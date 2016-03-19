import QtQuick 2.5
import QtQuick.Controls 1.4
import QtQuick.Dialogs 1.2
import QtQuick.Window 2.2
import QtQuick.Controls.Styles 1.4
import QtCanvas3D 1.0

import "renderer.js" as GLRender

ApplicationWindow {
    visible: true
    width: Screen.width
    height: Screen.height
    title: qsTr("Wind Field Game")
    visibility:"FullScreen"
    contentOrientation: Screen.orientation

    Canvas3D {
        id: windField
        width: Screen.width
        height: Screen.height

        property int menuMargin: 50
        property int fieldWidth: 2550
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
            pressurefield.addPressurePoint(0,0,true)
            pressurefield.addPressurePoint(14,0,true)
            pressurefield.addPressurePoint(0,25,true)
            pressurefield.addPressurePoint(14,25,true)
            pressurefield.addPressurePoint(7,12,false)
            pressurefield.addPressurePoint(8,12,false)
            pressurefield.addPressurePoint(7,13,false)
            pressurefield.addPressurePoint(8,13,false)

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

            testLeaf2.leafX = 10*pressurefield.xGridSpacing
            testLeaf2.leafY = 2*pressurefield.yGridSpacing
            testLeaf2.leafXV = 0
            testLeaf2.leafYV = 0
            testLeaf2.leafMass = 1
            testLeaf2.leafSize = 50
            testLeaf2.leafXF = 0
            testLeaf2.leafYF = 0
            testLeaf2.leafXFDrag = 0
            testLeaf2.leafYFDrag = 0

            pauseSimulation()
            //testLeaf.robotComm.macAddr = "00:06:66:74:43:01"
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
            pressurefield.initializeWindField()
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
        }

        Leaf {
            id: testLeaf2
            field: pressurefield
        }
    }
    UIPanel {
        anchors.fill: parent
        id: controls
    }
}
