import QtQuick 2.5
import QtQuick.Controls 1.4
import QtQuick.Dialogs 1.2
import QtQuick.Window 2.2
import QtQuick.Controls.Styles 1.4

Item {
    property variant pressureGrid: []
    property variant pressurePoints: []
    property variant pressureDragInput: []
    readonly property int maxPressurePointPairs: 10

    readonly property int gridDensity: 1
    readonly property int numCols: 26*gridDensity
    readonly property int numRows: 16*gridDensity

    readonly property double xGridSpacing: (width/numCols)
    readonly property double yGridSpacing: (height/numRows)

    //Controls how much force there is per unit of pressure difference
    readonly property double pressureToForceMultiplier: 1
    readonly property double maxForce: 15.0

    //Controls how fast pressure disperses in a single time step
    readonly property double pressureTransferRate: .5

    //Controls how many loops we run the pressure update for before letting the balloon simulation start
    readonly property int convergenceIterations: 25

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
                cellArray[6] = 1.0 //0: obstacle 1:valid cell
                column[j] = cellArray
            }
            rows[i]=column
        }
        pressureGrid = rows
        pressurePoints = new Array(maxPressurePointPairs*2);        
        pressureDragInput = new Array(touchArea.maximumTouchPoints)
        updateField()
    }

    function resetPressureAtPressurePoints() {
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

    /***PRESSURE GRID STATE UPDATE METHODS***/
    function updateField() {
        //console.log("Robot Position X: ", robotComm.x, "Robot Position Y: ", robotComm.y)
        for (var i = 0; i < convergenceIterations; i++) {
            updatePressureGrid()
            resetPressureAtPressurePoints()
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

    /***HELPER METHODS FOR ADDING, MOVING AND REMOVING PRESSURE POINTS***/
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

    /***Pressure field touch interations***/
    MultiPointTouchArea {
        id: touchArea
        anchors.fill: parent
        maximumTouchPoints: maxPressurePointPairs

        function changingPressureCells() {
            var length = pressureDragInput.length
            for (var i = 0; i < length; i++) {
                if (pressureDragInput[i])
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
                case 1:
                    if (pressureGrid[row][col][6])
                        addPressurePoint(row, col, true)
                    //Remove the cell input box
                    for (var i = 0; i < maxPointPairs; i++) {
                        if (pressureDragInput[i]) {
                            if (pressureDragInput[i].x == row && pressureDragInput[i].y == col) {
                                 pressureDragInput[i] = 0
                                 break;
                            }
                        }
                    }
                    break;
                case 2:
                    if (pressureGrid[row][col][6])
                        addPressurePoint(row, col, false)
                    //Remove the cell input box
                    for (var i = maxPointPairs; i < maxPointPairs*2; i++) {
                        if (pressureDragInput[i+maxPointPairs].x == row &&
                                pressureDragInput[i+maxPointPairs].y == col) {
                            pressureDragInput[i+maxPointPairs] = 0
                            break;
                        }
                    }
                    break;
                case 3:
                    removePressurePoint(row, col)
                    break;
                case 0:
                    var startRow = Math.floor(touchPoints[t].startY/yGridSpacing)
                    var startCol = Math.floor(touchPoints[t].startX/xGridSpacing)
                    for (var i = 0; i < maxPointPairs*2; i++) {
                        if (!pressurePoints[i])
                            continue
                        var cellRow = pressurePoints[i].x
                        var cellCol = pressurePoints[i].y
                        if (startRow == cellRow && startCol == cellCol) {
                            pressureDragInput[i] = 0
                            if (!pressureGrid[row][col][6])
                                return
                            pressurePoints[i].x = row
                            pressurePoints[i].y = col
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
                        if (!pressureDragInput[i]) {
                            pressureDragInput[i] = Qt.point(startRow, startCol)
                            break;
                        }
                    }
                    break;
                case 2:
                    for (var i = maxPointPairs; i < maxPointPairs*2; i++) {
                        if (!pressureDragInput[i+maxPointPairs]) {
                            pressureDragInput[i+maxPointPairs] = Qt.point(startRow, startCol)
                            break;
                        }
                    }
                    break;
                case 3:
                    break;
                case 0:
                    for (var i = 0; i < maxPointPairs*2; i++) {
                        if (!pressurePoints[i])
                            continue
                        var cellRow = pressurePoints[i].x
                        var cellCol = pressurePoints[i].y
                        if (startRow == cellRow && startCol == cellCol) {
                             pressureDragInput[i] = Qt.point(startRow,startCol)
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
                       if (pressureDragInput[i]) {
                           if (pressureDragInput[i].x == prevRow && pressureDragInput[i].y == prevCol) {
                                pressureDragInput[i] = Qt.point(row, col)
                                break;
                           }
                       }
                   }
                   break;
               case 2:
                   for (var i = maxPointPairs; i < maxPointPairs*2; i++) {
                       if (pressureDragInput[i+maxPointPairs].x == prevRow &&
                               pressureDragInput[i+maxPointPairs].y == prevCol) {
                           pressureDragInput[i+maxPointPairs] = Qt.point(row, col)
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
                       if (!pressurePoints[i])
                           continue
                       var cellRow = pressurePoints[i].x
                       var cellCol = pressurePoints[i].y
                       if (startRow == cellRow && startCol == cellCol) {
                            pressureDragInput[i] = Qt.point(row,col)
                       }
                   }
                   break;
                }
            }
        }
    }
}
