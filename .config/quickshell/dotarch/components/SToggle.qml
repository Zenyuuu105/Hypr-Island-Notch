import QtQuick

Item {
    id: root
    property string label: ""
    property string hint: ""
    property bool checked: false
    property color accent: "#f2b8c0"
    signal toggled(bool v)

    implicitHeight: hint !== "" ? 46 : 34
    implicitWidth: 400

    Column {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2
        Text { text: root.label; color: "#e6e1e1"; font.pixelSize: 13 }
        Text { visible: root.hint !== ""; text: root.hint; color: "#8c8686"; font.pixelSize: 11 }
    }

    Rectangle {
        width: 44; height: 24; radius: 12
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        color: root.checked ? root.accent : "#3a3636"
        Rectangle {
            width: 18; height: 18; radius: 9
            y: 3
            x: root.checked ? 23 : 3
            color: root.checked ? "#3a1c22" : "#a8a3a3"
            Behavior on x { NumberAnimation { duration: 120 } }
        }
    }

    MouseArea { anchors.fill: parent; onClicked: root.toggled(!root.checked) }
}
