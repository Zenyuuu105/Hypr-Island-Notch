import QtQuick

Item {
    id: root
    property string label: ""
    property real from: 0
    property real to: 100
    property real value: 0
    property string unit: "px"
    property color accent: "#f2b8c0"
    signal moved(int v)

    implicitHeight: 52
    implicitWidth: 400
    readonly property real frac: to > from ? (Math.max(from, Math.min(to, value)) - from) / (to - from) : 0

    Text { text: root.label; color: "#e6e1e1"; font.pixelSize: 13; anchors.left: parent.left; anchors.top: parent.top }
    Text { text: Math.round(root.value) + (root.unit ? " " + root.unit : ""); color: "#a8a3a3"; font.pixelSize: 12; anchors.right: parent.right; anchors.top: parent.top }

    Rectangle {
        id: track
        anchors.left: parent.left
        anchors.right: parent.right
        y: 34
        height: 4
        radius: 2
        color: "#3a3636"
        Rectangle { width: parent.width * root.frac; height: parent.height; radius: 2; color: root.accent }
        Rectangle {
            width: 14; height: 14; radius: 7
            color: root.accent
            anchors.verticalCenter: parent.verticalCenter
            x: (track.width - width) * root.frac
        }
    }

    MouseArea {
        anchors.left: parent.left
        anchors.right: parent.right
        y: 22
        height: 28
        preventStealing: true
        function setFrom(mx) {
            const f = Math.max(0, Math.min(1, mx / width))
            root.moved(Math.round(root.from + f * (root.to - root.from)))
        }
        onPressed: mouse => setFrom(mouse.x)
        onPositionChanged: mouse => { if (pressed) setFrom(mouse.x) }
    }
}
