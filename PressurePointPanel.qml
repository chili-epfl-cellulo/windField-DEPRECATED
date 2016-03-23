import QtQuick 2.0

Item {
    id: pressurePanel
    property string colorKey

    width: 64; height: 64

    MouseArea {
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
    }
}
