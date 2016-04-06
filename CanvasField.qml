import QtQuick 2.0
import QtCanvas3D 1.0
import Cellulo 1.0
import "renderer.js" as GLRender
Item {
    width: parent.width
    height: parent.height
    property variant robot: robotComm
    property variant windfield: windField
    property int fieldWidth: 2500
    property int fieldHeight: 950

    visible: false
    Canvas3D {
        id: windField
        width: parent.width
        height: parent.height


        property int menuMargin: 50
        property int fieldWidth: 2500
        property int fieldHeight: 950

        property int robotMinX: (windField.width - windField.fieldWidth)/2
        property int robotMinY: (windField.height - windField.fieldHeight)/2
        property int robotMaxX: robotMinX + windField.fieldWidth
        property int robotMaxY: robotMinY + windField.fieldHeight

        //Game UI variables, kept here so that all components can have access to them
        property bool paused: true
        property bool drawPressureGrid: true
        property bool drawForceGrid: true
        property bool drawLeafVelocityVector: true
        property bool drawLeafForceVectors: true
        property bool drawPrediction: false
        property int currentAction: 0

        //Set the leaves here
        property variant leaves: [testLeaf]
        property int numLeaves: 1

        property variant game: 3

        ZonesF{
            id:allzones
        }

        function addPressurePoint(r,c,pressureLevel) {
            console.log('called here')
            pressurefield.addPressurePoint(r,c,pressureLevel)
        }

        function addPressurePointCoord(y,x,pressureLevel) {
            console.log('called here')
            var r = y
            var c = x
            pressurefield.addPressurePoint(r,c,pressureLevel)
        }

        function setInitialTestConfiguration(){

            //Set pressure point
            pressurefield.addPressurePoint(0,0,3)
            pressurefield.addPressurePoint(14,0,3)
            pressurefield.addPressurePoint(0,25,3)
            pressurefield.addPressurePoint(14,25,3)
            pressurefield.addPressurePoint(7,12,-3)
            pressurefield.addPressurePoint(8,12,-3)
            pressurefield.addPressurePoint(7,13,-3)
            pressurefield.addPressurePoint(8,13,-3)

            setObstaclesfromZones()

            //Set test leaf info
            testLeaf.leafX = 10*pressurefield.xGridSpacing
            testLeaf.leafY = pressurefield.height/2
            testLeaf.leafXV = 20
            testLeaf.leafYV = 0
            testLeaf.leafMass = 5
            testLeaf.leafSize = 150
            testLeaf.leafXF = 0
            testLeaf.leafYF = 0
            testLeaf.leafXFDrag = 2
            testLeaf.leafYFDrag = 0
            testLeaf.collided = false

            pauseSimulation()
            //testLeaf.robotComm.macAddr = "00:06:66:74:43:01"
        }
        // - Set obstacle spots
        function setObstacles() {
            pressurefield.pressureGrid[10][30][6] = 0
        }

        // - transform a point (between 0 and 1) to coordinates in the pressureGrid
        function fromPointToCoords(ptx,pty){
            return   [Math.round(ptx*pressurefield.numCols),Math.round(pty*pressurefield.numRows)];
        }

        // - return true if the point is in the polygone poly
        function isPointInPoly(poly, pt){
            for(var c = false, i = -1, l = poly.length, j = l - 1; ++i < l; j = i){
                //console.log(poly[i].x,poly[i].y )
                if(
                        ((poly[i].y <= pt.y && pt.y < poly[j].y) || (poly[j].y <= pt.y && pt.y < poly[i].y))
                        && (pt.x < (poly[j].x - poly[i].x) * (pt.y - poly[i].y) / (poly[j].y - poly[i].y) + poly[i].x)
                        && (c = !c));
                //console.log(c)
                return c;
            }
        }
        function setObstaclesfromZones(){
            // TODO : PLACEMENT NOT ACCURATE OF THE ZONES
            //console.log("start zoning")
            var zoneObstacles = allzones.zonelist
            for (var i = 0; i < zoneObstacles.length; i++) {
                console.log(zoneObstacles[i]["name"])
                if(zoneObstacles[i]["name"].indexOf("obstacle")===0 ||zoneObstacles[i]["name"].indexOf("cloud")===0){
                    var pathcoord = []
                    var minPX = pressurefield.numCols;var minPY = pressurefield.numRows;var maxPX = 0;var maxPY = 0;
                    for( var j =0 ; j< zoneObstacles[i]["path"].length; j++){
                        var point  = zoneObstacles[i]["path"][j]
                        var coord = fromPointToCoords(point.x,point.y)

                        minPX = Math.min(minPX,coord[0])
                        maxPX = Math.max(maxPX,coord[0])
                        minPY = Math.min(minPY,coord[1])
                        maxPY = Math.max(maxPY,coord[1])
                        pathcoord.push(Qt.point(coord[1],coord[0]))
                        pressurefield.pressureGrid[coord[1]][coord[0]][6] = 0

                    }
                    //console.log(minPX,minPY,maxPX,maxPY)
                    //console.log(pathcoord)
                    // - try to fill the zone with obstacle
                    // TODO : NOT COVERING THE WHOLE ZONE
                    for (var px = minPX ; px<maxPX; px++){
                        for (var py = minPY ; py<maxPY ; py++){
                            if(isPointInPoly(pathcoord, Qt.point(py,px)))
                                pressurefield.pressureGrid[py][px][6] = 0
                        }
                    }
                }
            }
        }

        function pauseSimulation() {
            paused = false;
            controls.togglePaused()
        }

        onInitializeGL: {
            GLRender.initializeGL(windField, pressurefield, leaves, numLeaves)
        }

        //Since we do no update the pressure grid while the simulation is running, the only thing we have to update then are the leaves
        onPaintGL: {
            if (!paused) {
                for (var i = 0; i < numLeaves; i++)
                    leaves[i].updateLeaf()
            }
            GLRender.paintGL(pressurefield, leaves, numLeaves)
        }

        function setPressureFieldTextureDirty() {
            GLRender.pressureFieldUpdated = true;
        }

        Component.onCompleted: {
            pressurefield.resetWindField()
            setInitialTestConfiguration()
            //testLeaf.robotComm.macAddr = "00:06:66:74:43:00"
        }

        PressureField {
            width: windField.fieldWidth
            height: windField.fieldHeight
            x: windField.robotMinX
            y: windField.robotMinY
            id: pressurefield
        }

        Leaf {
            id: testLeaf
            field: pressurefield
            robot: robotComm
        }
    }

    UIPanel {
        //anchors.fill: parent
        id: controls
        robot: robotComm
        windfield: windField
        width: parent.width
        height: parent.height /5
    }

    Rectangle {
        id: stockView
        y: parent.height -  controls.height
        anchors.left : windField.left
        width: controls.width
        height:  controls.height

        //anchors.fill: parent
        color: Qt.rgba(1,1,1,0.6)
        radius:155

        Row {
            id:rowPressure
            width:parent.width
            height: parent.height
            spacing: 50

            PressurePoint{
                id: pressurePoint1
                field: pressurefield
                ilevel: 2
            }
            PressurePoint{
                id: pressurePoint10
                field: pressurefield
                ilevel: -2
            }
            PressurePoint{
                id: pressurePoint2
                field: pressurefield
                ilevel: -1
            }
            PressurePoint{
                id: pressurePoint3
                field: pressurefield
                ilevel: 1
            }
        }
    }
}
