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
        anchors.fill: parent

        property int fieldWidth: Screen.width
        property int fieldHeight: Screen.height

        //Game UI variables, kept here so that all components can have access to them
        property bool paused: false
        property bool drawPressureGrid: true
        property bool drawForceGrid: true
        property bool drawLeafVelocityVector: true
        property bool drawLeafForceVectors: true
        property bool drawPrediction: false
        property int currentAction: 0

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
            pressurefield.updateField()

            //Set test leaf info
            testLeaf.leafX = 4*pressureField.xGridSpacing
            testLeaf.leafY = 2*pressureField.yGridSpacing
            testLeaf.leafXV = 0
            testLeaf.leafYV = 0
            testLeaf.leafMass = 1
            testLeaf.leafSize = 50
            testLeaf.robotComm.macAddr = "00:06:66:74:43:01"
        }

        onInitializeGL: {
            GLRender.initializeGL(windField, pressurefield, testLeaf)
        }

        //Since we do no update the pressure grid while the simulation is running, the only thing we have to update then are the leaves
        onPaintGL: {
            if (!paused)
                testLeaf.updateLeaf()

            GLRender.paintGL(pressurefield, testLeaf)
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

        UIPanel {
            anchors.fill: parent
            id: controls
        }
    }
}
