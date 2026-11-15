import QtQuick
import qs
import "../ui/Singletons"

// A ratio. The row shows the number; the slider itself stays mute. Hairline track,
// solid fill, a flat thumb. `accent` still exists so pages that set it keep working;
// by default the slider is mono, as in Ryoku.
Item {
    id: slid

    property real from: 0
    property real to: 100
    property real value: 0
    property color accent: Tokens.ink
    signal modified(real v)

    readonly property color ink: Tokens.ink
    readonly property color line: Qt.rgba(ink.r, ink.g, ink.b, 0.26)
    readonly property color lineStrong: Qt.rgba(ink.r, ink.g, ink.b, 0.42)

    readonly property real frac: to > from ? Math.max(0, Math.min(1, (value - from) / (to - from))) : 0
    implicitHeight: 24
    implicitWidth: 200

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 4
        color: "transparent"
        border.width: 1
        border.color: hh.hovered ? slid.lineStrong : slid.line
        antialiasing: false
    }
    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width * slid.frac
        height: 4
        color: slid.accent
        Behavior on width { enabled: !dh.active; NumberAnimation { duration: Tokens.flap; easing.type: Tokens.ease } }
        antialiasing: false
    }
    Rectangle {
        x: Math.min(parent.width - 6, Math.max(0, parent.width * slid.frac - 3))
        Behavior on x { enabled: !dh.active; NumberAnimation { duration: Tokens.flap; easing.type: Tokens.ease } }
        anchors.verticalCenter: parent.verticalCenter
        width: 6
        height: 17
        color: slid.accent
        antialiasing: false
    }

    HoverHandler { id: hh; cursorShape: Qt.PointingHandCursor }
    TapHandler { onTapped: (p) => slid.seat(p.position.x) }
    DragHandler {
        id: dh
        target: null
        onCentroidChanged: if (active) slid.seat(centroid.position.x)
    }

    function seat(x) {
        var f = Math.max(0, Math.min(1, x / width));
        modified(Math.round((from + f * (to - from)) * 100) / 100);
    }
}
