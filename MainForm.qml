import QtQuick 2.5
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.2

Item {

    //property alias mouser: mouser
    //property alias button: button
    property alias background: background
    //property alias canvas: canvas

    property alias infoBox: infoBox

    property alias stateSkipper: stateSkipper

    width: 2560
    height: width * 10/16

    Rectangle{
     id: blackBg
     color:"#000000"
     anchors.fill: parent
     Image {
         id: background
         anchors.fill: parent
         source: "assets/start/windUiStart.png"
    }

     MouseArea {
         id: stateSkipper
         x: 1230
         y: 20
         width: 100
         height: 100
         anchors.horizontalCenter: background.horizontalCenter
         smooth: false
         z: 20
     }

     Text {
         id: infoBox
         x: 836
         y: 1448
         color: "#ffffff"
         text: qsTr("connecting ...")
         font.italic: true
         anchors.horizontalCenter: parent.horizontalCenter
         font.pixelSize: 70
     }

    }

    /*property variant stateOrder:[   [start],
                                    [explanations],
                                    [game1Rules,game1Play],
                                    [game2Rules,game2Play],
                                    [game3Rules,game3Play],
                                    [goFurther],
                                    [finish]
                               ]
*/
    states: [
        State {
            name: "Start";
            when: state==="" && mouser.pressed;

            PropertyChanges {
                target: background
                source: "assets/windUi-1.png"
            }

        }
    ,
        State {
            name: "general_explanations"
            PropertyChanges {
                target: background
                source: "assets/windUi-1.png"
            }
        },

        State {
            name: "game1"
            /*PropertyChanges {
                target: canvas
                visible :true
            }*/
        }

    ]




}

