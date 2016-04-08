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
    property double secondsElapsed: 0
    property int numberOfLifes: windfield.nblifes
    function togglePaused() {
        windfield.paused = !windfield.paused
        if (windfield.paused){
            //timer.stop()
            pause.text = 'Resume'
        }
        else{
            timer.restart()
            pause.text = 'Pause'
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
    function timeChanged(){
        if(!windfield.paused){
            if(startTime == 0)
                startTime =  new Date().getTime()
            var currentTime = new Date().getTime()
            secondsElapsed = (currentTime-startTime)
        }
    }
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
            spacing: 5

            Column {
                //anchors.left: lifescol.right
                //Implementation of the Button control.
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

                        }}
                }


            }

            Column {
                id:menu
                spacing:0
                //Implementation of the Button control.
                Item {
                    id: buttonPause
                    width: 100
                    height: 100
                    signal clicked
                    enabled: windfield.paused

                    Image {
                        id: playImage
                        anchors.fill: parent
                        source: (buttonPause.enabled ? "assets/buttons/playOn.png" : "assets/buttons/playOff.png")
                    }

                    Text {
                        id: playinnerText
                        anchors.centerIn: parent
                        color: "white"
                        font.bold: true
                    }

                    //Mouse area to react on click events
                    MouseArea {
                        anchors.fill: buttonPause
                        onClicked: {togglePaused()
                            playImage.source = (buttonPause.enabled ? "assets/buttons/playOn.png" : "assets/buttons/playOff.png")
                        }
                        onPressed: {
                            playImage.source = "assets/buttons/playOn.png"}
                    }
                }


                Button {
                    id: pause
                    text: qsTr("Start")
                    anchors.horizontalCenter: parent.horizontalCenter
                    onClicked: togglePaused()
                    style:     ButtonStyle {
                        id: buttonStyle
                        background: Rectangle {
                            implicitWidth: 100
                            implicitHeight: 25
                            border.width: control.activeFocus ? 2 : 1
                            border.color: "#888"
                            radius: 4
                            gradient: Gradient {
                                GradientStop { position: 0 ; color: control.pressed ? "#ccc" : "#eee" }
                                GradientStop { position: 1 ; color: control.pressed ? "#aaa" : "#ccc" }
                            }
                        }
                    }
                }
                Button {
                    id: reset
                    text: qsTr("Reset")
                    anchors.horizontalCenter: parent.horizontalCenter
                    style: pause.style
                    onClicked: {
                        startTime=0;
                        pressurefield.resetWindField()
                        //windfield.setInitialTestConfiguration()
                        windfield.setInitialConfiguration()
                        windfield.setPressureFieldTextureDirty()
                        windfield.pauseSimulation()
                    }
                }
            }

            Column {
                CheckBox {
                    id: pressureGridCheck
                    checked: windfield.drawPressureGrid
                    text: "Pressure Gradient"
                    onClicked: toggleDisplaySetting(1)
                }
                CheckBox {
                    id: forceGridCheck
                    checked: windfield.drawForceGrid
                    text: "Force Vectors"
                    onClicked: toggleDisplaySetting(2)
                }
                CheckBox {
                    id: leafVelocityCheck
                    checked: windfield.drawLeafVelocityVector
                    text: "Leaf Velocity"
                    onClicked: toggleDisplaySetting(3)
                }
                CheckBox {
                    id: leafForceCheck
                    checked: windfield.drawLeafForceVectors
                    text: "Forces on Leaf"
                    onClicked: toggleDisplaySetting(4)
                }
            }

            Column {
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
                    anchors.horizontalCenter: parent.right
                    style: pause.style
                    onClicked: {
                        pressurefield.resetWindField()
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

            Column{
                id: itemsCol

                GroupBox {
                    id: addressBox
                    title: "Robot Address"
                    width: gWidth/4

                    Row{
                        spacing: 5

                        Label{
                            text: "00:06:66:74:"
                            anchors.verticalCenter: macAddrRight.verticalCenter
                        }
                        TextField{
                            id: macAddrRight
                            text: "40:DC"
                            placeholderText: "XX:XX"
                            width: em(5)
                        }
                        Button {
                            text: "Connect"
                            onClicked: robotComm.macAddr =  "00:06:66:74:" + macAddrRight.text;
                        }
                    }
                }

                GroupBox {
                    id: statusBox
                    title: "Status"
                    width: gWidth/4

                    Column{
                        spacing: 5

                        Row{
                            spacing: 5

                            Text{
                                text: "Connected?"
                                color: robot.connected ? "green" : "red"
                            }
                            Text{
                                text: "Battery State: " + robot.batteryState
                            }
                            Text{
                                id: k0
                                text: "K0"
                                color: "black"
                            }
                            Text{
                                id: k1
                                text: "K1"
                                color: "black"
                            }
                            Text{
                                id: k2
                                text: "K2"
                                color: "black"
                            }
                            Text{
                                id: k3
                                text: "K3"
                                color: "black"
                            }
                            Text{
                                id: k4
                                text: "K4"
                                color: "black"
                            }
                            Text{
                                id: k5
                                text: "K5"
                                color: "black"
                            }
                        }
                        Row{
                            spacing: 5

                            Text{
                                text: "Kidnapped?"
                                color: robot.kidnapped ? "red" : "green"
                            }
                            Text{
                                text: "X=" + robot.x.toFixed(2) + " Y=" + robot.y.toFixed(2) + " Theta=" + robot.theta.toFixed(1)
                            }
                        }
                    }
                }

            }

            Timer {
                id:timer
                interval:30
                running: false; repeat: true
                onTriggered: timeChanged()
            }

            Column{
                id:timerMenu
                anchors.right: parent.right
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
                        text: parseInt(secondsElapsed/100) + '\''+parseInt(secondsElapsed/1000)
                    }
                }
            }

        }
        /*Button {
            id: toggleMenu
            text: qsTr("Open Menu")
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            style: pause.style
            width: parent.width

            height: 100
            onClicked: {
                if (menuView.state == "CLOSED") {
                    menuView.state = "OPENED"
                    toggleMenu.text = "Close Menu"
                } else {
                    menuView.state = "CLOSED"
                    toggleMenu.text = "Open Menu"
                }
            }
        }*/
    }
}
