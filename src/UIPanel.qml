import QtQuick 2.5
import QtQuick.Window 2.1
import QtQuick.Layouts 1.1
import QtQuick.Controls 1.2
import QtQuick.Controls.Private 1.0
import QtQuick.Controls.Styles 1.3
import QtBluetooth 5.2
import Cellulo 1.0

Rectangle {

    function em(x){ return Math.round(x*TextSingleton.font.pixelSize); }

    property bool mobile: Qt.platform.os === "android"
    property real gWidth: mobile ? Screen.width : 640
    property variant windfield: windField
    property variant robot: cellulo1
    property double startTime: 0
    property variant playground: playground
    property double secondsElapsed: 0
    property int numberOfLifes: windfield.nblifes
    property int totalpoint: 0

    function togglePaused() {
        windfield.paused = !windfield.paused
        if (windfield.paused){
            //timer.stop()

        }
        else{
            timer.restart()

        }
        //pressureUpdate.enabled = windfield.paused
    }

    function toggleDisplaySetting(setting) {
        switch(setting){
        case 1:
            windfield.drawPressureGrid = pressureGridCheck.checked
            break;
        case 2:
            windfield.drawForceGrid = forceGridCheck.checked
            break;
        case 3:
            windfield.drawLeafVelocityVector = leafVelocityCheck.checked
            break;
        case 4:
            windfield.drawLeafForceVectors = leafForceCheck.checked
            break;
        }
    }

    function updateSimulation() {
        pressurefield.updateField()
        for (var i = 0; i < windfield.numLeaves; i++)
            windfield.leaves[i].calculateForcesAtLeaf()
    }

    function showInfo(){
        console.log("showInfo clicked");
    }

    width: parent.width
    height: 0.19375*Screen.height
    color: Qt.rgba(1,1,1,0.6)
    radius: 155

    RowLayout {
        anchors.margins: 20
        anchors.fill: parent
        spacing: parent.height/10

        //Info button
        Item{
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: childrenRect.width

            Image{
                id: infoButtonImg
                anchors.verticalCenter: parent.verticalCenter
                height: 0.15*Screen.height
                fillMode: Image.PreserveAspectFit
                source: "../assets/buttons/help.svg"

                MouseArea {
                    anchors.fill: parent
                    onClicked: showInfo()
                }
            }
        }

        //Pressure switch
        Item{
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: childrenRect.width

            Column {
                id: pressureButton

                anchors.verticalCenter: parent.verticalCenter
                spacing: 20

                property bool switchOn: false

                Image{
                    id: pressureButtonImg
                    height: 0.08*Screen.height
                    fillMode: Image.PreserveAspectFit
                    source: "../assets/buttons/" + (pressureButton.switchOn ? "gradientOn.svg" : "gradientOff.svg")

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            pressureButton.switchOn = !pressureButton.switchOn;
                            windfield.drawPressureGrid = pressureButton.switchOn;
                        }
                    }
                }

                Text{
                    anchors.horizontalCenter: parent.horizontalCenter
                    font.family: "Helvetica"
                    font.pointSize: 12
                    font.bold: true
                    text:"View pressure"
                }
            }
        }

        //Separator
        Rectangle{
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 10
            radius:width*0.5
            border.width:4
            border.color: "white"
            color:"white"
        }

        Column {
            id:hiddenMenuView
            spacing:0
            RowLayout{
                Column {
                    Item {
                        id: button
                        width: 100
                        height: 100
                        signal clicked
                        enabled: windfield.paused
                        Image {
                            id: backgroundImage
                            anchors.fill: parent
                            source: (button.enabled ? "../assets/buttons/updateOn.png" : "../assets/buttons/updateOff.png")


                            //Mouse area to react on click events
                            MouseArea {
                                anchors.fill: backgroundImage
                                onClicked: { updateSimulation()
                                    backgroundImage.source = (button.enabled ? "../assets/buttons/updateOn.png" : "../assets/buttons/updateOff.png")
                                }

                            }
                        }
                    }
                }

                Column {
                    id:menu
                    spacing:0
                    Item {
                        id: buttonPause
                        width: 100
                        height: 100
                        Image {
                            id: playImage
                            anchors.fill: parent
                            source: (windfield.paused ? "../assets/buttons/playOn.svg" : "../assets/buttons/playOff.svg")
                        }

                        MouseArea {
                            anchors.fill: buttonPause
                            onClicked: {togglePaused()
                                // playImage.source = (windfield.paused ? "assets/buttons/playOn.png" : "assets/buttons/playOff.png")
                            }
                        }
                    }
                }
            }
        }

        //Lives
        Row{
            id: livesBox
            anchors.top: parent.top
            anchors.bottom: parent.bottom

            spacing: 10

            Repeater {
                model: numberOfLifes
                Item{
                    anchors.top: livesBox.top
                    anchors.bottom: livesBox.bottom
                    width: childrenRect.width
                    Image{
                        anchors.verticalCenter: parent.verticalCenter
                        height: 0.15*Screen.height
                        fillMode: Image.PreserveAspectFit
                        source: "../assets/lifeOn.png"
                    }
                }
            }

            Repeater {
                model: 3 - numberOfLifes
                Item{
                    anchors.top: livesBox.top
                    anchors.bottom: livesBox.bottom
                    width: childrenRect.width
                    Image{
                        anchors.verticalCenter: parent.verticalCenter
                        height: 0.15*Screen.height
                        fillMode: Image.PreserveAspectFit
                        source: "../assets/lifeOn.png"
                    }
                }
            }
        }

        //Separator
        Rectangle{
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 10
            radius:width*0.5
            border.width:4
            border.color: "white"
            color:"white"
        }

        //Timer
        Item{
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: childrenRect.width

            Rectangle{
                anchors.verticalCenter: parent.verticalCenter
                width: 0.15*Screen.width
                height: 0.1*Screen.height
                radius: 30
                border.width: 3
                border.color: "black"
                color: "transparent"

                Row{
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 15

                    Image{
                        height: timeText.height
                        fillMode: Image.PreserveAspectFit
                        source: "../assets/time.svg"
                    }

                    Text {
                        id: timeText

                        font.family: "Helvetica"
                        font.pointSize: 25
                        font.bold: true
                        text: parseInt(secondsElapsed/1000) + '\''+parseInt(secondsElapsed/100) +"\""
                    }
                }
            }
        }

        //Score
        Item{
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: childrenRect.width

            Rectangle{
                anchors.verticalCenter: parent.verticalCenter
                width: 0.07*Screen.width
                height: width
                radius: width*0.5
                border.width: 3
                border.color: "black"
                color:"#14b4f0"

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    font.family: "Helvetica"
                    font.pointSize: 25
                    font.bold: true
                    color:"white"
                    text: totalpoint
                }
            }
        }
    }
}
