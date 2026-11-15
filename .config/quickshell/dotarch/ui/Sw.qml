import QtQuick
import "Singletons"

// A boolean. Two named modes are a Seg, not a switch.
Rectangle {
    id: sw
    property bool on: false
    signal toggled(bool v)

    implicitWidth: 54
    implicitHeight: 24
    radius: Tokens.radius
    color: tap.pressed ? Tokens.tint16 : (sw.on ? Tokens.tint16 : Tokens.tint5)
    border.width: Tokens.border
    border.color: hh.hovered ? Tokens.lineStrong : Tokens.line
    Behavior on border.color { ColorAnimation { duration: Tokens.snap } }
    Behavior on color { ColorAnimation { duration: Tokens.snap } }

    Rectangle {
        width: 16
        height: 16
        y: 4
        x: sw.on ? parent.width - width - 4 : 4
        radius: 4
        color: sw.on ? Tokens.ink : Tokens.inkDim
        Behavior on x { NumberAnimation { duration: Tokens.snap; easing.type: Tokens.easeSnap } }
    }
    HoverHandler { id: hh; cursorShape: Qt.PointingHandCursor }
    TapHandler { id: tap; onTapped: sw.toggled(!sw.on) }
}
