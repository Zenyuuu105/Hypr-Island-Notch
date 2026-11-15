import QtQuick
import QtQuick.Layouts
import qs

Item {
    id: root

    property string title: ""
    property string description: ""
    property bool expanded: true

    default property alias contentData: body.data

    implicitWidth: 400
    implicitHeight: header.height + (expanded ? 1 + body.implicitHeight + 25 : 0)

    Rectangle {
        anchors.fill: parent
        radius: 7
        color: Theme.bg1
        border.width: 1
        border.color: Theme.cardBorder
    }

    Item {
        id: header
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: 46

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 13
            spacing: 10

            Rectangle {
                Layout.preferredWidth: 3
                Layout.preferredHeight: 17
                radius: 1
                color: root.expanded ? Theme.primary : Theme.mutedDark
                opacity: root.expanded ? 0.9 : 0.45
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    Layout.fillWidth: true
                    text: root.title
                    color: Theme.foreground
                    font.family: "Geist"
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }

                Text {
                    visible: root.description !== ""
                    Layout.fillWidth: true
                    text: root.description
                    color: Theme.muted
                    font.family: "Geist"
                    font.pixelSize: 9
                    elide: Text.ElideRight
                }
            }

            Text {
                text: root.expanded ? "−" : "+"
                color: Theme.muted
                font.family: "Geist"
                font.pixelSize: 16
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.expanded = !root.expanded
        }
    }

    Rectangle {
        visible: root.expanded
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: header.bottom
        height: 1
        color: Theme.cardBorder
    }

    ColumnLayout {
        id: body
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: header.bottom
        anchors.leftMargin: 15
        anchors.rightMargin: 15
        anchors.topMargin: 12
        anchors.bottomMargin: 13
        spacing: 11
        visible: root.expanded
    }

    Behavior on implicitHeight {
        NumberAnimation {
            duration: 160
            easing.type: Easing.OutCubic
        }
    }
}
