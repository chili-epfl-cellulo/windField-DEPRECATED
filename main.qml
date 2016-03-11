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
        width: fieldWidth
        height: fieldHeight
        y: menuMargin

        property int menuMargin: 60
        property int fieldWidth: Screen.width
        property int fieldHeight: Screen.height-menuMargin

        //Game UI variables, kept here so that all components can have access to them
        property bool paused: false
        property bool drawPressureGrid: true
        property bool drawForceGrid: true
        property bool drawLeafVelocityVector: true
        property bool drawLeafForceVectors: true
        property bool drawPrediction: false
        property int currentAction: 0

        //Set the leaves here
        property variant leaves: [testLeaf, testLeaf2]
        property int numLeaves: 2

        function setInitialTestConfiguration(){
            //Set pressure point
            pressurefield.addPressurePoint(0,0,true)
            pressurefield.addPressurePoint(15,0,true)
            pressurefield.addPressurePoint(0,25,true)
            pressurefield.addPressurePoint(15,25,true)
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
            pressurefield.updateField()

            //Set test leaf info
            testLeaf.leafX = 4*pressurefield.xGridSpacing
            testLeaf.leafY = 2*pressurefield.yGridSpacing
            testLeaf.leafXV = 0
            testLeaf.leafYV = 0
            testLeaf.leafMass = 1
            testLeaf.leafSize = 50

            testLeaf.leafX = 10*pressurefield.xGridSpacing
            testLeaf.leafY = 2*pressurefield.yGridSpacing
            testLeaf.leafXV = 0
            testLeaf.leafYV = 0
            testLeaf.leafMass = 1
            testLeaf.leafSize = 50
            testLeaf.robotComm.macAddr = "00:06:66:74:43:01"
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
            anchors.fill: parent
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
