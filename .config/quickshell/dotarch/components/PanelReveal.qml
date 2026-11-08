import QtQuick

Item {
    id: root
    property bool shown: false
    property real fromScale: 0.9
    default property alias content: holder.data

    transformOrigin: Item.Top
    opacity: 0
    scale: fromScale
    visible: opacity > 0

    states: State {
        name: "open"; when: root.shown
        PropertyChanges { target: root; opacity: 1; scale: 1 }
    }
    transitions: [
        Transition {
            to: "open"
            NumberAnimation { property: "scale"; duration: 270; easing.type: Easing.OutBack; easing.overshoot: 1.3 }
            NumberAnimation { property: "opacity"; duration: 140 }
        },
        Transition {
            from: "open"
            NumberAnimation { property: "scale"; duration: 220; easing.type: Easing.OutBack; easing.overshoot: 1.1 }
            NumberAnimation { property: "opacity"; duration: 170; easing.type: Easing.InQuad }
        }
    ]

    Item { id: holder; anchors.fill: parent }
}
