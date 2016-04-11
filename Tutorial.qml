import QtQuick 2.0

Image {
    property string baseName: ''
    property int currentScreen: 0
    property int numScreens: 1

    width: parent.width
    height: parent.height

    source: 'assets/backgrounds/tutorial/' + baseName + '-' + (currentScreen + 1) + '.png'

    signal finished()

    function reset(){
        currentScreen = 0;
    }

    function nextScreen(){
        currentScreen++;
        if(currentScreen >= numScreens){
            reset();
            finished();
        }
    }

    TutorialAnimation{
        baseName: 'ballon'
        numImages: 120
    }

    Image{
        id: nextButton
        width: parent.width/10
        height: width
        x: parent.width*3/4
        y: parent.height*3/4
        source: "assets/buttons/playOn.png"

        MouseArea {
            anchors.fill: parent
            onClicked: nextScreen()
        }
    }
}
