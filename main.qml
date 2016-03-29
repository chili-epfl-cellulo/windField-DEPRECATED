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
            state="Start"
        }

        onReadyExplanationChanged: {
           state="general_explanations"
        }

        onReadyGame1Changed: {
          state="game1"
        }

        onStateChanged: {
            console.log("Switch to game state " + state);
            if (state == "game1") {
                game1();
            }

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
      //  property alias windfield: windfield
    }





    CelluloBluetooth{
        id: robotComm
    }
}
