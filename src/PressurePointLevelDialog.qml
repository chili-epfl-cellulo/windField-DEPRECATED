import QtQuick 2.0
import QtQuick.Window 2.2

Rectangle{
    id: dialog

    visible: false
    opacity: 0

    property real visualMargin: 15
    property real buttonHeight: Screen.height/6

    radius: visualMargin

    x: parent.x
    y: parent.y

    width: childrenRect.width + 2*visualMargin
    height: childrenRect.height + 2*visualMargin

    property alias dialogModel: dialogList.model

    signal clicked(int plevel)
    signal dialogShown()
    signal dialogHidden()

    color: Qt.rgba(255, 255, 255, 0.9)

    ListView{
        id: dialogList
        spacing: visualMargin

        x: visualMargin
        y: visualMargin

        width: childrenRect.width
        height: buttonHeight

        interactive: false
        orientation: ListView.Horizontal

        delegate: Rectangle{
            width: dialogListItemImg.width
            height: dialogListItemImg.height

            color: "transparent"

            Image{
                id: dialogListItemImg
                height: buttonHeight
                fillMode: Image.PreserveAspectFit

                opacity: 1
                source: imagePath
            }
            MouseArea{
                anchors.fill: parent
                onClicked: {
                    if(name === "cancel"){
                        hideDialog();
                        dialog.clicked(0);
                    }
                    else
                        dialog.clicked(plevel);
                }
            }
        }
    }

    function showDialog(targetX, targetY){
        x = Math.min(targetX, Screen.width - width);
        y = targetY;
        showDialogAnim.start();
        dialogShown();
    }

    function hideDialog(){
        hideDialogAnim.start();
        dialogHidden();
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
