import QtQuick
import Quickshell.Services.Notifications
import qs
import qs.components

FocusScope {
    id: root

    readonly property var items: ShellState.notificationModel ? ShellState.notificationModel.values.slice().reverse() : []

    function clearAll() {
        const all = items.slice();
        for (let i = 0; i < all.length; i++)
            all[i].dismiss();

    }

    implicitWidth: 420
    implicitHeight: 330

    Item {
        id: header

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: 34

        ShellText {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: "Notifications" + (ShellState.peaceMode ? "  ·  Peace Mode on" : "")
            color: Theme.foreground
            font.pixelSize: 15
            font.weight: Font.DemiBold
        }

        Rectangle {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            visible: root.items.length > 0
            width: 86
            height: 28
            radius: Theme.radiusSmall
            color: Theme.bg1

            ShellText {
                anchors.centerIn: parent
                text: "Clear all"
                color: Theme.foreground
                font.pixelSize: 12
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.clearAll()
            }

        }

    }

    ShellText {
        anchors.centerIn: parent
        visible: root.items.length === 0
        text: "No notifications"
        color: Theme.muted
        font.pixelSize: 13
    }

    ListView {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: header.bottom
        anchors.topMargin: 8
        anchors.bottom: parent.bottom
        clip: true
        spacing: 6
        model: root.items

        delegate: Rectangle {
            id: row

            required property var modelData
            readonly property bool critical: modelData.urgency === NotificationUrgency.Critical

            width: ListView.view.width
            height: 60
            radius: Theme.radiusSmall
            color: Theme.bg0
            border.width: critical ? 1 : 0
            border.color: Theme.red

            Column {
                anchors.left: parent.left
                anchors.right: closeButton.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 12
                anchors.rightMargin: 8
                spacing: 2

                ShellText {
                    width: parent.width
                    elide: Text.ElideRight
                    text: row.modelData.appName || "Notification"
                    color: row.critical ? Theme.red : Theme.primary
                    font.pixelSize: 10
                }

                ShellText {
                    width: parent.width
                    elide: Text.ElideRight
                    text: row.modelData.summary
                    color: Theme.foreground
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                }

                ShellText {
                    width: parent.width
                    elide: Text.ElideRight
                    visible: text.length > 0
                    text: row.modelData.body
                    color: Theme.muted
                    font.pixelSize: 11
                }

            }

            IconButton {
                id: closeButton

                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                width: 28
                height: 28
                icon: "×"
                accessibleName: "Dismiss notification"
                onClicked: row.modelData.dismiss()
            }

        }

    }

}
