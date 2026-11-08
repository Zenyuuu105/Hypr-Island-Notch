import QtQuick

Item {
    id: root
    property string label: ""
    property var options: []      // [{ key: "a", text: "A" }, ...]
    property string current: ""
    property color accent: "#f2b8c0"
    signal picked(string key)

    implicitHeight: 66
    implicitWidth: 400

    Text { text: root.label; color: "#e6e1e1"; font.pixelSize: 13; anchors.left: parent.left; anchors.top: parent.top }

    Row {
        y: 26
        spacing: 8
        Repeater {
            model: root.options
            delegate: Rectangle {
                required property var modelData
                readonly property bool on: root.current === modelData.key
                height: 34
                width: lbl.implicitWidth + 32
                radius: 17
                color: on ? root.accent : "#2a2626"
                Text {
                    id: lbl
                    anchors.centerIn: parent
                    text: modelData.text
                    font.pixelSize: 12
                    color: parent.on ? "#3a1c22" : "#e6e1e1"
                }
                MouseArea { anchors.fill: parent; onClicked: root.picked(modelData.key) }
            }
        }
    }
}
