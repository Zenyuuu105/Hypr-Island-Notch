import ".."
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root
    property string title: ""
    property string footer: ""
    default property alias content: col.data
    spacing: 6

    Text {
        visible: root.title !== ""
        text: root.title.toUpperCase()
        color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.9)
        font.pixelSize: 11
        font.weight: Font.DemiBold
        font.letterSpacing: 1.0
        leftPadding: 4
    }

    Rectangle {
        Layout.fillWidth: true
        visible: col.implicitHeight > 0
        implicitHeight: col.implicitHeight
        radius: 12
        color: Qt.rgba(1, 1, 1, 0.04)
        border.width: 1
        border.color: Theme.cardBorder

        ColumnLayout {
            id: col
            width: parent.width
            spacing: 0
        }
    }

    Text {
        visible: root.footer !== ""
        Layout.fillWidth: true
        text: root.footer
        color: Theme.muted
        font.pixelSize: 11
        wrapMode: Text.WordWrap
        leftPadding: 4
    }
}
