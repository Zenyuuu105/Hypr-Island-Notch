import QtQuick
import qs

Row {
    id: root

    property string keys: ""
    property string label: ""
    property real ui: 1.2

    spacing: 6 * ui

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        height: 18 * root.ui
        width: keyText.implicitWidth + 12 * root.ui
        radius: 6 * root.ui
        color: Qt.alpha(Theme.shellForeground, 0.07)
        border.width: 1
        border.color: Qt.alpha(Theme.shellForeground, 0.08)

        ShellText {
            id: keyText
            anchors.centerIn: parent
            text: root.keys
            color: Theme.mutedDark
            font.pixelSize: Math.round(10 * root.ui)
        }
    }

    ShellText {
        anchors.verticalCenter: parent.verticalCenter
        text: root.label
        color: Theme.mutedDark
        font.pixelSize: Math.round(11 * root.ui)
    }
}
