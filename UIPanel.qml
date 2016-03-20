import QtQuick 2.5
import QtQuick.Controls 1.4
import QtQuick.Dialogs 1.2
import QtQuick.Window 2.2
import QtQuick.Controls.Styles 1.4

Item {
    function togglePaused() {
        windField.paused = !windField.paused
        if (windField.paused)
            pause.text = 'Resume'
        else
            pause.text = 'Pause'
        pressureUpdate.enabled = windField.paused
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

    function updateSimulation() {
        pressurefield.updateField()
        for (var i = 0; i < windField.numLeaves; i++)
            windField.leaves[i].calculateForcesAtLeaf()
    }

    Column {
        id: menuView
        x: 2560*.25
        y: 0
        width: parent.width/2
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
                    id: pressureUpdate
                    text: qsTr("Update Pressure")
                    anchors.horizontalCenter: parent.horizontalCenter
                    onClicked: updateSimulation()
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
                        pressurefield.resetWindField()
                        windField.setInitialTestConfiguration()
                        windField.setPressureFieldTextureDirty()
                        windField.pauseSimulation()
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
        }
        Button {
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
        }
    }
}
