import QtQuick 2.0

Item {
    id:root
    //width: 2*parent.height/3
    //height: 2*parent.height/3
    width: 2*rowPressure.height/3
    height: 2*rowPressure.height/3
    visible: true
    opacity:1
    anchors.verticalCenter: parent.verticalCenter
    property bool activated: false
    property bool reset: false
    property int ilevel: -3
    property variant windfield: windField
    property variant ppointpanel:rowPressure
    readonly property double xGridSpacing: 12
    readonly property double yGridSpacing: 12
    property variant field: null
    property int xOffst: parent.x
    property int yOffst: windfield.fieldHeight


    ListModel{
        id: lowpressureModel
        ListElement{
            imagePath:"assets/lowPressure3.png"
            name:"lll"
            plevel:-3
        }
        ListElement{
            imagePath:"assets/lowPressure2.png"
            name:"ll"
            plevel:-2
        }
        ListElement{
            imagePath:"assets/lowPressure1.png"
            name:"l"
            plevel:-1
        }
    }

    ListModel{
        id: highpressureModel
        ListElement{
            imagePath:"assets/highPressure3.png"
            name:"hhh"
            plevel:3
        }
        ListElement{
            imagePath:"assets/highPressure2.png"
            name:"hh"
            plevel:2
        }
        ListElement{
            imagePath:"assets/highPressure1.png"
            name:"h"
            plevel:1
        }
    }

    PressurePointLevelDialog{
        id: newpDialog
        dialogModel:ilevel <0 ?lowpressureModel :highpressureModel
        opacity: 0
        onClicked: {
            // add pressure point of the level at the position
            var p = mapFromItem(root, root.x, root.y )
            console.log('adding p poin')
            var row = Math.floor((yOffst-p.y)/yGridSpacing)
            var col = Math.floor((p.x+xOffst)/xGridSpacing)
            console.info(row,col, p.x, p.y, root.x, root.y, x,y)
            //field.addPressurePoint(row,col,ilevel)

            // Dismiss new game dialog
            newpDialog.hideDialog= true;

            //Set the new level
            ilevel = plevel

            //activate the pressure point (as it is on the field
            activated = true
        }
    }


    Image {
        id: ppImg
        opacity:1
        source:
            switch (ilevel){
            case -1:
                "assets/lowPressure1.png"
                break;
            case -2:
                "assets/lowPressure2.png"
                break;
            case -3:
                "assets/lowPressure3.png"
                break;
            case 1:
                "assets/highPressure1.png"
                break;
            case 2:
                "assets/highPressure2.png"
                break;
            case 3:
                "assets/highPressure3.png"
                break;
            }

        Drag.active: mouseArea.drag.active
        Drag.hotSpot.x: width/2
        Drag.hotSpot.y: height/2

        MouseArea{
            id:mouseArea
            width: parent.width
            height: parent.height
            drag.target:ppImg
            //propagateComposedEvents: true
            onReleased:{
                //if(root.state == "exited"){
                newpDialog.x = ppImg.x
                newpDialog.y = ppImg.y - ppImg.height
                newpDialog.showDialog =true
                //}
            }
            onClicked:{
                //if(root.state == "exited"){
                newpDialog.x = ppImg.x
                newpDialog.y = ppImg.y - ppImg.height
                newpDialog.showDialog =true
                //}
            }
            /*onExited:{
                console.log("exit p point")
                root.state = "exited"
                console.log(root.parent)
                console.log(root.x, root.y)
            }
            onEntered:{
                console.log("entered p point")
                root.state = "backin"
                console.log(root.parent)
                console.log(root.x, root.y)
            }*/
        }

        states:
        State {
            name:"exited"
            ParentChange{target:root; parent:windfield}
         }
        State {
           name:"backin"
           ParentChange{target:root; parent:parent}
        }

        }
}
