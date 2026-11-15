import QtQuick
import "Singletons"

// A single-line text field. `edited` fires on user typing only; clear() does not
// emit it, so callers reset their own state alongside.
Rectangle {
    id: f

    property alias text: input.text
    property string placeholder: ""
    signal edited(string text)
    signal accepted()
    signal escaped()

    function clear() { input.text = ""; }
    function grabFocus() { input.forceActiveFocus(); input.selectAll(); }

    implicitHeight: 32
    radius: Tokens.radius
    color: "transparent"
    border.width: input.activeFocus ? 2 : Tokens.border
    border.color: input.activeFocus ? Tokens.ink : Tokens.line

    TextInput {
        id: input
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        verticalAlignment: TextInput.AlignVCenter
        clip: true
        autoScroll: activeFocus
        selectByMouse: true
        color: Tokens.ink
        font.family: Tokens.ui
        font.pixelSize: 13
        onTextEdited: f.edited(text)
        onAccepted: f.accepted()
        Keys.onEscapePressed: f.escaped()
    }
    Text {
        visible: input.text === ""
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: 10
        text: f.placeholder
        color: Tokens.inkFaint
        font.family: Tokens.ui
        font.pixelSize: 13
    }
}
