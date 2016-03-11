import QtQuick 2.5
import QtQuick.Controls 1.4
import QtQuick.Dialogs 1.2
import QtQuick.Window 2.2
import QtQuick.Controls.Styles 1.4

Item {
    property double rotation: sceneRotation.value
    property double maxRotation: sceneRotation.maximumValue

    function togglePaused() {
        windField.paused = !windField.paused
        if (windField.paused)
            pause.text = 'Resume'
        else
            pause.text = 'Pause'
        pathUpdate.enabled = windField.paused
    }

    function togglePathDraw() {
        windField.drawPrediction = true
    }

    function toggleDisplaySetting(setting) {
        switch(setting){
        case 1:
            windField.drawPressureGrid = pressureGridCheck.checked
            break;
        case 2:
            windField.drawForceGrid = forceGridCheck.checked
            break;
        case 3:
            windField.drawLeafVelocityVector = leafVelocityCheck.checked
            break;
        case 4:
            windField.drawLeafForceVectors = leafForceCheck.checked
            break;
        }
    }

    //UI
    Column {
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        Slider {
            id: sceneRotation
            orientation: Qt.Vertical
            height: 500
            minimumValue: 0
            maximumValue: 100
            value: 100
        }
    }

    Column {
        id: menuView
        x: 0
        y: 0
        width: parent.width
        state: "CLOSED"
        height: 350

        Rectangle {
            anchors.fill: parent
            border.width: 5
            border.color: "black"
            color: Qt.rgba(0.75,0.75,0.75,1.0)
        }

        states: [
            State {
                name: "OPENED"
                when: menuView.state=="OPENED"
                PropertyChanges { target: menuView; y: 0}
            },
            State {
                name: "CLOSED"
                when: menuView.state=="CLOSED"
                PropertyChanges { target: menuView; y: -(menuView.height-toggleMenu.height)}
            }
        ]

        transitions: [
            Transition {
                from: "OPENED"
                to: "CLOSED"
                SmoothedAnimation { target: menuView; properties:"y"; duration: 1000}
            },
            Transition {
                from: "CLOSED"
                to: "OPENED"
                SmoothedAnimation { target: menuView; properties:"y"; duration: 1000}
            }
        ]

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.topMargin: parent.top
            spacing: 5
            Column {
                Button {
                    id: pathUpdate
                    text: qsTr("Calculate path")
                    anchors.horizontalCenter: parent.horizontalCenter
                    onClicked: togglePathDraw()
                    enabled: windField.paused
                    style: ButtonStyle {
                        id: buttonStyle
                        background: Rectangle {
                            implicitWidth: 100
                            implicitHeight: 100
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
            }

            Column {
                id:menu
                spacing:0
                Button {
                    id: pause
                    text: qsTr("Pause")
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
                        pressurefield.initializeWindField()
                        windField.setInitialTestConfiguration()
                    }
                }
            }
            Column {
                CheckBox {
                    id: pressureGridCheck
                    checked: windField.drawPressureGrid
                    text: "Pressure Gradient"
                    onClicked: toggleDisplaySetting(1)
                }
                CheckBox {
                    id: forceGridCheck
                    checked: windField.drawForceGrid
                    text: "Force Vectors"
                    onClicked: toggleDisplaySetting(2)
                }
                CheckBox {
                    id: leafVelocityCheck
                    checked: windField.drawLeafVelocityVector
                    text: "Leaf Velocity"
                    onClicked: toggleDisplaySetting(3)
                }
                CheckBox {
                    id: leafForceCheck
                    checked: windField.drawLeafForceVectors
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
                    enabled: (sceneRotation.value == sceneRotation.maximumValue)
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
                        ListElement { text: "Add High Pressure"; color: "White" }
                        ListElement { text: "Add Low Pressure"; color: "White" }
                        ListElement { text: "Remove Pressure"; color: "White" }
                    }
                    onCurrentIndexChanged: {
                        windField.currentAction = currentIndex;
                    }
                }
            }
        }
        Button {
            id: toggleMenu
            text: qsTr("Open Menu")
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            style: pause.style
            width: parent.width
            height: 60
            onClicked: {
                if (menuView.state == "CLOSED") {
                    menuView.state = "OPENED"
                    toggleMenu.text = "Close Menu"
                } else {
                    menuView.state = "CLOSED"
                    toggleMenu.text = "Open Menu"
                }
            }
        }
    }
}
