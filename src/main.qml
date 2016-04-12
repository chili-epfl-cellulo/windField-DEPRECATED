import QtQuick 2.5
import QtQuick.Controls 1.4
import QtQuick.Dialogs 1.2
import QtQuick.Window 2.2
import QtQuick.Controls.Styles 1.4
import QtQuick.Layouts 1.1
import QtCanvas3D 1.0
import Cellulo 1.0
import "renderer.js" as GLRender

ApplicationWindow {
    visible: true
    width: Screen.width
    height: Screen.height
    title: qsTr("Wind Field Game")
    visibility: "FullScreen"
    contentOrientation: Screen.orientation

    StateEngine{
        id: stateEngine

        states: [
            'MainMenu',
            'Tutorial1',
            'Game1',
            'Game2'
        ]

        onCurrentStateChanged: {
            mainMenu.visible = false;
            mainMenu.enabled = false;
            tutorial1.visible = false;
            tutorial1.enabled = false;
            mainGameField.visible = false;
            mainGameField.enabled = false;
            switch(currentState){
            case 'MainMenu':
                mainMenu.visible = true;
                mainMenu.enabled = true;
                break;
            case 'Tutorial1':
                tutorial1.visible = true;
                tutorial1.enabled = true;
                break;
            case 'Game1':
                mainGameField.visible = true;
                mainGameField.enabled = true;
                mainGameField.windfield.gameMode = 1;
                break;
            case 'Game2':
                mainGameField.visible = true;
                mainGameField.enabled = true;
                mainGameField.windfield.gameMode = 2;
                break;
            default:
                break;
            }
        }
    }

    MainMenu{
        id: mainMenu

        onGame1Clicked: stateEngine.goToStateByName('Game1')
        onGame2Clicked: stateEngine.goToStateByName('Game2')
    }

    Tutorial{
        id: tutorial1
        visible: false
        enabled: false
        baseName: 'Tutorial1'
        numScreens: 5
        animBaseNames:  ['ballon',  '',         '',             '',             'feel']
        animNumImages:  [120,       120,        51,             51,             36]
        animDurations:  [2400,      2400,       2000,           2000,           1400]
        animSizeCoeffs: [0.5,       0.5,        0.5,            0.5,            0.35]
        onFinished: stateEngine.goToStateByName('Game1')
    }

    MainGameField{
        anchors.fill: parent
        id: mainGameField
        robot: cellulo1
        visible: false
        enabled: false
        playground: playground
        //  property alias windfield: windfield
    }

    MouseArea {
        id: debugButton
        x: parent.width/2 - width/2
        y: 0
        width: parent.width/10
        height: parent.height/10
        smooth: false
        z: 20

        property bool showing: false
        onPressAndHold: {
            if(showing)
                debugMenu.hideMenu();
            else
                debugMenu.showMenu();
            showing = !showing;
        }
    }

    Column{
        id: debugMenu
        spacing: 5
        visible: false

        function hideMenu(){
            visible = false;
        }

        function showMenu(){
            visible = true;
            debugStateSelector.currentIndex = stateEngine.currentStateIndex;
        }

        property variant addresses: [
            "00:06:66:74:40:D2",
            "00:06:66:74:40:D4",
            "00:06:66:74:40:D5",
            "00:06:66:74:40:DB",
            "00:06:66:74:40:DC",
            "00:06:66:74:40:E4",
            "00:06:66:74:40:EC",
            "00:06:66:74:40:EE",
            "00:06:66:74:41:04",
            "00:06:66:74:41:14",
            "00:06:66:74:41:4C",
            "00:06:66:74:43:00",
            "00:06:66:74:46:58",
            "00:06:66:74:46:60",
            "00:06:66:74:48:A7"
        ]

        Row{
            spacing: 5

            Label{ text: "Robot " + cellulo1.robotId }
            MacAddrSelector{
                addresses: parent.parent.addresses
                onConnectRequested: cellulo1.robotComm.macAddr = selectedAddress
                onDisconnectRequested: cellulo1.robotComm.disconnectFromServer()
                connected: cellulo1.robotComm.connected
                connecting: cellulo1.robotComm.connecting
            }
        }

        Row{
            spacing: 5

            Label{ text: "Change current state: " }
            ComboBox{
                id: debugStateSelector
                model: stateEngine.states
                onCurrentIndexChanged: {
                    if(currentIndex >= 0)
                        stateEngine.goToStateByIndex(currentIndex);
                }
            }
        }
    }

    ZonesF{
        id: playground
        property real widthmm: 1700 // in mm
        property real heightmm: 660 // in mm
        property real gridSize: 0.508 //in mmm
        function zonesByName(name) {
            var res = []
            for (var i = 0; i < zones.length; i++) {
                if (zones[i]["name"] === name)
                    res.push(zones[i]);
            }
            return res;
        }
    }

    CelluloRobot{
        id: cellulo1
        playground: playground
        robotId: 1
 	//robotComm.macAddr : "00:06:66:74:40:DC"
        robotComm.onKidnappedChanged:{
            mainGameField.windfield.leaves[0].collided = robotComm.kidnapped
        }
        robotComm.onTouchBegan:{
            mainGameField.windfield.leaves[0].tangible = true
        }
        robotComm.onTouchReleased:{
            mainGameField.windfield.leaves[0].tangible = false
        }
        robotComm.onPoseChanged: {
            mainGameField.windfield.leaves[0].updateCellulo()

        }
    }
}
