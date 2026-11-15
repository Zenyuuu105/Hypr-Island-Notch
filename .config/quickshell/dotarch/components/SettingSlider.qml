import QtQuick
import qs
import "../ui/Singletons"

Item {
    id: root

    property string label: ""
    property real from: 0
    property real to: 100
    property real value: 0
    property string unit: "px"
    property color accent: Tokens.ink

    signal moved(int v)

    implicitWidth: 300
    implicitHeight: 48

    readonly property real clampedValue: Math.max(from, Math.min(to, value))
    readonly property real frac: to > from
        ? (clampedValue - from) / (to - from) : 0

    Text {
        id: nameLabel
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.right: valueLabel.left
        anchors.rightMargin: 10
        text: root.label
        color: Tokens.ink
        font.family: Tokens.ui
        font.pixelSize: 11
        font.weight: Font.Medium
        elide: Text.ElideRight
    }

    Text {
        id: valueLabel
        anchors.right: parent.right
        anchors.top: parent.top
        text: Math.round(root.value) + (root.unit ? " " + root.unit : "")
        color: Tokens.inkMuted
        font.family: Tokens.ui
        font.pixelSize: 10
        font.weight: Font.DemiBold
    }

    Rectangle {
        id: track
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: nameLabel.bottom
        anchors.topMargin: 13
        height: 3
        radius: 2
        color: Tokens.tint10

        Rectangle {
            width: track.width * root.frac
            height: parent.height
            radius: 2
            color: Tokens.ink
            Behavior on width {
                NumberAnimation { duration: Tokens.flap; easing.type: Easing.OutCubic }
            }
        }

        Rectangle {
            width: 11
            height: 11
            radius: 4
            x: Math.max(0, Math.min(track.width - width,
                                    (track.width - width) * root.frac))
            anchors.verticalCenter: parent.verticalCenter
            color: Tokens.ink
            border.width: 2
            border.color: Tokens.paperLift
            Behavior on x {
                NumberAnimation { duration: Tokens.flap; easing.type: Easing.OutCubic }
            }
        }
    }

    MouseArea {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: track.top
        anchors.bottom: track.bottom
        anchors.topMargin: -12
        anchors.bottomMargin: -12
        preventStealing: true
        cursorShape: Qt.PointingHandCursor

        function setFrom(mx) {
            if (width <= 0 || root.to <= root.from)
                return
            const fraction = Math.max(0, Math.min(1, mx / width))
            root.moved(Math.round(root.from + fraction * (root.to - root.from)))
        }

        onPressed: mouse => setFrom(mouse.x)
        onPositionChanged: mouse => {
            if (pressed)
                setFrom(mouse.x)
        }
    }
}
