import QtQuick 2.0

Item {
    width: 2*parent.height/3
    height: 2*parent.height/3
    visible: true
    anchors.verticalCenter: parent.verticalCenter
    property bool activated: false
    property int ilevel: -3
    //property variant ppImg: ppImg
    Image {
        id: ppImg
        source:
            switch (ilevel){
            case -1:
                "assets/lowPressure2.png"
                break;
            case -2:
                "assets/lowPressure2.png"
                break;
            case -3:
                "assets/lowPressure2.png"
                break;
            case 1:
                "assets/highPressure2.png"
                break;
            case 2:
                "assets/highPressure2.png"
                break;
            case 3:
                "assets/lowPressure2.png"
                break;
            }

    }

}
