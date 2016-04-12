import QtQuick 2.5
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.2

Item{
    focus: true
    width: parent.width
    height: parent.height

    signal game1Clicked()
    signal game2Clicked()

    Rectangle{
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter:  parent.verticalCenter
        width: parent.width
        height: parent.height

        Image {
            id: background
            anchors.fill: parent
            source: "../assets/backgrounds/MainMenuBackground.png"
        }
    }

    RowLayout{
        spacing: 200
        y: 3*parent.height/4
        anchors.horizontalCenter: parent.horizontalCenter

        Rectangle{
            width: 700
            height: 300
            color: "yellow"
            radius: width*0.5
            opacity: 0.6

            Text{
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                font.family: "Helvetica"
                font.pointSize: 25
                font.bold: true
                text: "Feel the wind"
            }

            MouseArea{
                anchors.fill: parent
                onClicked: {
                    parent.color = 'red';
                    game1Clicked();
                }
            }
        }

        Rectangle{
            width: 700
            height: 300
            color: "green"
            radius: width*0.5
            opacity: 0.6

            Text{
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                font.family: "Helvetica"
                font.pointSize: 25
                font.bold: true
                text: "Control the wind"
            }

            MouseArea{
                anchors.fill: parent
                onClicked: {
                    parent.color = 'red';
                    game2Clicked();
                }
            }
        }
    }
}

