import QtQuick 2.5
import QtQuick.Controls 1.4
import QtQuick.Dialogs 1.2
import QtQuick.Window 2.2
import QtQuick.Controls.Styles 1.4
import QtCanvas3D 1.0


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

    readonly property double mountainDragMultiplier: 10 //to adjust for obstacle
    readonly property double dragCoefficient: .05 //air friction
    readonly property double maxVelocity: 50
    readonly property double timeStep: .25

    property variant field: null

    property variant robot: null

    /***CELLULO SYNCHRONISATION METHODS***/
//    CelluloBluetooth{
//        id: robotComm
//    }

    function updateCellulo() {
        //TODO: fill this in with code that makes the robot synchronise with the leaf representation
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

    function updateLeaf() {
        if (collided) {
            return;
        }

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
        if (leafX > windField.fieldWidth-leafSize/2 || leafX < leafSize/2) {
            leafX = Math.max(Math.min(leafX, windField.fieldWidth-leafSize/2), 0.0)
            collided = true
        } else if (leafY > windField.fieldHeight-leafSize/2 || leafY < leafSize/2) {
            leafY = Math.max(Math.min(leafY, windField.fieldHeight-leafSize/2), 0.0)
            collided = true
        }
        if (collided) {
            leafXV = 0
            leafYV = 0
            leafXF = 0
            leafYF = 0
            leafXFDrag = 0
            leafYFDrag = 0
        }

        //TESTING
        //leafX = (robotComm.y/575)*robotMaxX
        //leafY = robotMaxY-(robotComm.x/400)*robotMaxY

        robot.setGoalVelocity(leafXV*2 , leafYV*2 , 0.0);
    }


}
