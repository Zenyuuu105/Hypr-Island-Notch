import QtQuick
import qs
import "../ui/Singletons"

// A boolean. Two named modes are a Seg, not a switch. Off is a dim knob on a
// faint track, on brightens the track and fills the knob: two signals, one state.
Rectangle {
    id: sw

    property bool on: false
    signal toggled(bool value)

    readonly property color ink: Tokens.ink
    readonly property color inkDim: Qt.rgba(ink.r, ink.g, ink.b, 0.66)
    readonly property color line: Qt.rgba(ink.r, ink.g, ink.b, 0.26)
    readonly property color lineStrong: Qt.rgba(ink.r, ink.g, ink.b, 0.42)
    readonly property color tint5: Qt.rgba(ink.r, ink.g, ink.b, 0.05)
    readonly property color tint16: Qt.rgba(ink.r, ink.g, ink.b, 0.16)

    activeFocusOnTab: true
    function activate() { toggled(!on) }
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
            activate();
            event.accepted = true;
        }
    }

    implicitWidth: 54
    implicitHeight: 24
    radius: 6
    color: tap.pressed ? tint16 : (sw.on ? tint16 : tint5)
    border.width: 1
    border.color: activeFocus ? ink : (hh.hovered ? lineStrong : line)
    antialiasing: false
    Behavior on border.color { ColorAnimation { duration: 90 } }
    Behavior on color { ColorAnimation { duration: 90 } }

    Rectangle {
        width: 25
        height: 17
        y: 3
        x: sw.on ? parent.width - width - 3 : 3
        radius: 6
        antialiasing: false
        color: sw.on ? sw.ink : sw.inkDim
        Behavior on x { NumberAnimation { duration: 90; easing.type: Easing.OutQuad } }
    }

    HoverHandler { id: hh; cursorShape: Qt.PointingHandCursor }
    TapHandler { id: tap; onTapped: sw.toggled(!sw.on) }
}
