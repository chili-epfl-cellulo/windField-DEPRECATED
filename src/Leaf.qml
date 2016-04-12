import QtQuick 2.5
import QtQuick.Window 2.1
import QtQuick.Layouts 1.1
import QtQuick.Controls 1.2
import QtQuick.Controls.Private 1.0
import QtQuick.Controls.Styles 1.3
import QtBluetooth 5.2
import Cellulo 1.0
Item {
    //Leaf Properties
    property double leafX: 0
    property double leafY: 0
    property double leafXV: 0
    property double leafYV: 0
    property double leafXF: 0
    property double leafYF: 0
    property double leafXFDrag: 0
    property double leafYFDrag: 0
    property double leafMass: 1
    property double leafSize: 0
    property bool collided: false
    property bool tangible: false

    readonly property double mountainDragMultiplier: 10 //to adjust for obstacle
    readonly property double dragCoefficient: .0 //air friction
    readonly property double maxVelocity: 50
    readonly property double timeStep: .25

    property variant field: null
    property variant allzones: null
    property variant robot: null
    //property variant controls: parent.controls

    property variant zoneHistory : []
    property variant zoneNameList : {"madrid":1,"paris":4,"bern":5, "budapest":6, "kiev":8, "rome":3, "athens":2, "finish":2}



    /***CELLULO SYNCHRONISATION METHODS***/
    function resetRobotVelocity(){
        //robot.setGlobalSpeeds(0.0 , 0.0 , 0.0);
        if(robot.robotComm.connected)
            robot.robotComm.reset();
    }

    function updateCellulo() {
        //TODO: fill this in with code that makes the robot synchronise with the leaf representation

        if(robot.robotComm.connected){
            leafX = robot.coords.x* fieldWidth
            leafY = robot.coords.y * fieldHeight
            //console.log(robot.coords.x, robot.coords.y)
            //console.log(leafX, leafY)
        }

    }

    /***LEAF STATE UPDATE METHODS***/
    function calculateForcesAtLeaf() {
        //Calculate force acting on the leaf at current pressure conditions
        var yGridSpacing = field.yGridSpacing
        var xGridSpacing = field.xGridSpacing
        var numCols = field.numCols
        var numRows = field.numRows
        var rowIndex = Math.floor(leafY/yGridSpacing)
        var colIndex = Math.floor(leafX/xGridSpacing)

        var pressureGrid = field.pressureGrid
        //Pressure is defined as center of the cell, calculate pressure at each corner, be ware of edge conditions
        var topLeftPressure = (pressureGrid[Math.max(0,rowIndex-1)][Math.max(0,colIndex-1)][4] +
                               pressureGrid[Math.max(0,rowIndex-1)][colIndex][4] +
                               pressureGrid[rowIndex][Math.max(0,colIndex-1)][4] +
                               pressureGrid[rowIndex][colIndex][4])/4.0;

        var topRightPressure = (pressureGrid[Math.max(0,rowIndex-1)][colIndex][4] +
                                pressureGrid[Math.max(0,rowIndex-1)][Math.min(numCols-1, colIndex+1)][4] +
                                pressureGrid[rowIndex][colIndex][4] +
                                pressureGrid[rowIndex][Math.min(numCols-1, colIndex+1)][4])/4.0

        var bottomLeftPressure = (pressureGrid[rowIndex][Math.max(0,colIndex-1)][4] +
                                  pressureGrid[rowIndex][colIndex] [4]+
                                  pressureGrid[Math.min(numRows-1,rowIndex+1)][Math.max(0,colIndex-1)][4] +
                                  pressureGrid[Math.min(numRows-1,rowIndex+1)][colIndex][4])/4.0

        var bottomRightPressure = (pressureGrid[rowIndex][colIndex][4] +
                                   pressureGrid[rowIndex][Math.min(numCols-1, colIndex+1)][4] +
                                   pressureGrid[Math.min(numRows-1,rowIndex+1)][colIndex][4] +
                                   pressureGrid[Math.min(numRows-1,rowIndex+1)][Math.min(numCols-1, colIndex+1)][4])/4

        //console.log( 'pressures' ,topLeftPressure, topRightPressure ,bottomLeftPressure,bottomRightPressure)

        //Now interpolate between the points to find the force (which we will just call the
        var xRatio = (leafX-colIndex*xGridSpacing)/xGridSpacing
        var topPressure = topLeftPressure+(topRightPressure-topLeftPressure)*xRatio
        var bottomPressure = bottomLeftPressure+(bottomRightPressure-bottomLeftPressure)*xRatio

        var yRatio = (leafY-rowIndex*yGridSpacing)/yGridSpacing
        var leftPressure = topLeftPressure+(bottomLeftPressure-topLeftPressure)*yRatio
        var rightPressure = topRightPressure+(bottomRightPressure-topRightPressure)*yRatio

        leafYF = (topPressure-bottomPressure)*field.pressureToForceMultiplier
        leafXF = (leftPressure-rightPressure)*field.pressureToForceMultiplier

        leafXFDrag = -leafXV * dragCoefficient
        leafYFDrag = -leafYV * dragCoefficient
        if (!pressureGrid[rowIndex][colIndex][6]) {
            leafXFDrag *= mountainDragMultiplier;
            leafYFDrag *= mountainDragMultiplier;
        }
    }

    // - check if the leaf is in a zone
    function inZone(zone){
        if(robot.checkZone()!=="" && robot.robotComm.connected){
            robot.blink("red")
        }
        //TODO
        return false;

    }

    function updateLeaf() {
        //TODO CHEKC OBSTACLE REDUCE SPEED
        //TODO CHECK ZONES AND BONUS POINTS
        if (collided) {
            return;
        }
        if(tangible){// motors of cellulo are off the leaf updates according to cellulo
            updateCellulo()
        }else{
            var pressureGrid = field.pressureGrid
            var yGridSpacing = field.yGridSpacing
            var xGridSpacing = field.xGridSpacing
            calculateForcesAtLeaf()
            var netForceX = leafXF + leafXFDrag
            var netForceY = leafYF + leafYFDrag

            //update position from one time step given current velocity and current force
            var deltaX = leafXV*timeStep+.5*netForceX/leafMass*timeStep*timeStep
            var deltaY = leafYV*timeStep+.5*netForceY/leafMass*timeStep*timeStep

            leafXV += netForceX/leafMass*timeStep
            leafYV += netForceY/leafMass*timeStep
            leafX += deltaX
            leafY += deltaY



            //if(robot.connected && !collided)
            console.log(leafXV , leafYV )
            console.log(leafXV/fieldHeight *660*0.508, leafYV /fieldWidth*1800*0.508, 0.0)
            if(robot.robotComm.connected)
                robot.setGlobalSpeeds(leafXV/field.numRows *660*0.508, leafYV /field.numCols*1700*0.508, 0.0);


            if(robot.checkZone()!==''&& robot.robotComm.connected){
                //controls.bonus = controls.bonus + 1
                var thezone =robot.checkZone()
                console.log(thezone)
                if(zoneNameList.valueOf(thezone)>0 && zoneHistory.indexOf(thezone)<0){
                    console.log("__________________")
                    console.log(zoneNameList[thezone])
                    console.log(parent.bonus)
                    controls.bonus = controls.bonus  + zoneNameList[thezone]
                    zoneHistory.push(thezone)
                }
            }

            //if (leafX > windField.fieldWidth-leafSize/2 || leafX < leafSize/2) {
            if (leafX > windField.fieldWidth) {
                leafX = Math.max(Math.min(leafX, windField.fieldWidth-leafSize/2), 0.0)
                collided = true;
                windfield.state = (windfield.nblifes <=0) ?  "wins": "winr"
                if(robot.robotComm.connected){
                    robot.alert(Qt.rgba(0.7,0,0,1), 5);
                    robot.setGlobalSpeeds(0,0,4);
                }
            }
            else if (leafX < 0) {
                leafX = Math.max(Math.min(leafX, windField.fieldWidth-leafSize/2), 0.0)
                collided = true;
                windfield.state = (windfield.nblifes <=0) ?  "over": "lost"
                if(robot.robotComm.connected){
                    robot.alert(Qt.rgba(0.7,0,0,1), 5);
                    robot.setGlobalSpeeds(0,0,4);
                }
                console.log("=========LEAF COLLIDED R1==========")
                //} else if (leafY > windField.fieldHeight-leafSize/2 || leafY < leafSize/2) {
            } else if (leafY > windField.fieldHeight || leafY < 0) {
                leafY = Math.max(Math.min(leafY, windField.fieldHeight-leafSize/2), 0.0)
                collided = true
                windfield.state = (windfield.nblifes <=0) ?  "over": "lost"
                if(robot.robotComm.connected){
                    robot.alert(Qt.rgba(0.7,0,0,1),5);
                    robot.setGlobalSpeeds(0,0,4);
                }
                console.log("=========LEAF COLLIDED R2==========")
            }
            else if (inZone(allzones.zones[allzones.zones.length-1])) {
                leafXV = 0
                leafYV = 0
                windfield.state = (windfield.nblifes <=0) ?  "wins": "winr"

            }
            if (collided) {
                leafXV = 0
                leafYV = 0
                leafXF = 0
                leafYF = 0
                leafXFDrag = 0
                leafYFDrag = 0
                robot.setGlobalSpeeds(0,0,0);
            }
        }
    }
}
