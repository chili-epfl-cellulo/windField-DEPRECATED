import QtQuick 2.5
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.2

Item {


    property alias background: background
    //property alias selectionRect: selectionRect

    width: 2560
    height: width * 10/16

    Rectangle{
        id: blackBg
        color:"#000000"
        anchors.fill: parent
        state:""
        Image {
            id: background
            anchors.fill: parent
            source: "assets/start/windUiStart.png"

            MouseArea {
                id: starter
                width: parent.width
                height: parent.height
                anchors.horizontalCenter: background.horizontalCenter
                onClicked: {
                    console.log('clicked')
                    console.log(blackBg.state)
                    blackBg.state="select"
                }
            }
        }






    }
}

