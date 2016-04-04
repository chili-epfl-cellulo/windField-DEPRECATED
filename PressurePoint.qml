import QtQuick 2.0

Item {
    id:root
    width: 2*parent.height/3
    height: 2*parent.height/3
    visible: true
    anchors.verticalCenter: parent.verticalCenter
    property bool activated: false
    property int ilevel: -3

    MouseArea{
        id:mouseArea
        width: parent.width
        height: parent.height
        drag.target: ppImg
        onReleased:parent = ppImg.Drag.target !== null? tile.Drag.target : root
        Image {
            id: ppImg
            source:
                switch (ilevel){
                case -1:
                    "assets/lowPressure2.png"
                    break;
                case -2:
                    "assets/lowPressure2.png"
                    break;
                case -3:
                    "assets/lowPressure2.png"
                    break;
                case 1:
                    "assets/highPressure2.png"
                    break;
                case 2:
                    "assets/highPressure2.png"
                    break;
                case 3:
                    "assets/lowPressure2.png"
                    break;
                }

            Drag.active: dragArea.drag.active
            Drag.hotSpot.x: width/2
            Drag.hotSpot.y: height/2
        }
    }

}
