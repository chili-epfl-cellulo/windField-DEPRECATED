import QtQuick 2.0
import QtQuick.Window 2.0

Item {
    id: root
    objectName: "PressurePoint"

    property real imageWidth: imageHeight
    property real imageHeight: Screen.height/6

    property real xOffset: Screen.width/1800*50 + 20
    property real yOffset: Screen.width/1800*50 + Screen.height*(1 - (760/(1800/Screen.width*Screen.height)))/2

    property int ilevel: -3

    property real initialImgX: 0
    property real initialImgY: 0

    property int row: -1
    property int col: -1

    signal putInGame(int r, int c, int level)
    signal updated(int prevr, int prevc, int r, int c, int level)
    signal removedFromGame(int prevr, int prevc)


    state:"inPlay"
    function removeForcefully(){
        choosePointLevelDialog.hideDialog();
        putImageBack();
        if(row >= 0 && col >= 0){
            removedFromGame(row, col);
            pressurefield.removePressurePoint(row, col);
        }
        row = -1;
        col = -1;
    }

    function putImageBack(){
        img.x = initialImgX;
        img.y = initialImgY;
    }

    function updateProperties(plevel){

        //Add pressure point of the level at the position
        var p = img.mapToItem(null, 0, 0);
        var prevRow = row;
        var prevCol = col;
        row = Math.floor((p.y + imageHeight/2 - yOffset)/Screen.height*1600/pressurefield.yGridSpacing);
        col = Math.floor((p.x + imageWidth/2 - xOffset)/Screen.width*2560/pressurefield.xGridSpacing);

        console.log((p.x + imageWidth/2 - xOffset)/Screen.width*2560/pressurefield.xGridSpacing);

        //Set the new level
        if(plevel !== 0)
            ilevel = plevel;

        //Moved outside game area
        if(row < 0 || col < 0 || col >= pressurefield.numCols || row >= pressurefield.numRows){
            choosePointLevelDialog.hideDialog();
            putImageBack();
            if(prevRow >= 0 && prevCol >= 0){
                removedFromGame(prevRow, prevCol);
                pressurefield.removePressurePoint(prevRow,prevCol);
            }
            row = -1;
            col = -1;
        }

        //Moved inside game area
        else{
            choosePointLevelDialog.showDialog(img.x, img.y - img.height);
            if(prevRow < 0 || prevCol < 0){
                putInGame(row, col, ilevel);
                pressurefield.addPressurePoint(row,col,ilevel);
            }
            else{
                updated(prevRow, prevCol, row, col, ilevel);
                pressurefield.addOrUpdatePressurePoint(prevRow,prevCol,row,col,ilevel);
            }
        }
    }

    ListModel{
        id: lowpressureModel

        ListElement{
            imagePath: "../assets/lowPressure3.png"
            name: "lll"
            plevel: -3
        }
        ListElement{
            imagePath: "../assets/lowPressure2.png"
            name: "ll"
            plevel: -2
        }
        ListElement{
            imagePath: "../assets/lowPressure1.png"
            name: "l"
            plevel: -1
        }
        ListElement{
            imagePath: "../assets/buttons/cancelPDialog.svg"
            name: "cancel"
            plevel: 0
        }
    }

    ListModel{
        id: highpressureModel

        ListElement{
            imagePath: "../assets/highPressure3.png"
            name: "hhh"
            plevel: 3
        }
        ListElement{
            imagePath: "../assets/highPressure2.png"
            name: "hh"
            plevel: 2
        }
        ListElement{
            imagePath: "../assets/highPressure1.png"
            name: "h"
            plevel: 1
        }
        ListElement{
            imagePath: "../assets/buttons/cancelPDialog.svg"
            name: "cancel"
            plevel: 0
        }
    }

    PressurePointLevelDialog{
        id: choosePointLevelDialog
        dialogModel: ilevel < 0 ? lowpressureModel : highpressureModel
        onClicked: {
            updateProperties(plevel);
            hideDialog();
        }
        onDialogShown: root.z = 100
        onDialogHidden: root.z = 0
    }

    Image {
        id: img

        opacity: 1
        source:
            switch (ilevel){
            case -1:
                "../assets/lowPressure1.png"
                break;
            case -2:
                "../assets/lowPressure2.png"
                break;
            case -3:
                "../assets/lowPressure3.png"
                break;
            case 1:
                "../assets/highPressure1.png"
                break;
            case 2:
                "../assets/highPressure2.png"
                break;
            case 3:
                "../assets/highPressure3.png"
                break;
            }
        height: imageHeight
        fillMode: Image.PreserveAspectFit

        Drag.active: mouseArea.drag.active
        Drag.hotSpot.x: width/2
        Drag.hotSpot.y: height/2

        MouseArea{
            id: mouseArea
            anchors.fill: parent
            drag.target: img
            onReleased: updateProperties(0)
            enabled: true

            Image {
                id: checkImage
                visible:false
                opacity: 1
                source:"../assets/buttons/right.png"
                 /**   switch (root.state){
                    case "correct":
                        "../assets/buttons/right.png"
                        break;
                    case "incorrect":
                        "../assets/buttons/wrong.png"
                        break;
                    }**/
                height: imageHeight
                fillMode: Image.PreserveAspectFit

            }
        }
    }
    states:[
        State{
            name: "correct"
            PropertyChanges {target: checkImage; source:"../assets/buttons/right.png"}
            PropertyChanges {target: checkImage; visible:true}
            PropertyChanges {target: mouseArea; enabled:false}
        },
        State{
            name: "incorrect"
            PropertyChanges {target: checkImage; source:"../assets/buttons/wrong.png"}
            PropertyChanges {target: checkImage; visible:true}
        },
        State{
            name: "inPlay"
            PropertyChanges {target: checkImage; visible:false}
        }
    ]
}
