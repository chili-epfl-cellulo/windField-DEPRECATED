import QtQuick 2.0

Image {
    property string baseName: ''
    property int currentIndex: 0
    property int numImages: 1
    property int duration: 1000

    source: '../assets/animations/' + baseName + '/' + currentIndex + '.png'

    SequentialAnimation on currentIndex{
        loops: Animation.Infinite
        running:  true

        PropertyAnimation{
            to: 0
            duration: 1000
        }
        PropertyAnimation{
            to: numImages - 1
            duration: 1000
        }
    }
}
