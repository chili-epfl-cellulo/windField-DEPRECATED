import QtQuick 2.5
import QtQuick.Controls 1.4
import QtQuick.Dialogs 1.2
import QtQuick.Window 2.2
import QtQuick.Controls.Styles 1.4

Item {
    property variant pressureGrid: []
    //Contains an array of pressurePoint structs including
    property variant pressurePoints: []
    property int numHighPressurePoints: 0
    property int numLowPressurePoints: 0

    readonly property int maxPressurePointPairs: 10

    readonly property int gridDensity: 3
    readonly property int numCols: 16*gridDensity
    readonly property int numRows: 25*gridDensity

    readonly property double xGridSpacing: (windField.fieldWidth/numCols)
    readonly property double yGridSpacing: (windField.fieldHeight/numRows)

    //Controls how much force there is per unit of pressure difference
    readonly property double pressureToForceMultiplier: .5
    readonly property double maxForce: 15.0

    //Controls how fast pressure disperses in a single time step
    readonly property double pressureTransferRate: 1

    //Controls how many loops we run the pressure update for before letting the balloon simulation start
    readonly property int convergenceIterations: 30

    //State variables for pressure inputs
    readonly property int inactive: 0
    readonly property int active: 1
    readonly property int selected: 2

    function pressurePointObject() {
        this.gridIndex = Qt.point(0,0);
        this.position = Qt.point(0,0)
        //0-inactive, 1-active, 2-active and selected
        this.state = inactive
        this.strength = 0.0
    }

    /***PRESSURE FIELD INITIALIZATION***/
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
                cellArray[6] = 1.0 //0:mountain cell, 1:normal cell
                column[j] = cellArray
            }
            rows[i]=column
        }
        pressureGrid = rows
        pressurePoints = new Array(maxPressurePointPairs*2);
        for (var i = 0; i < maxPressurePointPairs*2; i++) {
            pressurePoints[i] = new pressurePointObject()
        }

        updateField()
    }

    function resetPressureAtPressurePoints() {
        for (var i = 0; i < maxPressurePointPairs*2; i++) {
            if (!pressurePoints[i].state)
                continue
            var row = pressurePoints[i].gridIndex.x
            var col = pressurePoints[i].gridIndex.y
            pressureGrid[row][col][4] = pressurePoints[i].strength
        }
    }

    /***PRESSURE GRID STATE UPDATE METHODS***/
    function updateField() {
        //console.log("Robot Position X: ", robotComm.x, "Robot Position Y: ", robotComm.y)
        for (var i = 0; i < convergenceIterations; i++) {
            resetPressureAtPressurePoints()
            updatePressureGrid()
            resetPressureAtPressurePoints()
            calculateForceVectors()
            windField.setPressureFieldTextureDirty()
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
                        if ((!rowOffset && !colOffset) || colIndex >= numCols || colIndex < 0)
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
            }
        }
    }

    function calculateForceVectors() {
        if (!windField.drawForceGrid)
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
                        if (colIndex >= numCols || colIndex < 0)
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

    /***HELPER METHODS FOR ADDING, MOVING AND REMOVING PRESSURE POINTS***/
    function addPressurePoint(r,c,highPressure) {
        //First make sure the point doesn't already exist, do nothing if it already does
        for (var p = 0; p < maxPressurePointPairs*2; p++) {
            if (pressurePoints[p].state) {
                var row = pressurePoints[p].gridIndex.x
                var col = pressurePoints[p].gridIndex.y
                if (row == r && col == c) {
                    return;
                }
            }
        }
        //Actually add the pressure cell
        if (highPressure) {
            for (var p = 0; p < maxPressurePointPairs; p++) {
                if (!pressurePoints[p].state) {
                    pressurePoints[p].gridIndex = Qt.point(r,c)
                    pressurePoints[p].position = Qt.point(c*xGridSpacing+xGridSpacing/2, r*yGridSpacing+yGridSpacing/2);
                    pressurePoints[p].state = active
                    pressurePoints[p].strength = 100.0
                    numHighPressurePoints++
                    return
                }
            }
        } else {
            for (var p = maxPressurePointPairs; p < maxPressurePointPairs*2; p++) {
                if (!pressurePoints[p].state) {
                    pressurePoints[p].gridIndex = Qt.point(r,c)
                    pressurePoints[p].position = Qt.point(c*xGridSpacing+xGridSpacing/2, r*yGridSpacing+yGridSpacing/2);
                    pressurePoints[p].state = active
                    pressurePoints[p].strength = 0.0
                    numLowPressurePoints++
                    return
                }
            }
        }
    }

    function removePressurePoint(r,c) {
        for (var i = 0; i < maxPressurePointPairs*2; i++) {
            if (!pressurePoints[i].state)
                continue
            var row = pressurePoints[i].gridIndex.x
            var col = pressurePoints[i].gridIndex.y
            if (r == row && c == col) {
                pressurePoints[i].state = inactive
                pressurePoints[i].position = null
                pressurePoints[i].gridIndex = null
                if (pressurePoints[i].strength > 50.0)
                    numHighPressurePoints--
                else
                    numLowPressurePoints--
                pressurePoints[i].strength = 0.0
                updateField()
            }
        }
    }

    /***Pressure field touch interations***/
    MultiPointTouchArea {
        id: touchArea
        anchors.fill: parent
        maximumTouchPoints: maxPressurePointPairs
        enabled: (controls.rotation == controls.maxRotation)

        function changingPressureCells() {
            var length = pressurePoints.length
            for (var i = 0; i < length; i++) {
                if (pressurePoints[i].state == selected)
                    return true
            }
            return false
        }

        onReleased: {
            var maxPointPairs = maxPressurePointPairs
            var length = touchPoints.length
            for (var t = 0; t < length; t++) {
                var row = Math.floor(touchPoints[t].y/yGridSpacing)
                var col = Math.floor(touchPoints[t].x/xGridSpacing)
                switch(windField.currentAction) {
                //Note: For cases 1 and 2 gridIndex stores the starting touch point of the gesture so that we can identify which pressurepoint to remove
                case 1:
                    //Remove the unplaced pressure point
                    for (var i = 0; i < maxPointPairs; i++) {
                        console.log(pressurePoints[i].position.x, "  ", pressurePoints[i].position.y)
                        if (pressurePoints[i].state == selected &&
                                pressurePoints[i].gridIndex.x == touchPoints[t].startX &&
                                pressurePoints[i].gridIndex.y == touchPoints[t].startY) {
                            pressurePoints[i].state = inactive
                            pressurePoints[i].position = null
                            pressurePoints[i].gridIndex = null
                            pressurePoints[i].strength = 0.0
                            break
                        }
                    }
                    if (numHighPressurePoints < maxPressurePointPairs) {
                        addPressurePoint(row, col, true)
                        updateField()
                    }
                    break;
                case 2:
                    //Remove the unplaced pressure point
                    for (var i = maxPointPairs; i < maxPointPairs*2; i++) {
                        if (pressurePoints[i].state == selected &&
                                pressurePoints[i].gridIndex.x == touchPoints[t].startX &&
                                pressurePoints[i].gridIndex.y == touchPoints[t].startY) {
                            pressurePoints[i].state = inactive
                            pressurePoints[i].position = null
                            pressurePoints[i].gridIndex = null
                            pressurePoints[i].strength = 0.0
                            break
                        }
                    }
                    if (numLowPressurePoints < maxPressurePointPairs) {
                        addPressurePoint(row, col, false)
                        updateField()
                    }
                    break;
                case 3:
                    removePressurePoint(row, col)
                    updateField()
                    break;
                case 0:
                    var startRow = Math.floor(touchPoints[t].startY/yGridSpacing)
                    var startCol = Math.floor(touchPoints[t].startX/xGridSpacing)
                    for (var i = 0; i < maxPointPairs*2; i++) {
                        if (!pressurePoints[i].state)
                            continue
                        var cellRow = pressurePoints[i].gridIndex.x
                        var cellCol = pressurePoints[i].gridIndex.y
                        if (startRow == cellRow && startCol == cellCol) {
                            pressurePoints[i].gridIndex = Qt.point(row, col)
                            pressurePoints[i].position = Qt.point(col*xGridSpacing+xGridSpacing/2, row*yGridSpacing+yGridSpacing/2);
                            updateField()
                        }
                    }
                    break;
                }
            }
        }

        onPressed:  {
            var maxPointPairs = maxPressurePointPairs
            var length = touchPoints.length
            for (var t = 0; t < length; t++) {
                var startRow = Math.floor(touchPoints[t].startY/yGridSpacing)
                var startCol = Math.floor(touchPoints[t].startX/xGridSpacing)
                switch (windField.currentAction) {
                case 1:
                    for (var i = 0; i < maxPointPairs; i++) {
                        if (!pressurePoints[i].state) {
                            pressurePoints[i].state = selected
                            pressurePoints[i].strength = 100.0
                            pressurePoints[i].position = Qt.point(touchPoints[t].startX, touchPoints[t].startY)
                            //Temporarily use gridIndex to store the start coordinates for use later
                            pressurePoints[i].gridIndex = Qt.point(touchPoints[t].startX, touchPoints[t].startY)
                            break
                        }
                    }
                    break;
                case 2:
                    for (var i = maxPointPairs; i < maxPointPairs*2; i++) {
                        if (!pressurePoints[i].state) {
                            pressurePoints[i].state = selected
                            pressurePoints[i].strength = 0.0
                            pressurePoints[i].position = Qt.point(touchPoints[t].startX, touchPoints[t].startY)
                            //Temporarily use gridIndex to store the start coordinates for use later
                            pressurePoints[i].gridIndex = Qt.point(touchPoints[t].startX, touchPoints[t].startY)
                            break
                        }
                    }
                    break;
                case 3:
                    break;
                case 0:
                    for (var i = 0; i < maxPointPairs*2; i++) {
                        if (!pressurePoints[i].state)
                            continue
                        var cellRow = pressurePoints[i].gridIndex.x
                        var cellCol = pressurePoints[i].gridIndex.y
                        if (startRow == cellRow && startCol == cellCol) {
                            pressurePoints[i].state = selected
                            pressurePoints[i].position = Qt.point(touchPoints[t].startX, touchPoints[t].startY)
                        }
                    }
                    break;
                }
            }
        }

        onUpdated: {
           var maxPointPairs = maxPressurePointPairs
           var length = touchPoints.length
           for (var t = 0; t < length; t++) {
               var row = Math.floor(touchPoints[t].y/yGridSpacing)
               var col = Math.floor(touchPoints[t].x/xGridSpacing)
               var prevRow = Math.floor(touchPoints[t].previousY/yGridSpacing)
               var prevCol = Math.floor(touchPoints[t].previousX/xGridSpacing)
               switch (windField.currentAction) {
               case 1:
                   for (var i = 0; i < maxPointPairs; i++) {
                       if (pressurePoints[i].state == selected &&
                               pressurePoints[i].position.x == touchPoints[t].previousX &&
                               pressurePoints[i].position.y == touchPoints[t].previousY) {
                           pressurePoints[i].position = Qt.point(touchPoints[t].x, touchPoints[t].y)
                           break;
                       }
                   }                   
                   break;
               case 2:
                   for (var i = maxPointPairs; i < maxPointPairs*2; i++) {
                       if (pressurePoints[i].state == selected &&
                               pressurePoints[i].position.x == touchPoints[t].previousX &&
                               pressurePoints[i].position.y == touchPoints[t].previousY) {
                           pressurePoints[i].position = Qt.point(touchPoints[t].x, touchPoints[t].y)
                           break;
                       }
                   }
                   break;
               case 3:
                   break;
               case 0:
                   var startRow = Math.floor(touchPoints[t].startY/yGridSpacing)
                   var startCol = Math.floor(touchPoints[t].startX/xGridSpacing)
                   for (var i = 0; i < maxPointPairs*2; i++) {
                       if (pressurePoints[i].state != selected)
                           continue
                       var cellRow = pressurePoints[i].gridIndex.x
                       var cellCol = pressurePoints[i].gridIndex.y
                       if (startRow == cellRow && startCol == cellCol) {
                            pressurePoints[i].position = Qt.point(touchPoints[t].x, touchPoints[t].y)
                       }
                   }
                   break;
                }
            }
        }
    }
}
