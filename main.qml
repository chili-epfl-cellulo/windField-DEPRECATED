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



    CanvasField{
        anchors.fill: parent
        id: mainGameField
        robot:robotComm
      //  property alias windfield: windfield
    }





    CelluloBluetooth{
        id: robotComm
    }
}
