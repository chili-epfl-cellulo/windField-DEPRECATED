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
    width: Screen.width
    height: Screen.height
    title: qsTr("Wind Field Game")
    visibility:"FullScreen"
    contentOrientation: Screen.orientation


    MainForm{
        id:game
        focus:true
        property bool readystart: state=""
        property bool readyExplanation: state="general_explanation"
        property bool readyGame1: state="game1"


        state:""

        onReadystartChanged:  {
            console.log("Start changed ");
            //state="Start"

        }

        onReadyExplanationChanged: {
            console.log("explanation");
            //state="general_explanations"
        }

        onReadyGame1Changed: {
            console.log("game1 ");
            //state="game1"
        }

        onStateChanged: {
            console.log("Switch to game state " + state);
            if (state == "general_explanation") {
                intro();
            }
            if (state == "game1") {
                game1();
            }

        }

        Rectangle {
            id:rect
            width: 100; height: 100
            color: "green"
            visible:false
            MouseArea {
                anchors.fill: parent
                onClicked: { parent.color = 'red' ; state="game1"}
            }
        }

        function intro(){
            rect.visible = true
        }
        function game1() {
            mainGameField.visible= true;
        }


        Keys.onUpPressed: macAddrSelectors.updateKeys('u')
        Keys.onVolumeUpPressed: macAddrSelectors.updateKeys('u')
        Keys.onDownPressed: macAddrSelectors.updateKeys('d')
        Keys.onVolumeDownPressed: macAddrSelectors.updateKeys('d')
    }


    CanvasField{
        anchors.fill: parent
        id: mainGameField
        robot:cellulo1
        visible:false
        playground:playground
        //  property alias windfield: windfield
    }


    ZonesF{
        id:playground
        width: 1700 // in mm
        height: 660 // in mm
        function zonesByName(name) {
            var res = []
            for (var i = 0; i < zones.length; i++) {
                if (zones[i]["name"] === name)
                    res.push(zones[i]);
            }
            return res;
        }
    }


    Column{
           id: macAddrSelectors
           spacing: 5
           visible: false

           function updateKeys(keyCode){
               hideSelectors();
               var tempKeyHistory = [];
               for(var i=0;i<keyHistory.length;i++)
                   tempKeyHistory.push(keyHistory[i]);
               tempKeyHistory.push(keyCode);
               if(tempKeyHistory.length > 10)
                   tempKeyHistory.shift();
               keyHistory = tempKeyHistory;
           }

           function hideSelectors(){
               visible = false;
           }

           function showSelectors(){
               visible = true;
           }

           property variant keyHistory: []
           property variant keyCode: ['d','u','d','u','d','u','d','u','d','u']
           onKeyHistoryChanged:{
               if(keyHistory.length == 10){
                   for(var i=0;i<10;i++)
                       if(keyHistory[i] !== keyCode[i])
                           return;
                   showSelectors();
                   keyHistory = [];
               }
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
       }

       CelluloRobot{
           id: cellulo1
           playground: playground
           robotId: 1
       }
}
