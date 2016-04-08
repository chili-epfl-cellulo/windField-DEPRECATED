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

    }


    CanvasField{
        anchors.fill: parent
        id: mainGameField
        robot:robotComm
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


   CelluloRobot{
        id: robotComm
        playground: playground

    }
}
