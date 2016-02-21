import QtQuick 2.5
import QtQuick.Controls 1.4
import QtQuick.Dialogs 1.2
import QtQuick.Window 2.2
import QtQuick.Controls.Styles 1.4
import QtCanvas3D 1.0
import Cellulo 1.0

import "renderer.js" as GLRender


ApplicationWindow {
    visible: true
    width: 640
    height: 480
    title: qsTr("Wind Field Game")
    visibility:"FullScreen"

    //Cellulo
    CelluloBluetooth{
        id: robotComm
    }

    Canvas3D {
        id: windField
        anchors.fill: parent

        //Game interaction variables
        property bool paused: false
        property bool drawPressureGrid: true
        property bool drawForceGrid: true
        property bool drawLeafVelocityVector: true
        property bool drawLeafForceVectors: true
        property bool drawPrediction: false
        property int currentAction: 0

        //TODO: Create a structure for the leaf/robot
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


        //Pressure state TODO - convert to struct
        property variant pressureGrid: []
        property int robotMaxY: 1600.0
        property int robotMaxX: 2560.0
        property int numCols: 26*gridDensity
        property int numRows: 16*gridDensity
        property double xGridSpacing: (robotMaxX/numCols)
        property double yGridSpacing: (robotMaxY/numRows)

        //Pressure points
        property int maxPressurePointPairs: 10
        property variant pressurePoints: []
        property variant pressureDragInput: []

        property double pressureToForceMultiplier: 1
        property double pressureTransferRate: .5
        property double maxForce: 15.0
        property double dragCoefficient: .05
        property double maxVelocity: maxForce/dragCoefficient
        property double timeStep: .25
        property int gridDensity: 1 //Preferably an odd number to have nice vector spacing
        property int collisionSearchRadius: 1*gridDensity
        property int convergenceIterations: 50

        onInitializeGL: {
            GLRender.initializeGL(windField)
        }

        onPaintGL: {
            if (!paused)
                updateLeaf()
            GLRender.paintGL(windField)
        }

        Component.onCompleted: {
            windField.initializeWindField()
            robotComm.macAddr = "00:06:66:74:43:01"
        }

        //Simulation Logic
        function initializeWindField() {
            var rows = new Array(numRows)
            for (var i = 0; i < numRows; i++) {
                var column = new Array(numCols)
                for (var j = 0; j < numCols; j++) {
                    var cellArray = new Array(7)
                    cellArray[0] = xGridSpacing/2+j*xGridSpacing //Position X
                    cellArray[1] = yGridSpacing/2+i*yGridSpacing //Position Y
                    cellArray[2] = 0.0 //current wind force X component
                    cellArray[3] = 0.0 //current wind force Y component
                    cellArray[4] = 50.0 //Pressure (from 0 to 100)
                    cellArray[5] = 0.0 //incoming pressure
                    cellArray[6] = 1.0 //0: obstacle 1:valid cell
                    column[j] = cellArray
                }
                rows[i]=column
            }
            pressureGrid = rows

            pressurePoints = new Array(maxPressurePointPairs*2);
            addPressurePoint(0,0,true)
            addPressurePoint(15,0,true)
            addPressurePoint(0,25,true)
            addPressurePoint(15,25,true)
            addPressurePoint(7,12,false)
            addPressurePoint(8,12,false)
            addPressurePoint(7,13,false)
            addPressurePoint(8,13,false)

            pressureDragInput = new Array(touchArea.maximumTouchPoints)
            setObstacles()
            setPressurePoints()
            setInitialLeafInfo()

            updateField()
        }

        function setObstacles() {
            pressureGrid[13][24][6] = 0
            pressureGrid[13][23][6] = 0
            pressureGrid[14][23][6] = 0
            pressureGrid[14][24][6] = 0

            pressureGrid[5][7][6] = 0
            pressureGrid[5][8][6] = 0
            pressureGrid[6][7][6] = 0
            pressureGrid[6][8][6] = 0
            pressureGrid[6][6][6] = 0
        }

        function setPressurePoints() {
            for (var i = 0; i < maxPressurePointPairs*2; i++) {
                if (!pressurePoints[i])
                    continue
                var row = pressurePoints[i].x
                var col = pressurePoints[i].y
                if (i < maxPressurePointPairs)
                    pressureGrid[row][col][4] = 100.0
                else
                    pressureGrid[row][col][4] = 0.0
            }
        }

        function setInitialLeafInfo() {
            leafX = 200
            leafY = 300
            leafXV = 0
            leafYV = 0
            leafMass = 1
            leafSize = 50
            calculateForcesAtLeaf()
        }

        function removePressurePoint(r,c) {
            for (var i = 0; i < maxPressurePointPairs*2; i++) {
                if (!pressurePoints[i])
                    continue
                var row = pressurePoints[i].x
                var col = pressurePoints[i].y
                if (r == row && c == col) {
                    pressurePoints[i] = 0
                    updateField()
                }
            }
        }

        function addPressurePoint(r,c,highPressure) {
            //First make sure the point doesn't already exist, do nothing if it already does
            for (var p = 0; p < maxPressurePointPairs*2; p++) {
                if (pressurePoints[p]) {
                    var row = pressurePoints[p].x
                    var col = pressurePoints[p].y
                    if (row == r && col == c) {
                        return;
                    }
                }
            }
            //Actually add the pressure cell
            if (highPressure) {
                for (var p = 0; p < maxPressurePointPairs; p++) {
                    if (!pressurePoints[p]) {
                        pressurePoints[p] = Qt.point(r,c)
                        updateField()
                        return
                    }
                }
            } else {
                for (var p = maxPressurePointPairs; p < maxPressurePointPairs*2; p++) {
                    if (!pressurePoints[p]) {
                        pressurePoints[p] = Qt.point(r,c)
                        updateField()
                        return
                    }
                }
            }
        }

        /***STATE UPDATE METHODS***/
        function updateField() {
            //console.log("Robot Position X: ", robotComm.x, "Robot Position Y: ", robotComm.y)
            for (var i = 0; i < convergenceIterations; i++) {
                updatePressureGrid()
                setPressurePoints()
                calculateForceVectors()
            }
        }

        function updatePressureGrid() {
            for (var row = 0; row < numRows; row++) {
                for (var col = 0; col < numCols; col++) {
                    var tempLocalPressure = new Array(3)
                    tempLocalPressure[0] = new Array(3)
                    tempLocalPressure[1] = new Array(3)
                    tempLocalPressure[2] = new Array(3)
                    tempLocalPressure[0][0] = 0.0
                    tempLocalPressure[0][1] = 0.0
                    tempLocalPressure[0][2] = 0.0
                    tempLocalPressure[1][0] = 0.0
                    tempLocalPressure[1][1] = 0.0
                    tempLocalPressure[1][2] = 0.0
                    tempLocalPressure[2][0] = 0.0
                    tempLocalPressure[2][1] = 0.0
                    tempLocalPressure[2][2] = 0.0

                    var numLowPressureNeighbours = 0;
                    var curPressure = pressureGrid[row][col][4]
                    for (var rowOffset = -1; rowOffset <= 1; rowOffset++) {
                        if (row+rowOffset >= numRows || row+rowOffset < 0)
                            continue;
                        for (var colOffset = -1; colOffset <= 1; colOffset++) {
                            var rowIndex = row+rowOffset
                            var colIndex = col+colOffset
                            if ((!rowOffset && !colOffset) || colIndex >= numCols || colIndex < 0 || (!pressureGrid[rowIndex][colIndex][6]))
                                continue;
                            var neighbourPressure = pressureGrid[rowIndex][colIndex][4]
                            if (curPressure > neighbourPressure) {
                                var pressureDiff = (curPressure - neighbourPressure)
                                tempLocalPressure[rowOffset+1][colOffset+1] = pressureDiff
                                numLowPressureNeighbours++
                            } else {
                                tempLocalPressure[rowOffset+1][colOffset+1] = 0.0
                            }
                        }
                    }

                    numLowPressureNeighbours++ //including self
                    for (var i = -1; i <= 1; i++) {
                        for (var j = -1; j <= 1; j++) {
                            var localPressureDiff = pressureTransferRate*tempLocalPressure[i+1][j+1]/numLowPressureNeighbours
                            if (localPressureDiff > 0.0) {
                                pressureGrid[row+i][col+j][5] += localPressureDiff
                                pressureGrid[row][col][5] -= localPressureDiff
                            }
                        }
                    }
                }
            }

            for (var row = 0; row < numRows; row++) {
                for (var col = 0; col < numCols; col++) {
                    pressureGrid[row][col][4] += pressureGrid[row][col][5]
                    pressureGrid[row][col][5] = 0.0
                    if (!pressureGrid[row][col][6])
                        pressureGrid[row][col][4] = 0.0
                }
            }
        }

        function calculateForceVectors() {
            if (!drawLeafForceVectors)
                return;
            for (var row = 0; row < numRows; row++) {
                for (var col = 0; col < numCols; col++) {
                    var curPressure = pressureGrid[row][col][4]
                    var validNeighbours = 0
                    var nFX = 0
                    var nFY = 0
                    for (var rowOffset = -1; rowOffset <= 1; rowOffset++) {
                        if (row+rowOffset >= numRows || row+rowOffset < 0)
                            continue;
                        for (var colOffset = -1; colOffset <= 1; colOffset++) {
                            var rowIndex = row+rowOffset
                            var colIndex = col+colOffset
                            if (colIndex >= numCols || colIndex < 0 || (!pressureGrid[rowIndex][colIndex][6]))
                                continue;
                            var pressureGradient = (curPressure - pressureGrid[rowIndex][colIndex][4])*gridDensity

                            if (rowOffset != 0 && colOffset == 0) {
                                nFY += rowOffset*pressureGradient
                            } else if (colOffset != 0 && rowOffset == 0) {
                                nFX += colOffset*pressureGradient
                            } else {
                                nFY += rowOffset*Math.SQRT1_2*pressureGradient
                                nFX += colOffset*Math.SQRT1_2*pressureGradient
                            }
                            validNeighbours++
                        }
                    }
                    nFY /= validNeighbours
                    nFX /= validNeighbours

                    //TODO: maxForce is subject to change, maybe should not be capped
                    var forceMagScale = nFX*nFX+nFY*nFY/(maxForce*maxForce)
                    if (forceMagScale > 1)  {
                        nFX /= forceMagScale
                        nFY /= forceMagScale
                    }

                    pressureGrid[row][col][2] = nFX
                    pressureGrid[row][col][3] = nFY
                }
            }
        }

        function calculateForcesAtLeaf() {
            //Calculate force acting on the leaf at current pressure conditions
            var rowIndex = Math.floor(leafY/yGridSpacing)
            var colIndex = Math.floor(leafX/xGridSpacing)

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

            leafYF = (topPressure-bottomPressure)*pressureToForceMultiplier*gridDensity
            leafXF = (leftPressure-rightPressure)*pressureToForceMultiplier*gridDensity

            leafXFDrag = -leafXV * dragCoefficient
            leafYFDrag = -leafYV * dragCoefficient
        }

        function updateLeaf() {
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
                            if (searchRow < 0 || searchRow > numRows || searchCol < 0 || searchCol > numCols)
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
            //Calculate forces at leaf at the new position so we can draw them now
            calculateForcesAtLeaf()
        }

        /***Canvas touch interations***/
        MultiPointTouchArea {
            id: touchArea
            anchors.fill: parent
            maximumTouchPoints: windField.maxPressurePointPairs

            function changingPressureCells() {
                var length = windField.pressureDragInput.length
                for (var i = 0; i < length; i++) {
                    if (windField.pressureDragInput[i])
                        return true
                }
                return false
            }

            onReleased: {
                var maxPointPairs = windField.maxPressurePointPairs
                var length = touchPoints.length
                for (var t = 0; t < length; t++) {
                    var row = Math.floor(touchPoints[t].y/windField.yGridSpacing)
                    var col = Math.floor(touchPoints[t].x/windField.xGridSpacing)
                    switch(windField.currentAction) {
                    case 1:
                        if (windField.pressureGrid[row][col][6])
                            windField.addPressurePoint(row, col, true)
                        //Remove the cell input box
                        for (var i = 0; i < maxPointPairs; i++) {
                            if (windField.pressureDragInput[i]) {
                                if (windField.pressureDragInput[i].x == row && windField.pressureDragInput[i].y == col) {
                                     windField.pressureDragInput[i] = 0
                                     break;
                                }
                            }
                        }
                        break;
                    case 2:
                        if (windField.pressureGrid[row][col][6])
                            windField.addPressurePoint(row, col, false)
                        //Remove the cell input box
                        for (var i = maxPointPairs; i < maxPointPairs*2; i++) {
                            if (windField.pressureDragInput[i+maxPointPairs].x == row &&
                                    windField.pressureDragInput[i+maxPointPairs].y == col) {
                                windField.pressureDragInput[i+maxPointPairs] = 0
                                break;
                            }
                        }
                        break;
                    case 3:
                        windField.removePressurePoint(row, col)
                        break;
                    case 0:
                        var startRow = Math.floor(touchPoints[t].startY/windField.yGridSpacing)
                        var startCol = Math.floor(touchPoints[t].startX/windField.xGridSpacing)
                        for (var i = 0; i < maxPointPairs*2; i++) {
                            if (!windField.pressurePoints[i])
                                continue
                            var cellRow = windField.pressurePoints[i].x
                            var cellCol = windField.pressurePoints[i].y
                            if (startRow == cellRow && startCol == cellCol) {
                                windField.pressureDragInput[i] = 0
                                if (!windField.pressureGrid[row][col][6])
                                    return
                                windField.pressurePoints[i].x = row
                                windField.pressurePoints[i].y = col
                                windField.updateField()
                            }
                        }
                        break;
                    }
                    actionMenu.enabled = !changingPressureCells()
                }
            }

            onPressed:  {
                var maxPointPairs = windField.maxPressurePointPairs
                var length = touchPoints.length
                for (var t = 0; t < length; t++) {
                    var startRow = Math.floor(touchPoints[t].startY/windField.yGridSpacing)
                    var startCol = Math.floor(touchPoints[t].startX/windField.xGridSpacing)
                    switch (windField.currentAction) {
                    case 1:
                        for (var i = 0; i < maxPointPairs; i++) {
                            if (!windField.pressureDragInput[i]) {
                                windField.pressureDragInput[i] = Qt.point(startRow, startCol)
                                break;
                            }
                        }
                        break;
                    case 2:
                        for (var i = maxPointPairs; i < maxPointPairs*2; i++) {
                            if (!windField.pressureDragInput[i+maxPointPairs]) {
                                windField.pressureDragInput[i+maxPointPairs] = Qt.point(startRow, startCol)
                                break;
                            }
                        }
                        break;
                    case 3:
                        break;
                    case 0:
                        for (var i = 0; i < maxPointPairs*2; i++) {
                            if (!windField.pressurePoints[i])
                                continue
                            var cellRow = windField.pressurePoints[i].x
                            var cellCol = windField.pressurePoints[i].y
                            if (startRow == cellRow && startCol == cellCol) {
                                 windField.pressureDragInput[i] = Qt.point(startRow,startCol)
                            }
                        }
                        break;
                    }
                }
                actionMenu.enabled = !changingPressureCells()
            }

            onUpdated: {
               var maxPointPairs = windField.maxPressurePointPairs
               var length = touchPoints.length
               for (var t = 0; t < length; t++) {
                   var row = Math.floor(touchPoints[t].y/windField.yGridSpacing)
                   var col = Math.floor(touchPoints[t].x/windField.xGridSpacing)
                   var prevRow = Math.floor(touchPoints[t].previousY/windField.yGridSpacing)
                   var prevCol = Math.floor(touchPoints[t].previousX/windField.xGridSpacing)
                   switch (windField.currentAction) {
                   case 1:
                       for (var i = 0; i < maxPointPairs; i++) {
                           if (windField.pressureDragInput[i]) {
                               if (windField.pressureDragInput[i].x == prevRow && windField.pressureDragInput[i].y == prevCol) {
                                    windField.pressureDragInput[i] = Qt.point(row, col)
                                    break;
                               }
                           }
                       }
                       break;
                   case 2:
                       for (var i = maxPointPairs; i < maxPointPairs*2; i++) {
                           if (windField.pressureDragInput[i+maxPointPairs].x == prevRow &&
                                   windField.pressureDragInput[i+maxPointPairs].y == prevCol) {
                               windField.pressureDragInput[i+maxPointPairs] = Qt.point(row, col)
                               break;
                           }
                       }
                       break;
                   case 3:
                       break;
                   case 0:
                       var startRow = Math.floor(touchPoints[t].startY/windField.yGridSpacing)
                       var startCol = Math.floor(touchPoints[t].startX/windField.xGridSpacing)
                       for (var i = 0; i < maxPointPairs*2; i++) {
                           if (!windField.pressurePoints[i])
                               continue
                           var cellRow = windField.pressurePoints[i].x
                           var cellCol = windField.pressurePoints[i].y
                           if (startRow == cellRow && startCol == cellCol) {
                                windField.pressureDragInput[i] = Qt.point(row,col)
                           }
                       }
                       break;
                    }
                }
           }
        }

        //UI Interactions, see UI below
        function togglePaused() {
            paused = !paused
            if (paused)
                pause.text = 'Resume'
            else
                pause.text = 'Pause'
            pathUpdate.enabled = paused
        }

        function togglePathDraw() {
            drawPrediction = true
        }

        function toggleDisplaySetting(setting) {
            switch(setting){
            case 1:
                drawPressureGrid = pressureGridCheck.checked
                break;
            case 2:
                drawForceGrid = forceGridCheck.checked
                break;
            case 3:
                drawLeafVelocityVector = leafVelocityCheck.checked
                break;
            case 4:
                drawLeafForceVectors = leafForceCheck.checked
                break;
            }
        }
    }

    //UI
    Column {
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        Slider {
            id: sceneRotation
            orientation: Qt.Vertical
            height: 500
            minimumValue: 0
            maximumValue: 100
            value: 100
        }
    }

    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: parent.top
        spacing: 5
        Column {
            Button {
                id: pathUpdate
                text: qsTr("Calculate path")
                anchors.horizontalCenter: parent.horizontalCenter
                onClicked: windField.togglePathDraw()
                enabled: windField.paused
                style: ButtonStyle {
                    id: buttonStyle
                    background: Rectangle {
                        implicitWidth: 100
                        implicitHeight: 100
                        border.width: control.activeFocus ? 2 : 1
                        border.color: "#888"
                        radius: 4
                        gradient: Gradient {
                            GradientStop { position: 0 ; color: control.pressed ? "#ccc" : "#eee" }
                            GradientStop { position: 1 ; color: control.pressed ? "#aaa" : "#ccc" }
                        }
                    }
                }
            }
        }

        Column {
            id:menu
            spacing:0
            Button {
                id: pause
                text: qsTr("Pause")
                anchors.horizontalCenter: parent.horizontalCenter
                onClicked: windField.togglePaused()
                style:     ButtonStyle {
                    id: buttonStyle
                    background: Rectangle {
                        implicitWidth: 100
                        implicitHeight: 25
                        border.width: control.activeFocus ? 2 : 1
                        border.color: "#888"
                        radius: 4
                        gradient: Gradient {
                            GradientStop { position: 0 ; color: control.pressed ? "#ccc" : "#eee" }
                            GradientStop { position: 1 ; color: control.pressed ? "#aaa" : "#ccc" }
                        }
                    }
                }
            }
            Button {
                id: reset
                text: qsTr("Reset")
                anchors.horizontalCenter: parent.horizontalCenter
                style: pause.style
                onClicked: windField.initializeWindField()
            }
        }
        Column {
            CheckBox {
                id: pressureGridCheck
                checked: windField.drawPressureGrid
                text: "Pressure Gradient"
                onClicked: windField.toggleDisplaySetting(1)
            }
            CheckBox {
                id: forceGridCheck
                checked: windField.drawForceGrid
                text: "Force Vectors"
                onClicked: windField.toggleDisplaySetting(2)
            }
            CheckBox {
                id: leafVelocityCheck
                checked: windField.drawLeafVelocityVector
                text: "Leaf Velocity"
                onClicked: windField.toggleDisplaySetting(3)
            }
            CheckBox {
                id: leafForceCheck
                checked: windField.drawLeafForceVectors
                text: "Forces on Leaf"
                onClicked: windField.toggleDisplaySetting(4)
            }
        }
        Column {
            Text {
                text: " Action Menu: "
            }
            ComboBox {
                id: actionMenu
                currentIndex: 0
                style: ComboBoxStyle {
                    background: Rectangle {
                        implicitWidth: 300
                        implicitHeight: 50
                        border.width: control.activeFocus ? 2 : 1
                        border.color: "#888"
                        radius: 4
                        gradient: Gradient {
                            GradientStop { position: 0 ; color: control.pressed ? "#ccc" : "#eee" }
                            GradientStop { position: 1 ; color: control.pressed ? "#aaa" : "#ccc" }
                        }
                    }
                }
                model: ListModel {
                    id: cbItems
                    ListElement { text: "Move Pressure"; color: "White" }
                    ListElement { text: "Add High Pressure"; color: "White" }
                    ListElement { text: "Add Low Pressure"; color: "White" }
                    ListElement { text: "Remove Pressure"; color: "White" }
                }
                onCurrentIndexChanged: {
                    windField.currentAction = currentIndex;
                }
            }
        }
    }
}
