import QtQuick 2.0
import QtQuick.Window 2.0

Rectangle {

    anchors.horizontalCenter: parent.horizontalCenter
    anchors.verticalCenter: parent.verticalCenter
    width: parent.width/2
    height: parent.height/2
    color: Qt.rgba(1,1,1,0.6)
    radius: 110
    visible: false

    property real bonus: -1

    signal resetClicked()

    function showCollided(){
        gameEndDialogStateEngine.goToStateByName("CollidedWithWall");
    }

    function showWon(){
        gameEndDialogStateEngine.goToStateByName("Won");
    }

    StateEngine{
        id: gameEndDialogStateEngine

        states: ['Hidden', 'CollidedWithWall', 'Won']

        onCurrentStateChanged: {
            console.log("Game end dialog state changed: " + currentState);
            switch(currentState){
            case 'Hidden':
                parent.visible = false;
                break;
            case 'CollidedWithWall':
                parent.visible = true;
                theText.text = "Ouch, you collided with a wall. Play again?";
                break;
            case 'Won':
                parent.visible = true;
                theText.text = "You won with a score of " + bonus + "! Play again?";
                break;
            }
        }
    }

    Text {
        id: theText

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: button.top
        anchors.bottomMargin: 30
        font.family: "Helvetica"
        font.pointSize: 20
        font.bold: true
    }

    Image {
        id: button

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter

        width: Screen.width*0.10
        fillMode: Image.PreserveAspectFit

        source: "../assets/buttons/reset.svg"

        MouseArea {
            anchors.fill: parent
            onClicked: {
                gameEndDialogStateEngine.goToStateByName('Hidden');
                resetClicked();
            }
        }
    }
}
