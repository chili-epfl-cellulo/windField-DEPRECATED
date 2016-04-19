import QtQuick 2.0

Image {
    property string baseName: ''
    property int currentScreen: 0
    property int numScreens: 1

    property variant animBaseNames: []
    property variant animNumImages: []
    property variant animDurations: []
    property variant animSizeCoeffs: []
    property variant animBottomMarginCoeffs: []

    width: parent.width
    height: parent.height

    source: '../assets/backgrounds/tutorial/' + baseName + '-' + (currentScreen + 1) + '.png'

    signal finished()
    signal wentBack()

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

    function prevScreen(){
        if(currentScreen > 0)
            currentScreen--;
        else
            wentBack();
    }

    TutorialAnimation{
        baseName: animBaseNames[currentScreen]
        numImages: animNumImages[currentScreen]
        durationMillis: animDurations[currentScreen]

        width: parent.width*animSizeCoeffs[currentScreen]

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: parent.height*animBottomMarginCoeffs[currentScreen]
    }

    Image{
        id: nextButton
        width: parent.width/12
        fillMode: Image.PreserveAspectFit
        x: parent.width*0.78
        y: parent.height*0.68
        source: "../assets/buttons/next.svg"

        MouseArea {
            anchors.fill: parent
            onClicked: nextScreen()
        }
    }

    Image{
        id: prevButton
        width: parent.width/12
        fillMode: Image.PreserveAspectFit
        x: (parent.width - nextButton.x) - width
        y: parent.height*0.68
        rotation: 180
        source: "../assets/buttons/next.svg"

        MouseArea {
            anchors.fill: parent
            onClicked: prevScreen()
        }
    }
}
