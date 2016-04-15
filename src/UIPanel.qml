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
    property variant robot: cellulo1
    property double startTime: 0
    property variant playground: playground
    property double secondsElapsed: windfield.secondsElapsed
    property int numberOfLifes: windfield.nblifes
    property int totalpoint: 0
    property int gameMode: windfield.gameMode





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
            visible:uicontrols.state==="bravo"
            Image{
                id: infoButtonImg
                anchors.verticalCenter: parent.verticalCenter
                height: 0.15*Screen.height
                fillMode: Image.PreserveAspectFit
                source: "../assets/buttons/reset.svg"

                MouseArea {
                    anchors.fill: parent
                    onClicked: {windfield.setInitialConfigurationGame1()

                    }
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
                            //if(pressureButton.switchOn)
                            //    updateSimulation();
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

        //Play button
        Item{
            enabled: gameMode === 2
            visible: enabled

            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: childrenRect.width

            Image{
                anchors.verticalCenter: parent.verticalCenter
                height: 0.15*Screen.height
                fillMode: Image.PreserveAspectFit
                source: "../assets/buttons/" + (windfield.paused ? "playOn.svg" : "playOff.svg")

                MouseArea {
                    anchors.fill: parent
                    onClicked:{
                        updateSimulation();
                        togglePaused();
                    }
                }
            }
        }

        //Check button
        Item{
            enabled: gameMode === 1
            visible: enabled

            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: childrenRect.width
            Rectangle{
                id:checkinbutton
                anchors.verticalCenter: parent.verticalCenter
                width: 0.2*Screen.width
                height: 0.07*Screen.width
                radius: width*0.25
                border.width: 3
                border.color: "black"
                color:"yellow"

                Text {
                    id:buttontext
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    font.family: "Helvetica"
                    font.pointSize: 25
                    font.bold: true
                    color:"white"
                    text: "Check ?"
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked:
                        if(uicontrols.state == 'check'){
                            console.log('chekc pressed')
                            windfield.checkPPoint()
                        }
                        else if(uicontrols.state == 'tryagain'){
                            console.log('////////////////tryagain....')
                            windfield.resetNotfoundPoint()
                            windfield.hidePressurePoint()
                            //

                        }
                    onPressed: {
                        buttontext.color="gray"
                        checkinbutton.opacity =0.5
                    }
                    onReleased: {
                        buttontext.color="white"
                        checkinbutton.opacity =1
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
        /*Item{
            enabled: gameMode === 2
            visible: enabled

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
        }*/

        //Score in game 1
        Item{
            enabled: gameMode === 1
            visible: enabled

            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: childrenRect.width

            Rectangle{
                anchors.verticalCenter: parent.verticalCenter
                width: 0.2*Screen.width
                height: 0.07*Screen.width
                radius: width*0.25
                border.width: 3
                border.color: "black"
                color:"#aaff794d"

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    font.family: "Helvetica"
                    font.pointSize: 25
                    font.bold: true
                    color:"white"
                    text: (totalpoint > 0 ? -totalpoint : "-") + " km"
                }
            }
        }

        //Score in game 2
        Item{
            enabled: gameMode === 2
            visible: enabled

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
                color:"#aa14b4f0"

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
    states:[
        State{
            name:"check"
            PropertyChanges{target:checkinbutton;color:"yellow"}
            PropertyChanges{target:buttontext;text:"Check ?"}
        },
        State{
            name:"tryagain"
            PropertyChanges{target:checkinbutton;color:"red"}
            PropertyChanges{target:buttontext;text:"Try again?"}

        },
        State{
            name:"bravo"
            PropertyChanges{target:checkinbutton;color:"blue"}
            PropertyChanges{target:buttontext;text:"Bravo !"}

        }
    ]
}
