import QtQuick 2.0

Rectangle {
    id:listdialog
    width: parent.width*3
    height: parent.height
    color: "teal"
    x:parent.x
    y:parent.y
    property alias dialogModel: dialoglist.model
    //property alias dialogtitle: dialogtitle.text
    signal clicked (int plevel, int index)
    property alias showDialog: showDialog.running
    property alias hideDialog: hideDialog.running
    radius:15
    MouseArea{
        anchors.fill: parent
        onClicked: {
            // Hide the dialog box if clicked outside
            //hideDialog.running = true

            // Resume the game as soon as Dialog is hidden
            //if(paused)
            //MainWindow.pauseButton_clicked(false)
        }
    }


    Rectangle{
        id:dialog
        width: parent.width
        height: parent.height
        anchors.centerIn: parent
        radius: 15
        /*MouseArea{
            anchors.fill: parent
        }*/

        ListView{
            id:dialoglist
            width: parent.width
            spacing: parent.width/6
            height:parent.height
            interactive: false
            orientation: ListView.Horizontal
            anchors.top: parent.top
            anchors.topMargin: 5
            model: mymodel
            onModelChanged: {
                dialoglist.height = dialoglist.model.count*(parent.height+spacing)
            }

            delegate: Rectangle{
                id: listitem
                width: parent.width /5
                height: parent.height
                radius: 10
                anchors.verticalCenter: parent.verticalCenter
                color: "teal"
                Image{
                       id: listitemText
                       source:imagePath
                }
                MouseArea{
                    id: delegateMouseArea
                    anchors.fill: listitemText
                    onClicked: {
                        console.log(listitemText.source)
                        listdialog.clicked(plevel, index)
                    }
                }
            }
        }
    }

    // Animating list dialog
    PropertyAnimation { id: showDialog; target: listdialog; property: "opacity"; to: 1; duration: 500; easing.type: Easing.InQuad   }
    PropertyAnimation { id: hideDialog; target: listdialog; property: "opacity"; to: 0; duration: 500; easing.type: Easing.OutQuad}
}





