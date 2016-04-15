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
    property double leafXV: leafXVInit
    property double leafYV: leafYVInit
    property double leafXF: 0
    property double leafYF: 0
    property double leafXFDrag: 0
    property double leafYFDrag: 0
    property double leafMass: 0.05
    property double leafSize: 0
    property bool tangible: false
    property bool robotkidnapped: false

    readonly property real leafXVInit: 30
    readonly property real leafYVInit: 0

    readonly property double mountainDragMultiplier: 10 //to adjust for obstacle
    readonly property double dragCoefficient: .0 //air friction
    readonly property double maxVelocity: 50
    property double lastMillis: -1
    property double lastPositionSendMillis: 0
    property double timeStep: 0.025

    property variant field: null
    property variant allzones: null
    property variant robot: null

    property int bonus: 0
    property variant currentZone: ''
    property variant zoneHistory : []

    property variant zoneScoreList : {"madrid":1,"paris":4,"bern":5, "budapest":6, "kiev":8, "rome":3, "athens":2, "istanbul":2}
    property variant zoneNameList : ["madrid","paris","bern", "budapest", "kiev", "rome", "athens", "istanbul"]

    signal collidedWithWall()
    signal won()

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
        if(currentZone.indexOf('obstacle')>=0 || currentZone.indexOf('clouds')>=0){
            console.log(currentZone)
            leafXFDrag *= mountainDragMultiplier;
            leafYFDrag *= mountainDragMultiplier;
        }
    }

    function updateLeaf() {
        var currentMillis = (new Date).getTime();
        if(lastMillis < 0)
            timeStep = 0.025;
        else
            timeStep = (currentMillis - lastMillis)/1000;
        lastMillis = currentMillis;

        if(mainGameField.mainGameFieldStateEngine.isRunning){

            //Update leaf position
            var yGridSpacing = field.yGridSpacing
            var xGridSpacing = field.xGridSpacing
            calculateForcesAtLeaf()
            var netForceX = leafXF + leafXFDrag
            var netForceY = leafYF + leafYFDrag

            leafXV += netForceX/leafMass*timeStep;
            leafYV += netForceY/leafMass*timeStep;
            leafX += leafXV*timeStep;
            leafY += leafYV*timeStep;

            if(robot.robotComm.connected){
                if(currentMillis - lastPositionSendMillis > 100){
                    var goalX = leafX/fieldWidth*1700/0.508;
                    var goalY = leafY/fieldHeight*660/0.508;
                    var goalXDiff = goalX - robot.robotComm.x;
                    var goalYDiff = goalY - robot.robotComm.y;

                    var xCorrectionCoeff = 0;
                    var yCorrectionCoeff = 0;

                    var minAllowedDist = 25;

                    if(Math.abs(goalXDiff) > minAllowedDist)
                        xCorrectionCoeff = (1 - minAllowedDist/Math.abs(goalXDiff))/4;
                    if(Math.abs(goalYDiff) > minAllowedDist)
                        yCorrectionCoeff = (1 - minAllowedDist/Math.abs(goalYDiff))/4;

                    var goalXSpeed = 0.5*leafXV*(1 - xCorrectionCoeff) + goalXDiff*xCorrectionCoeff;
                    var goalYSpeed = 0.5*leafYV*(1 - yCorrectionCoeff) + goalYDiff*yCorrectionCoeff;
                    if(goalXSpeed > 150)
                        goalXSpeed = 150;
                    else if(goalXSpeed < -150)
                        goalXSpeed = -150;
                    if(goalYSpeed > 150)
                        goalYSpeed = 150;
                    else if(goalYSpeed < -150)
                        goalYSpeed = -150;

                    robot.robotComm.setGoalVelocityCompact(goalXSpeed, goalYSpeed);

                    lastPositionSendMillis = currentMillis;
                }
            }

            if( currentZone!==''){
                if(zoneNameList.indexOf(currentZone)>=0 && zoneHistory.indexOf(currentZone)<0){
                    bonus = bonus  + zoneScoreList[currentZone]
                    zoneHistory.push(currentZone)
                }
            }

            // Arrived at the end of the map: WINS
            if(leafX >= windfield.fieldWidth)
                won();

            //Collided with left, up or down wall
            else if (leafX <= 0 || leafY >= windfield.fieldHeight || leafY <= 0)
                collidedWithWall();
        }
        else{

            //Update from the robot
            leafX = robot.coords.x*fieldWidth
            leafY = robot.coords.y*fieldHeight
            leafXV = leafXVInit;
            leafYV = leafYVInit;
            zoneHistory = [];
        }
    }
}
