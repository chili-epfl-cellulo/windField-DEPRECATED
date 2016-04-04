import QtQuick 2.0

Item {
    id:root
    width: 2*parent.height/3
    height: 2*parent.height/3
    visible: true
    anchors.verticalCenter: parent.verticalCenter
    property bool activated: false
    property int ilevel: -3

    ListModel{
     id: lowpressureModel
        ListElement{
            imagePath:"assets/lowPressure5.png"
            name:"mid"
        }
        ListElement{
            imagePath:"assets/lowPressure3.png"
            name:"ll"
        }
        ListElement{
            imagePath:"assets/lowPressure4.png"
            name:"lll"
        }
     }

     PressurePointLevelDialog{
        id: newpDialog
        dialogModel:lowpressureModel
        opacity: 0
        onClicked: {
            // Put your logic here! Below is my logic from KDiamond QML version.
            // add pressure point of the level at the position

            // Dismiss new game dialog
            newpDialog.hideDialog= true;

            // Hide pop ups if any
            //hidePopup()
        }
     }



    MouseArea{
        id:mouseArea
        width: parent.width
        height: parent.height
        drag.target: ppImg
        onReleased:{
            newpDialog.x = ppImg.x
            newpDialog.y = ppImg.y - ppImg.height
            newpDialog.showDialog =true
        }
        //onReleased:parent = ppImg.Drag.target !== null? tile.Drag.target : root
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

            Drag.active: mouseArea.drag.active
            Drag.hotSpot.x: width/2
            Drag.hotSpot.y: height/2
        }
    }

}
