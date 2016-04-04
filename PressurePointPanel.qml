import QtQuick 2.0

Item {
    id: pressurePanel
    //property string colorKey
    property variant windfield: null
    x: 20
    y: parent.height -320
    property variant ppoint1: pressurePoint2

    Column {
        id: stockView
        width: parent.width - 40
        height: 310


        Rectangle {
            id:rect
            width:parent.width
            height: parent.height
            color: Qt.rgba(1,1,1,0.6)
            radius:155
            Row {
                id:rowPressure
                width:parent.width
                height: parent.height
                spacing: 50
                Image {
                    id: pressurePoint1
                    anchors.verticalCenter: parent.verticalCenter
                    width: 2*parent.height/3
                    height: 2*parent.height/3
            //        anchors.fill: parent
                    source:  "assets/highPressure2.png"

                }



                Image {
                    id: pressurePoint2
                    property int intensity: -3
                    anchors.verticalCenter:  parent.verticalCenter
                    width: 2*parent.height/3
                    height: 2*parent.height/3
                    source:  "assets/lowPressure2.png"
                    DropArea{
                        anchors.fill: parent
                    onEntered:{
                            pressurePoint2.source ="assets/lowPressure3.png"
                        }
                    onExited: {
                        pressurePoint2.source ="assets/lowPressure4.png"
                    }
                    onDropped: {
                        pressurePoint2.source ="assets/lowPressure2.png"
                        //if (drop.hasText) {
                         //   if (drop.proposedAction == Qt.MoveAction || drop.proposedAction == Qt.CopyAction) {
                          //      pressurePoint2.source ="assets/lowPressure5.png"
                                //item.display = drop.text
                            //    drop.acceptProposedAction()
                            }
                        }



                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        drag.target: draggable

                    Item {
                        id: draggable
                        anchors.fill: parent
                        Drag.active: true
                        Drag.hotSpot.x: 0
                        Drag.hotSpot.y: 0
                        Drag.mimeData: { pressurePoint2.source ="assets/lowPressure2.png" }
                        Drag.dragType: Drag.Automatic
                        //Drag.onDragStarted: {
                        //}
                        Drag.onDragFinished: {
                            //if (dropAction == Qt.MoveAction) {
                                pressurePoint2.source ="assets/lowPressure4.png"
                            //}
                        }
                    } // Item
}
                   /* MouseArea {
                                anchors.fill: parent
                                drag.target: pressurePoint2
                                drag.axis: Drag.XAndYAxis
                                drag.minimumX: 0
                                drag.maximumX: windfield.width
                                drag.minimumY: -500
                                drag.maximumY:  windfield.height
                            }*/

                }

        }
        }


    }




    /*MouseArea {
        id: mouseArea

        width: 64; height: 64
        anchors.centerIn: parent

        drag.target: pressureP

        onReleased: parent = pressureP.Drag.target !== null ? pressureP.Drag.target : root

        Rectangle {
            id: pressureP

            width: 64; height: 64
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter

            color: colorKey

            Drag.keys: [ colorKey ]
            Drag.active: mouseArea.drag.active
            Drag.hotSpot.x: 32
            Drag.hotSpot.y: 32
            states: State {
                when: mouseArea.drag.active
                ParentChange { target: pressureP; parent: root }
                AnchorChanges { target: pressureP; anchors.verticalCenter: undefined; anchors.horizontalCenter: undefined }
            }

        }
    }*/
}
