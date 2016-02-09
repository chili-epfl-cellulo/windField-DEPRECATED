import QtQuick 2.5
import QtQuick.Controls 1.4
import QtQuick.Dialogs 1.2
import QtQuick.Window 2.2
import QtQuick.Controls.Styles 1.4

ApplicationWindow {
    visible: true
    width: 640
    height: 480
    title: qsTr("Hello World")
    visibility:"FullScreen"

    Image {
        id: background
        anchors.fill: parent
        source: "assets/background.jpg"
    }
    Canvas {
        id: windField
        anchors.fill: parent
        //width: 2560, height 1600
        property int robotMaxY: 1600.0 //reset this, for now assume that it is the same as the context dimensions
        // can always scale robot coordinates down later to fit into screen.
        property int robotMaxX: 2560.0 //reset this
        //Right now I have the leaf following whatever the wind flow is, should I add inertia? If so I need
        //a velocity and acceleration of the leaf as well

        //Game interaction variables
        property bool paused: false
        property bool drawPressureGrid: true
        property bool drawForceGrid: true
        property bool drawLeafVelocityVector: true
        property bool drawLeafForceVectors: true
        property int ticks: 0
        property int currentAction: 0

        //Pressure state
        property variant pressureGrid: []

        //TODO: Create some kind of structure for the leaf/robot
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

        //Pressure points
        property int maxPressurePointPairs: 10
        property variant pressurePoints: []
        property variant pressureDragInput: []

        //Global ontants
        property double pressureToForceMultiplier: 1
        property double pressureTransferRate: .5
        property double maxForce: 15.0
        property double dragCoefficient: .05
        property double maxVelocity: maxForce/dragCoefficient
        property double timeStep: .25
        property int gridDensity: 1 //Preferably an odd number to have nice vector spacing
        property int numCols: 26*gridDensity
        property int numRows: 16*gridDensity

        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0,0, width, height);
            drawPressureFields(ctx)
            drawPressureCellInput(ctx)
            drawForceField(ctx, gridDensity)
            drawLeafVectors(ctx)
            ctx.drawImage("assets/leaf.png", leafX-leafSize/2,leafY-leafSize/2, leafSize, leafSize)
        }

        function togglePaused() {
            paused = !paused
            if (paused)
                pause.text = 'Resume'
            else
                pause.text = 'Pause'
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
            requestPaint()
        }

        function initializeWindField() {
            var xGridSpacing = (robotMaxX/numCols)
            var yGridSpacing = (robotMaxY/numRows)
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
        }

        Component.onCompleted: {
            windField.initializeWindField()
            loadImage("assets/leaf.png")
        }

        function setObstacles() {
            pressureGrid[13][24][6] = 0
            pressureGrid[13][23][6] = 0
            pressureGrid[14][23][6] = 0
            pressureGrid[14][24][6] = 0
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
                if (r == row && c == col)
                    pressurePoints[i] = 0
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
                        return
                    }
                }
            } else {
                for (var p = maxPressurePointPairs; p < maxPressurePointPairs*2; p++) {
                    if (!pressurePoints[p]) {
                        pressurePoints[p] = Qt.point(r,c)
                        return
                    }
                }
            }
        }

        /***STATE UPDATE METHODS***/
        function updateField() {
            if (paused)
                return;
            calculateForceVectors()
            updateLeaf()

            updatePressureGrid()
            setPressurePoints()
            requestPaint()

            ticks++
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
                            if ((!rowOffset && !colOffset) || colIndex >= numCols || colIndex < 0 || (!pressureGrid[rowIndex][colIndex][6]))
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

                    //todo gotta do something about this max
                    var forceMagScale = Math.sqrt(nFX*nFX+nFY*nFY)/maxForce
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
            var xGridSpacing = (robotMaxX/numCols)
            var yGridSpacing = (robotMaxY/numRows)

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
            //update position from one time step given current velocity and current force
            var deltaX = leafXV*timeStep+.5*netForceX/leafMass*timeStep*timeStep
            var deltaY = leafYV*timeStep+.5*netForceY/leafMass*timeStep*timeStep
            leafXV += netForceX/leafMass*timeStep
            leafYV += netForceY/leafMass*timeStep
            leafX += deltaX
            leafY += deltaY
            if (leafX > robotMaxX-leafSize/2 || leafX < 0) {
                leafXV = 0;
                leafX = Math.max(Math.min(leafX, robotMaxX-leafSize/2), 0.0)
            } else if (leafY > robotMaxY-leafSize/2 || leafY < 0) {
                leafYV = 0;
                leafY = Math.max(Math.min(leafY, robotMaxY-leafSize/2), 0.0)
            }

            //Calculate forces at leaf at the new position so we can draw them now
            calculateForcesAtLeaf()
        }

        /***DRAWING METHODS***/
        function drawPressureFields(ctx) {
            if (!drawPressureGrid)
                return
            var xGridSpacing = (robotMaxX/numCols)
            var yGridSpacing = (robotMaxY/numRows)
            for (var row = 0; row < numRows; row++) {
                for (var col = 0; col < numCols; col++) {
                    if (!pressureGrid[row][col][6]) {
                        ctx.fillStyle = Qt.rgba(0,0,0,.75)
                    } else {
                        var pressure = pressureGrid[row][col][4];
                        ctx.fillStyle = Qt.rgba(pressure/100.0, 0, (100-pressure)/100.0, .75)
                    }
                    ctx.fillRect(col*xGridSpacing,row*yGridSpacing,xGridSpacing,yGridSpacing)
                }
            }
        }

        function drawPressureCellInput(ctx) {
            var xGridSpacing = (robotMaxX/numCols)
            var yGridSpacing = (robotMaxY/numRows)

            //Draw outlines for existing pressure points
            for (var i = 0; i < maxPressurePointPairs*2; i++) {
                if (!pressurePoints[i])
                    continue
                var row = pressurePoints[i].x
                var col = pressurePoints[i].y
                ctx.lineWidth = 5
                if (i < maxPressurePointPairs)
                    ctx.strokeStyle = Qt.rgba(1,.5,0,1)
                else
                    ctx.strokeStyle = Qt.rgba(0,0,.5,1)
                ctx.strokeRect(col*xGridSpacing,row*yGridSpacing,xGridSpacing,yGridSpacing)
            }

            //Draw the pressure cell selection outline rects
            for (var i = 0; i < pressureDragInput.length; i++) {
                if (!pressureDragInput[i])
                    continue
                var row = pressureDragInput[i].x
                var col = pressureDragInput[i].y
                ctx.lineWidth = 5
                if (row < 0)
                    ctx.strokeStyle = Qt.rgba(.25,.25,.25,.75)
                else if (i < maxPressurePointPairs)
                    ctx.strokeStyle = Qt.rgba(1,1,0,.75)
                else if (i >= maxPressurePointPairs)
                    ctx.strokeStyle = Qt.rgba(0,1,1,.75)
                ctx.strokeRect(col*xGridSpacing,row*yGridSpacing,xGridSpacing,yGridSpacing)
            }
        }

        function drawLeafVectors(ctx) {
            if (drawLeafVelocityVector) {
                // Draw velocity vector
                var vectorDrawX = leafXV*5
                var vectorDrawY = leafYV*5
                drawVector(ctx, leafX, leafY, vectorDrawX, vectorDrawY, "white", 50.0/maxVelocity, leafSize, leafSize/2)
            }

            if (drawLeafForceVectors) {
                //Draw force vector
                vectorDrawX = 400*leafXF/maxForce
                vectorDrawY = 400*leafYF/maxForce
                drawVector(ctx, leafX, leafY, vectorDrawX, vectorDrawY, "yellow", 1.0/maxForce, leafSize, leafSize/2)

                //Draw drag vector
                vectorDrawX = 400*leafXFDrag/maxForce
                vectorDrawY = 400*leafYFDrag/maxForce
                drawVector(ctx, leafX, leafY, vectorDrawX, vectorDrawY, "red", 1.0/maxForce, leafSize, leafSize/2)
            }
        }

        //todo: gaussian average of force vectors when frequency > 1?
        function drawForceField(ctx, gridDensity) {
            if (!drawForceGrid)
                return
            var xGridSpacing = robotMaxX/numCols
            var yGridSpacing = robotMaxY/numRows
            for (var row = Math.floor(gridDensity/2); row < numRows; row+=gridDensity) {
                for (var col = Math.floor(gridDensity/2); col < numCols; col+=gridDensity) {
                    if (!pressureGrid[row][col][6])
                        continue;

                    var forceX = pressureGrid[row][col][2]
                    var forceY = pressureGrid[row][col][3]

                    var centerX = xGridSpacing/2+col*xGridSpacing;
                    var centerY = yGridSpacing/2+row*yGridSpacing;

                    var forceScaling = 50.0/maxForce
                    var windVectorX = forceX*forceScaling
                    var windVectorY = forceY*forceScaling

                    drawVector(ctx, centerX, centerY, windVectorX, windVectorY, Qt.rgba(0,0,0,1), 5.0/maxForce, 10.0 ,0)
                }
            }
        }

        function drawVector(ctx, cX, cY, vX, vY, color, widthScaling, widthMax, centerOffset) {
            ctx.strokeStyle = color
            ctx.fillStyle = color

            var vecMagnitude = Math.sqrt(vX*vX+vY*vY)
            var vectorOffsetFactor = centerOffset/vecMagnitude

            var vecX = vX + vectorOffsetFactor*vX
            var vecY = vY + vectorOffsetFactor*vY
            ctx.lineWidth = Math.min(widthMax, Math.max(2,widthScaling*vecMagnitude))

            var vectorTipX = cX+vecX
            var vectorTipY = cY+vecY
            var vectorUnitX = vX/vecMagnitude
            var vectorUnitY = vY/vecMagnitude
            var arrowHeadSizeX = vectorUnitX*ctx.lineWidth*1.5
            var arrowHeadSizeY = vectorUnitY*ctx.lineWidth*1.5
            var perpVecX = -arrowHeadSizeY
            var perpVecY = arrowHeadSizeX

            ctx.beginPath()
            ctx.moveTo(cX, cY)
            //Make arrow shaft overlap with arrowhead slightly for floating point drawing seam errors
            ctx.lineTo(vectorTipX-arrowHeadSizeX*.95, vectorTipY-arrowHeadSizeY*.95)
            ctx.stroke()

            ctx.beginPath()
            ctx.moveTo(vectorTipX, vectorTipY)
            ctx.lineTo(vectorTipX-arrowHeadSizeX + perpVecX, vectorTipY-arrowHeadSizeY + perpVecY)
            ctx.lineTo(vectorTipX-arrowHeadSizeX - perpVecX, vectorTipY-arrowHeadSizeY - perpVecY)
            ctx.closePath()
            ctx.fill()
        }

        /***PAINT LOOP TIMER***/
        Timer {
            id: paintTimer
            interval: 10
            repeat: true
            running: true
            triggeredOnStart: true
            onTriggered: windField.updateField()
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
                var xGridSpacing = (windField.robotMaxX/windField.numCols)
                var yGridSpacing = (windField.robotMaxY/windField.numRows)
                var maxPointPairs = windField.maxPressurePointPairs
                var length = touchPoints.length
                for (var t = 0; t < length; t++) {
                    var row = Math.floor(touchPoints[t].y/yGridSpacing)
                    var col = Math.floor(touchPoints[t].x/xGridSpacing)
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
                        var startRow = Math.floor(touchPoints[t].startY/yGridSpacing)
                        var startCol = Math.floor(touchPoints[t].startX/xGridSpacing)
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
                            }
                        }
                        break;
                    }
                    actionMenu.enabled = !changingPressureCells()
                    windField.requestPaint()
                }
            }

            onPressed:  {
                var xGridSpacing = (windField.robotMaxX/windField.numCols)
                var yGridSpacing = (windField.robotMaxY/windField.numRows)
                var maxPointPairs = windField.maxPressurePointPairs
                var length = touchPoints.length
                for (var t = 0; t < length; t++) {
                    var startRow = Math.floor(touchPoints[t].startY/yGridSpacing)
                    var startCol = Math.floor(touchPoints[t].startX/xGridSpacing)
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
                windField.requestPaint()
            }

            onUpdated: {
               var xGridSpacing = (windField.robotMaxX/windField.numCols)
               var yGridSpacing = (windField.robotMaxY/windField.numRows)
                var maxPointPairs = windField.maxPressurePointPairs
               var length = touchPoints.length
               for (var t = 0; t < length; t++) {
                   var row = Math.floor(touchPoints[t].y/yGridSpacing)
                   var col = Math.floor(touchPoints[t].x/xGridSpacing)
                   var prevRow = Math.floor(touchPoints[t].previousY/yGridSpacing)
                   var prevCol = Math.floor(touchPoints[t].previousX/xGridSpacing)
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
                       var startRow = Math.floor(touchPoints[t].startY/yGridSpacing)
                       var startCol = Math.floor(touchPoints[t].startX/xGridSpacing)
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
                windField.requestPaint()
           }
        }
    }

    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: parent.top
        spacing: 5
        Column {
            id:menu
            z: 100
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
