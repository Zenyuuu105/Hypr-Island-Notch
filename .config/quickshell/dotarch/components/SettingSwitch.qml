import QtQuick
import QtQuick.Layouts
import qs
import "../ui/Singletons"

RowLayout {
    id: root
    property string label: ""
    property string description: ""
    property bool checked: false
    signal toggled(bool value)

    spacing: 12
    Layout.fillWidth: true
    implicitHeight: description !== "" ? 39 : 30

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 2

        Text {
            Layout.fillWidth: true
            text: root.label
            color: Tokens.ink
            font.family: Tokens.ui
            font.pixelSize: 11
            font.weight: Font.Medium
            elide: Text.ElideRight
        }

        Text {
            visible: root.description !== ""
            Layout.fillWidth: true
            text: root.description
            color: Tokens.inkMuted
            font.family: Tokens.ui
            font.pixelSize: 9
            wrapMode: Text.WordWrap
        }
    }

    Rectangle {
        id: track
        Layout.preferredWidth: 54
        Layout.preferredHeight: 24
        radius: 6
        color: root.checked ? Tokens.tint16 : Tokens.tint5
        border.width: Tokens.border
        border.color: hover.hovered ? Tokens.lineStrong : Tokens.line

        Rectangle {
            width: 16
            height: 16
            radius: 4
            y: (parent.height - height) / 2
            x: root.checked ? parent.width - width - 4 : 4
            color: root.checked ? Tokens.ink : Tokens.inkDim

            Behavior on x {
                NumberAnimation {
                    duration: Tokens.move
                    easing.type: Easing.OutCubic
                }
            }
        }

        HoverHandler { id: hover }
        TapHandler { onTapped: root.toggled(!root.checked) }
    }
}
