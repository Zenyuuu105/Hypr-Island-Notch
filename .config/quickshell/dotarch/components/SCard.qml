import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    property string title: ""
    default property alias content: col.data

    color: "#1c1919"
    radius: 16
    implicitWidth: 400
    implicitHeight: col.implicitHeight + (title !== "" ? 54 : 28)

    Text {
        visible: root.title !== ""
        text: root.title
        color: "#f2b8c0"
        font.pixelSize: 13
        font.bold: true
        x: 16; y: 14
    }

    ColumnLayout {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        y: root.title !== "" ? 42 : 14
        spacing: 8
    }
}
