import QtQuick 2.5
import QtQuick.Window 2.1
import QtQuick.Layouts 1.1
import QtQuick.Controls 1.2
import QtQuick.Controls.Private 1.0
import QtQuick.Controls.Styles 1.3
import QtBluetooth 5.2
import Cellulo 1.0



Item {

    function em(x){ return Math.round(x*TextSingleton.font.pixelSize); }

    property bool mobile: Qt.platform.os === "android"
    property real gWidth: mobile ? Screen.width : 640
    property variant windfield: windField
    property variant robot: null
    property double startTime: 0
    property variant playground: playground
    property double secondsElapsed: 0
    property int numberOfLifes: windfield.nblifes
    property int bonus: 0

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

    function showInfo(){}

    Column {
        id: menuView
        x: 20
        y: 5
        width: parent.width - 40
        //state: "CLOSED"
        height: 310


        Rectangle {
            anchors.fill: parent
            //            border.width: 5
            //            border.color: "white"
            color: Qt.rgba(1,1,1,0.6)
            //opacity: 0.6
            radius:155
        }

        RowLayout {
            anchors.fill: parent
            //anchors.horizontalCenter: parent.horizontalCenter
            //anchors.topMargin: parent.top
            spacing: parent.height/10

            Column {
                Item {
                    width: 150
                    height: 150
                    Rectangle{
                        id: infobutton
                        width: 150
                        height: 150
                        radius:width*0.5
                        border.width:2
                        border.color: "black"
                        color:"transparent"
                        Text {
                            id: infoText
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.verticalCenter: parent.verticalCenter
                            font.family: "Helvetica"
                            font.pointSize: 40
                            font.bold: true
                            text: "?"
                        }
                        MouseArea {
                            anchors.fill: infobutton
                            onClicked:  showInfo()
                        }
                    }
                }
            }

            Column {
                Item {
                    id: pressurebutton
                    width: 150
                    height: width/2
                    Rectangle{
                        id: pressureSwitch
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 150
                        height: width/2
                        radius:width*0.5
                        border.width:5
                        border.color: "black"
                        color:"gray"
                        Rectangle{
                            id: pressureBall
                            width: parent.height -border.width
                            height: width
                            radius:width*0.5
                            border.width: 5
                            anchors.verticalCenter: parent.verticalCenter
                            border.color: "black"
                            color:"black"
                            state:( windfield.drawPressureGrid ? "anchorRight" : "anchorLeft")
                            states:[
                                State {
                                    name: "anchorRight"
                                    AnchorChanges {
                                        target: pressureBall
                                        anchors.right: parent.right
                                        anchors.left: undefined
                                    }
                                    PropertyChanges {
                                        target: pressureSwitch;
                                        color:"green"
                                    }
                                },
                                State {
                                    name: "anchorLeft"
                                    AnchorChanges {
                                        target: pressureBall
                                        anchors.left: parent.left
                                        anchors.right: undefined
                                    }
                                    PropertyChanges {
                                        target: pressureSwitch;
                                        color:"gray"
                                    }
                                }
                            ]
                        }
                        MouseArea {
                            anchors.fill: pressureSwitch
                            onClicked: {
                                windfield.drawPressureGrid = (windfield.drawPressureGrid ? false : true)
                                pressureBall.state = ( windfield.drawPressureGrid ? "anchorRight" : "anchorLeft")
                            }
                        }
                    }
                    Text{
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: pressureSwitch.bottom
                        font.family: "Helvetica"
                        font.pointSize: 12
                        font.bold: true
                        text:"Pressure gradient"
                    }
                }
            }


            Column {
                Rectangle{
                    width: 4
                    height: 150
                    radius:width*0.5
                    border.width:4
                    border.color: "white"
                    color:"white"
                }
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
                                source: (button.enabled ? "assets/buttons/updateOn.png" : "assets/buttons/updateOff.png")


                                //Mouse area to react on click events
                                MouseArea {
                                    anchors.fill: backgroundImage
                                    onClicked: { updateSimulation()
                                        backgroundImage.source = (button.enabled ? "assets/buttons/updateOn.png" : "assets/buttons/updateOff.png")
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
                                source: (windfield.paused ? "assets/buttons/playOn.png" : "assets/buttons/playOff.png")
                            }

                            MouseArea {
                                anchors.fill: buttonPause
                                onClicked: {togglePaused()
                                   // playImage.source = (windfield.paused ? "assets/buttons/playOn.png" : "assets/buttons/playOff.png")
                                }
                            }
                        }


                        Button {
                            id: reset
                            text: qsTr("Reset")
                            anchors.horizontalCenter: parent.horizontalCenter
                            onClicked: {
                                startTime=0;
                                pressurefield.resetWindField()
                                //windfield.setInitialTestConfiguration()
                                windfield.setInitialConfiguration()
                                windfield.setPressureFieldTextureDirty()
                                windfield.pauseSimulation()
                                if(robot.robotComm.connected)
                                robot.robotComm.reset();
                                timer.restart()
                            }
                        }
                    }

                    Column {
                        id:actionCol
                        Text {
                            text: " Action Menu: "
                        }
                        ComboBox {
                            id: actionMenu
                            currentIndex: 0

                            style: ComboBoxStyle {
                                background: Rectangle {
                                    implicitWidth: 300
                                    implicitHeight: 50
                                    border.width: control.activeFocus ? 2 : 1
                                    border.color: "#888"
                                    radius: 4
                                    gradient: Gradient {
                                        GradientStop { position: 0 ; color: control.pressed ? "#ccc" : "#eee" }
                                        GradientStop { position: 1 ; color: control.pressed ? "#aaa" : "#ccc" }
                                    }
                                }
                            }
                            model: ListModel {
                                id: cbItems
                                ListElement { text: "Move Pressure"; color: "White" }
                                ListElement { text: "Add Low Pressure (High)"; color: "White" }
                                ListElement { text: "Add Low Pressure (Medium)"; color: "White" }
                                ListElement { text: "Add Low Pressure (Low)"; color: "White" }
                                ListElement { text: "Add High Pressure (Low)"; color: "White" }
                                ListElement { text: "Add High Pressure (Medium)"; color: "White" }
                                ListElement { text: "Add High Pressure (High)"; color: "White" }
                                ListElement { text: "Remove Pressure"; color: "White" }
                            }
                            onCurrentIndexChanged: {
                                windfield.currentAction = currentIndex;
                                //windfield.currentAction = currentIndex;
                            }
                        }
                        Button {
                            id: removeAll
                            text: qsTr("Clear All Pressure")
                            anchors.horizontalCenter: parent.horizontalCenter
                            //style: pause.style
                            onClicked: {
                                pressurefield.resetWindField()
                            }
                        }
                    }



                    Column{
                        id: itemsCol
                        anchors.left:actionCol.right
                        GroupBox {
                            id: statusBox
                            title: "Status"
                            width: parent.height

                            Column{
                                spacing: 5

                                Row{
                                    spacing: 5

                                    Text{
                                        text: "Battery State: " + (robot.robotComm.connected? robot.robotComm.batteryState:"")
                                    }
                                }
                                Row{
                                    spacing: 5

                                    Text{
                                        text: "Kidnapped?"
                                        color: robot.robotComm.kidnapped ? "red" : "green"
                                    }
                                    Text{
                                        text: "X=" + parseInt(robot.robotComm.x) + "\n Y=" + parseInt(robot.robotComm.y) + " \nTheta=" + parseInt(robot.robotComm.theta)
                                    }
                                }
                            }
                        }

                    }
                }



            }

            Column{
                id:lifescol
                Row {
                    //anchors.horizontalCenter: parent.horizontalCenter
                    //anchors.left: parent.left
                    spacing: 5
                    Repeater {
                        model: numberOfLifes
                        Rectangle {
                            width: 50
                            height: 50
                            border.width: 1
                            color: "yellow"
                        }
                    }
                    Repeater {
                        model: (3 - numberOfLifes)
                        Rectangle {
                            width: 50
                            height: 50
                            border.width: 1
                            color: "black"
                        }
                    }
                }
            }




            Column {
                Rectangle{
                    width: 4
                    height: 150
                    radius:width*0.5
                    border.width:4
                    border.color: "white"
                    color:"white"
                }
            }
            Column{
                id:timerMenu
                anchors.right: bonusMenu.left
                Rectangle{
                    width: 270
                    height: 100
                    radius:30
                    border.width:3
                    border.color: "black"
                    color:"transparent"
                    Text {
                        id: timetext
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                        font.family: "Helvetica"
                        font.pointSize: 25
                        font.bold: true
                        text: parseInt(secondsElapsed/1000) + '\''+parseInt(secondsElapsed/100) +"\""
                    }
                }
               }
                Column{
                    id:bonusMenu
                    //anchors.right: parent.right
                    Rectangle{
                        width: 100
                        height: 100
                        radius:width*0.5
                        border.width:3
                        border.color: "black"
                        color:"yellow"

                    Text {
                        id: scoretext
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                        font.family: "Helvetica"
                        font.pointSize: 25
                        font.bold: true
                        text: bonus
                    }
                    }


            }

        }

    }
}
