import QtQuick
import qs
import qs.components
import ".."

Item {
    id: sectionLabel

    property string text: ""

    height: 24

    ShellText {
        anchors.left: parent.left
        anchors.leftMargin: 6
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 4
        text: sectionLabel.text.toUpperCase()
        color: Theme.muted
        font.pixelSize: 10
        font.weight: Font.Bold
    }
}
