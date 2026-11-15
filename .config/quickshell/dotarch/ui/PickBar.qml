import QtQuick
import "Singletons"

// A button-like readout that opens a picker (a long list, like fonts).
Rectangle {
    id: pb

    property string value: ""
    signal opened()

    implicitHeight: 32
    radius: Tokens.radius
    color: tap.pressed ? Tokens.tint16 : (hh.hovered ? Tokens.tint10 : "transparent")
    border.width: Tokens.border
    border.color: hh.hovered ? Tokens.lineStrong : Tokens.line
    Behavior on color { ColorAnimation { duration: Tokens.snap } }

    Text {
        anchors { left: parent.left; right: arrow.left; verticalCenter: parent.verticalCenter }
        anchors.leftMargin: 10
        anchors.rightMargin: Tokens.s2
        text: pb.value
        elide: Text.ElideRight
        color: Tokens.ink
        font.family: Tokens.ui
        font.pixelSize: 12
    }
    Text {
        id: arrow
        anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
        text: "\u25be"
        color: Tokens.inkDim
        font.family: Tokens.ui
        font.pixelSize: 11
    }
    HoverHandler { id: hh; cursorShape: Qt.PointingHandCursor }
    TapHandler { id: tap; onTapped: pb.opened() }
}
