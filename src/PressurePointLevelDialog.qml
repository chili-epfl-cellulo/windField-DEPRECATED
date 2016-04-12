import QtQuick 2.0
import QtQuick.Window 2.2

Rectangle{
    id: dialog

    property real visualMargin: 15

    radius: visualMargin

    x: parent.x
    y: parent.y

    width: childrenRect.width + 2*visualMargin
    height: childrenRect.height + 2*visualMargin

    property alias dialogModel: dialogList.model

    signal clicked(int plevel, int index)

    color: Qt.rgba(255, 255, 255, 0.9)

    ListView{
        id: dialogList
        spacing: visualMargin

        x: visualMargin
        y: visualMargin

        width: childrenRect.width
        height: Screen.height/6

        interactive: false
        orientation: ListView.Horizontal

        delegate: Rectangle{
            width: dialogListItemImg.width
            height: dialogListItemImg.height

            color: "transparent"

            Image{
                id: dialogListItemImg
                height: Screen.height/6
                fillMode: Image.PreserveAspectFit

                opacity: 1
                source: imagePath
            }
            MouseArea{
                anchors.fill: parent
                onClicked: {
                    console.log("Clicked PressurePointLevelDialogItem: " + plevel + " " + index);
                    if(name === "cancel")
                        hideDialog();
                    else
                        dialog.clicked(plevel, index);
                }
            }
        }
    }

    function showDialog(){
        showDialogAnim.start();
    }

    function hideDialog(){
        hideDialogAnim.start();
    }

    //Animations for showing and hiding

    SequentialAnimation{
        id : showDialogAnim

        PropertyAction{
            target: dialog
            property: "visible"
            value: true
        }

        PropertyAnimation{
            target: dialog
            property: "opacity"
            to: 0.8
            duration: 250
            easing.type: Easing.InQuad
        }
    }

    SequentialAnimation{
        id : hideDialogAnim

        PropertyAnimation{
            target: dialog
            property: "opacity"
            to: 0
            duration: 250
            easing.type: Easing.OutQuad
        }

        PropertyAction{
            target: dialog
            property: "visible"
            value: false
        }
    }
}
