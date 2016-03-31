import QtQuick 2.0
import QtCanvas3D 1.0
import Cellulo 1.0
import "renderer.js" as GLRender
Item {
    width: parent.width
    height: parent.height
    property variant robot: robotComm
    property variant windfield: windField
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

            setObstacles()
            //Set test leaf info
            testLeaf.leafX = 4*pressurefield.xGridSpacing
            testLeaf.leafY = 2*pressurefield.yGridSpacing
            testLeaf.leafXV = 0
            testLeaf.leafYV = 0
            testLeaf.leafMass = 1
            testLeaf.leafSize = 50
            testLeaf.leafXF = 0
            testLeaf.leafYF = 0
            testLeaf.leafXFDrag = 0
            testLeaf.leafYFDrag = 0
            testLeaf.collided = false

            /*testLeaf2.leafX = 10*pressurefield.xGridSpacing
            testLeaf2.leafY = 2*pressurefield.yGridSpacing
            testLeaf2.leafXV = 0
            testLeaf2.leafYV = 0
            testLeaf2.leafMass = 1
            testLeaf2.leafSize = 50
            testLeaf2.leafXF = 0
            testLeaf2.leafYF = 0
            testLeaf2.leafXFDrag = 0
            testLeaf2.leafYFDrag = 0*/

            pauseSimulation()
            //testLeaf.robotComm.macAddr = "00:06:66:74:43:01"
        }

        function setObstacles() {
            //Set obstacle spots
            pressurefield.pressureGrid[13][24][6] = 0
            pressurefield.pressureGrid[13][23][6] = 0
            pressurefield.pressureGrid[14][23][6] = 0
            pressurefield.pressureGrid[14][24][6] = 0

            pressurefield.pressureGrid[4][7][6] = 0
            pressurefield.pressureGrid[4][8][6] = 0
            pressurefield.pressureGrid[5][7][6] = 0
            pressurefield.pressureGrid[5][8][6] = 0
            pressurefield.pressureGrid[6][7][6] = 0
            pressurefield.pressureGrid[6][8][6] = 0
            pressurefield.pressureGrid[6][6][6] = 0

            var zoneObstacles = [{"name":"zone 0","path":[Qt.point(0.10833333333333334,0.6215741153931268),Qt.point(0.13166666666666665,0.5748893642369907),Qt.point(0.19583333333333333,0.6229079654261593),Qt.point(0.175,0.6615896163841006)]},{"name":"zone 1","path":[Qt.point(0.21666666666666667,0.46151211142923154),Qt.point(0.2866666666666667,0.5442108134772441),Qt.point(0.30833333333333335,0.5255369130147897),Qt.point(0.24083333333333334,0.44017051090071213)]},{"name":"zone 2","path":[Qt.point(0.06666666666666667,0.33479635829114773),Qt.point(0.22833333333333333,0.35080255868753724),Qt.point(0.22166666666666668,0.26410230654042727),Qt.point(0.060833333333333336,0.26276845650739483)]},{"name":"zone 3","path":[Qt.point(0.41,0.4548428612640692),Qt.point(0.5958333333333333,0.3254594080599205),Qt.point(0.535,0.23742530587977806),Qt.point(0.3983333333333333,0.3948196097776085)]},{"name":"zone 4","path":[Qt.point(0.3408333333333333,0.6602557663510682),Qt.point(0.39,0.7322836681348212),Qt.point(0.4825,0.734951368200886),Qt.point(0.4633333333333333,0.6629234664171332)]},{"name":"zone 5","path":[Qt.point(0.6708333333333333,0.4655136615283289),Qt.point(0.7741666666666667,0.5935632646994452),Qt.point(0.8025,0.5695539641048608),Qt.point(0.6991666666666667,0.42816586060342)]},{"name":"zone 6","path":[Qt.point(0.7133333333333334,0.2974485573662388),Qt.point(0.8633333333333333,0.33479635829114773),Qt.point(0.8641666666666666,0.2867777571019791),Qt.point(0.7275,0.2520976562431351)]}]
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
            testLeaf.robotComm.macAddr = "00:06:66:74:43:01"
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
        anchors.fill: parent
        id: controls
        robot: robotComm
        windfield: windField
    }

    Column {
        id: stockView
        x: 20
        y: parent.height -320
        width: parent.width - 40
        //state: "CLOSED"
        height: 310


        Rectangle {
            anchors.fill: parent
//            border.width: 5
//            border.color: "white"
            color: Qt.rgba(1,1,1,0.6)
            //opacity: 0.4
            radius:155
        }
    }


}
