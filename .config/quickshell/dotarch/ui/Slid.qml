import QtQuick
import "Singletons"

// A ratio. The row shows the number; this stays mute.
Item {
    id: slid
    property real value: 0
    property real from: 0
    property real to: 100
    signal modified(real v)

    readonly property real frac: to > from ? Math.max(0, Math.min(1, (value - from) / (to - from))) : 0
    implicitHeight: 24

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 4
        radius: 2
        color: Tokens.tint5
        border.width: Tokens.border
        border.color: hh.hovered ? Tokens.lineStrong : Tokens.line
    }
    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width * slid.frac
        height: 4
        radius: 2
        color: Tokens.ink
    }
    Rectangle {
        x: Math.min(parent.width - 6, Math.max(0, parent.width * slid.frac - 5.5))
        anchors.verticalCenter: parent.verticalCenter
        width: 11
        height: 11
        radius: 4
        color: Tokens.ink
        border.width: 2
        border.color: Tokens.paperLift
    }
    HoverHandler { id: hh; cursorShape: Qt.PointingHandCursor }
    TapHandler { onTapped: (p) => slid.seat(p.position.x) }
    DragHandler {
        target: null
        onCentroidChanged: if (active) slid.seat(centroid.position.x)
    }
    function seat(x) {
        var f = Math.max(0, Math.min(1, x / width));
        modified(Math.round((from + f * (to - from)) * 100) / 100);
    }
}
