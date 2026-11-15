import QtQuick
import QtQuick.Controls
import "../ui/Singletons"

// A text input in Ryoku's hairline box.
TextField {
    id: ctl
    color: Tokens.ink
    selectionColor: Tokens.bone
    selectedTextColor: Tokens.inkOnBone
    placeholderTextColor: Tokens.inkFaint
    font.family: Tokens.ui
    font.pixelSize: Tokens.fSmall
    leftPadding: Tokens.s3
    rightPadding: Tokens.s3
    implicitHeight: 34

    background: Rectangle {
        radius: Tokens.radius
        color: Tokens.paperLift
        border.width: 1
        border.color: ctl.activeFocus ? Tokens.lineStrong : Tokens.line
        Behavior on border.color { ColorAnimation { duration: Tokens.snap } }
    }
}
