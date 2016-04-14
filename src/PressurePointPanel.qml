import QtQuick 2.5
import QtQuick.Window 2.0
import Cellulo 1.0
import "renderer.js" as GLRender

Rectangle {
    readonly property real pressurePointPanelHeight: Screen.height/5
    readonly property real pressurePointPanelRadius: 155

    anchors.bottom: parent.bottom
    anchors.left: parent.left
    width: parent.width
    height: pressurePointPanelHeight

    color: Qt.rgba(1,1,1,0.7)

    radius: pressurePointPanelRadius

    property real spacing: pressurePointPanelHeight/2

    function arrangeOwnedPressurePoints(){
        var currentPressurePointStockX = 0;
        for(var i=0;i<children.length;i++)
            if(children[i].objectName === "DummyPressurePoint"){
                children[i].initialImgX = currentPressurePointStockX + spacing;
                children[i].initialImgY = spacing;
                children[i].putImageBack();
                currentPressurePointStockX += children[i].imageWidth + spacing;
            }
    }

    function removeOwnedPressurePoints(){
        for(var i=0;i<children.length;i++)
            if(children[i].objectName === "DummyPressurePoint")
                children[i].removeForcefully();
    }

    onChildrenChanged: arrangeOwnedPressurePoints()
}
