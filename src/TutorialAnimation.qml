import QtQuick 2.0

Image {
    id: img

    property string baseName: ''
    property int currentIndex: 0
    property int numImages: 1
    property int durationMillis: 1000

   // onNumImagesChanged: anim.stop();

    source: '../assets/animations/' + baseName + '/' + currentIndex + '.png'

    fillMode: Image.PreserveAspectFit

    SequentialAnimation on currentIndex{
        id: anim
        loops: Animation.Infinite
        running: true

        PropertyAnimation{
            from: 0
            to: numImages - 1
            duration: durationMillis
            onToChanged: anim.restart()
        }
    }
}
