import QtQuick 2.0

Image {
    property string baseName: ''
    property int currentIndex: 0
    property int numImages: 1

    source: 'assets/animations/' + baseName + '/' + currentIndex + '.png'

    SequentialAnimation on currentIndex{
        loops: Animation.Infinite
        running:  true

        PropertyAnimation{
            to: numImages - 1
        }
        PropertyAnimation{
            to: 0
        }
    }
}
