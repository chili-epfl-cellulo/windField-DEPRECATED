import QtQuick 2.5
import QtQuick.Controls 1.4
import QtQuick.Dialogs 1.2
import QtQuick.Window 2.2
import QtQuick.Controls.Styles 1.4
import QtCanvas3D 1.0
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
    property double collisionForceX: 0
    property double collisionForceY: 0

    property int robotMaxX: 1600
    property int robotMaxY: 2560

    readonly property double dragCoefficient: .05
    readonly property double maxVelocity: 50
    readonly property double timeStep: .25
    readonly property int collisionSearchRadius: 1*field.gridDensity

    property variant field: null

    /***CELLULO SYNCHRONISATION METHODS***/
    CelluloBluetooth{
        id: robotComm
    }

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
                               pressureGrid[rowIndex][colIndex][4])/
                              (pressureGrid[Math.max(0,rowIndex-1)][Math.max(0,colIndex-1)][6] +
                               pressureGrid[Math.max(0,rowIndex-1)][colIndex][6] +
                               pressureGrid[rowIndex][Math.max(0,colIndex-1)][6] +
                               pressureGrid[rowIndex][colIndex][6]);
        var topRightPressure = (pressureGrid[Math.max(0,rowIndex-1)][colIndex][4] +
                                pressureGrid[Math.max(0,rowIndex-1)][Math.min(numCols-1, colIndex+1)][4] +
                                pressureGrid[rowIndex][colIndex][4] +
                                pressureGrid[rowIndex][Math.min(numCols-1, colIndex+1)][4])/
                                (pressureGrid[Math.max(0,rowIndex-1)][colIndex][6] +
                                pressureGrid[Math.max(0,rowIndex-1)][Math.min(numCols-1, colIndex+1)][6] +
                                pressureGrid[rowIndex][colIndex][6] +
                                pressureGrid[rowIndex][Math.min(numCols-1, colIndex+1)][6])
        var bottomLeftPressure = (pressureGrid[rowIndex][Math.max(0,colIndex-1)][4] +
                                  pressureGrid[rowIndex][colIndex] [4]+
                                  pressureGrid[Math.min(numRows-1,rowIndex+1)][Math.max(0,colIndex-1)][4] +
                                  pressureGrid[Math.min(numRows-1,rowIndex+1)][colIndex][4])/
                                 (pressureGrid[rowIndex][Math.max(0,colIndex-1)][6] +
                                  pressureGrid[rowIndex][colIndex][6]+
                                  pressureGrid[Math.min(numRows-1,rowIndex+1)][Math.max(0,colIndex-1)][6] +
                                  pressureGrid[Math.min(numRows-1,rowIndex+1)][colIndex][6])
        var bottomRightPressure = (pressureGrid[rowIndex][colIndex][4] +
                                   pressureGrid[rowIndex][Math.min(numCols-1, colIndex+1)][4] +
                                   pressureGrid[Math.min(numRows-1,rowIndex+1)][colIndex][4] +
                                   pressureGrid[Math.min(numRows-1,rowIndex+1)][Math.min(numCols-1, colIndex+1)][4])/
                                  (pressureGrid[rowIndex][colIndex][6] +
                                   pressureGrid[rowIndex][Math.min(numCols-1, colIndex+1)][6] +
                                   pressureGrid[Math.min(numRows-1,rowIndex+1)][colIndex][6] +
                                   pressureGrid[Math.min(numRows-1,rowIndex+1)][Math.min(numCols-1, colIndex+1)][6])

        //Now interpolate between the points to find the force (which we will just call the
        var xRatio = (leafX-colIndex*xGridSpacing)/xGridSpacing
        var topPressure = topLeftPressure+(topRightPressure-topLeftPressure)*xRatio
        var bottomPressure = bottomLeftPressure+(bottomRightPressure-bottomLeftPressure)*xRatio

        var yRatio = (leafY-rowIndex*yGridSpacing)/yGridSpacing
        var leftPressure = topLeftPressure+(bottomLeftPressure-topLeftPressure)*yRatio
        var rightPressure = topRightPressure+(bottomRightPressure-topRightPressure)*yRatio

        leafYF = (topPressure-bottomPressure)*field.pressureToForceMultiplier*field.gridDensity
        leafXF = (leftPressure-rightPressure)*field.pressureToForceMultiplier*field.gridDensity

        leafXFDrag = -leafXV * dragCoefficient
        leafYFDrag = -leafYV * dragCoefficient
    }

    function updateLeaf() {
        var pressureGrid = field.pressureGrid
        var yGridSpacing = field.yGridSpacing
        var xGridSpacing = field.xGridSpacing
        calculateForcesAtLeaf()
        var netForceX = leafXF + leafXFDrag
        var netForceY = leafYF + leafYFDrag
        //Ignore pressure cell forces when simulating the collision impulse
        if (collisionForceX || collisionForceY) {
            netForceX = collisionForceX
            netForceY = collisionForceY
        }
        //update position from one time step given current velocity and current force
        var deltaX = leafXV*timeStep+.5*netForceX/leafMass*timeStep*timeStep
        var deltaY = leafYV*timeStep+.5*netForceY/leafMass*timeStep*timeStep
        leafXV += netForceX/leafMass*timeStep
        leafYV += netForceY/leafMass*timeStep
        leafX += deltaX
        leafY += deltaY
        if (leafX > robotMaxX-leafSize/2 || leafX < 0) {
            leafX = Math.max(Math.min(leafX, robotMaxX-leafSize/2), 0.0)
            var reflectDirection;
            if (leafX  > robotMaxX-leafSize/2)
                reflectDirection = -1
            else
                reflectDirection = 1
            leafXV = leafXV - 2*leafXV*reflectDirection*reflectDirection
        } else if (leafY > robotMaxY-leafSize/2 || leafY < 0) {
            leafY = Math.max(Math.min(leafY, robotMaxY-leafSize/2), 0.0)
            var reflectDirection;
            if (leafY  > robotMaxY-leafSize/2)
                reflectDirection = -1
            else
                reflectDirection = 1
            var vdotn = leafYV*reflectDirection
            leafYV = leafYV - 2*leafYV*reflectDirection*reflectDirection
        } else {
            var leafRow = Math.floor(leafY/yGridSpacing)
            var leafCol = Math.floor(leafX/xGridSpacing)
            //Handle obstacle collision
            var startX = leafX - deltaX
            var startY = leafY - deltaY
            var deltaMag = Math.sqrt(deltaX*deltaX+deltaY*deltaY)
            //Search along deltaX and deltaY to determine whether or not a collision will occur
            var stepSize = Math.min(xGridSpacing, yGridSpacing)/5
            var stepX = deltaX/deltaMag*stepSize
            var stepY = deltaY/deltaMag*stepSize
            var previousCellRow = Math.floor(startY/yGridSpacing)
            var previousCellCol = Math.floor(startX/xGridSpacing)
            var step = 0
            var collisionFound = false
            for (step = 0; step < Math.ceil(deltaMag/stepSize); step++) {
                var currentRow = Math.floor((startY+stepY)/yGridSpacing)
                var currentCol = Math.floor((startX+stepX)/xGridSpacing)
                if (!pressureGrid[currentRow][currentCol][6]) {
                    collisionFound = true
                    break
                }
                previousCellRow = currentRow
                previousCellCol = currentCol
            }
            //PreviousCellRow/Col now locates the cell right before collision with obstacle, call it cell P
            //Next we search for all obstacles cells within a radius of this cell and average their direction vectors to P
            //We do this by searching in a predefined grid size around P and for each cell for which the magnitude of the vector
            //between the cell and P is < the radius, we use the corresponding unit vector in our averaging
            //Note: we can actually just search a grid around P, it's technically more accurate to do a radius search but
            //but assuming we actually use the squared radius to search but that means two more subtractions, at assuming
            //we use the squared radius, another addition and two more multiplications, per grid cell, a.k.a not worth it
            if (collisionFound) {
                var netX = 0
                var netY = 0
                var radius = collisionSearchRadius;
                var totalVecsAdded = 0
                for (var rowOffset = -radius; rowOffset <= radius; rowOffset++) {
                    for (var colOffset = -radius; colOffset <= radius; colOffset++) {
                        var searchRow = previousCellRow + rowOffset
                        var searchCol = previousCellCol + colOffset
                        //Out of bounds, try the next cell
                        if (searchRow < 0 || searchRow > field.numRows || searchCol < 0 || searchCol > field.numCols)
                            continue;
                        if (!pressureGrid[searchRow][searchCol][6]) {
                            var yDiff = previousCellRow - searchRow
                            var xDiff = previousCellCol - searchCol
                            var diffMag = Math.sqrt(xDiff*xDiff+yDiff*yDiff)
                            netX += xDiff/diffMag
                            netY += yDiff/diffMag
                            totalVecsAdded++
                        }
                    }
                }
                netX /= totalVecsAdded
                netY /= totalVecsAdded
                //<netX,netY> is a unit vector

                //Once we have this approximate perpendicular direction of the force, we can reflect the incoming object based off of it
                leafX = startX + step*stepX
                leafY = startY + step*stepY
                if (collisionForceX == 0 && collisionForceY == 0) {
                    var vdotn = leafXV*netX+leafYV*netY
                    leafXV = leafXV - 2*vdotn*netX
                    leafYV = leafYV - 2*vdotn*netY
                }

                var speed2 = leafXV*leafXV+leafYV*leafYV
                //TODO: scaling factor here is subject to change based on the grid setup (density, speed of the leaf, etc)
                //We also need to make the velocity vector converge the the original desired velocity, which gets hairy
                //Maybe something better to do here would be to approximate the obstacles continuously but that becomes a huge hassle
                collisionForceX += netX*speed2/10.0
                collisionForceY += netY*speed2/10.0
            } else {
                collisionForceX = 0.0
                collisionForceY = 0.0
            }
        }
        //TESTING
        //leafX = (robotComm.y/575)*robotMaxX
        //leafY = robotMaxY-(robotComm.x/400)*robotMaxY

        //Recalculate leaf forces at new point so we can draw the new forces correctly
        calculateForcesAtLeaf()
    }
}
