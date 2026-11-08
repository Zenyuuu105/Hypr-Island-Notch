import QtQuick
import qs
import qs.components
import ".."

Item {
    id: row

    property string icon: ""
    property string title: ""
    property string subtitle: ""
    property bool active: false
    property bool busy: false
    property string actionText: ""
    property bool secondaryActionVisible: false
    property string secondaryActionName: ""
    property real pulse: 1

    signal clicked()
    signal secondaryClicked()

    height: 54

    SequentialAnimation on pulse {
        running: row.busy
        loops: Animation.Infinite

        NumberAnimation { to: 0.45; duration: 500 }
        NumberAnimation { to: 1; duration: 500 }
    }

    Rectangle {
        anchors.fill: parent
        radius: 14
        color: row.active ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.14)
                          : (rowArea.containsMouse ? Qt.rgba(1, 1, 1, 0.07) : Qt.rgba(1, 1, 1, 0.03))
        border.width: 1
        border.color: row.active ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.35) : Theme.cardBorder

        Behavior on color {
            ColorAnimation { duration: Theme.animationFast }
        }
    }

    MouseArea {
        id: rowArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: row.clicked()
    }

    Rectangle {
        id: rowBadge
        anchors.left: parent.left
        anchors.leftMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        width: 34
        height: 34
        radius: 17
        color: row.active ? Theme.primary : Qt.rgba(1, 1, 1, 0.08)

        ShellText {
            anchors.centerIn: parent
            text: row.icon
            font.family: Theme.iconFontFamily
            color: row.active ? Theme.bgDim : Theme.muted
            font.pixelSize: 16
        }
    }

    Row {
        id: rowActions
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

        Item {
            visible: row.secondaryActionVisible
            anchors.verticalCenter: parent.verticalCenter
            width: 26
            height: 26

            Rectangle {
                anchors.fill: parent
                radius: 13
                color: forgetArea.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : "transparent"
            }

            ShellText {
                anchors.centerIn: parent
                text: "×"
                color: Theme.muted
                font.pixelSize: 16
            }

            MouseArea {
                id: forgetArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: row.secondaryClicked()
            }
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            height: 28
            width: pillText.implicitWidth + 22
            radius: 14
            opacity: row.busy ? row.pulse : 1
            color: row.active ? Qt.rgba(1, 1, 1, 0.10) : Theme.primary

            ShellText {
                id: pillText
                anchors.centerIn: parent
                text: row.busy ? "Working…" : row.actionText
                color: row.active ? Theme.foreground : Theme.bgDim
                font.pixelSize: 11
                font.weight: Font.Bold
            }
        }
    }

    Column {
        anchors.left: rowBadge.right
        anchors.leftMargin: 10
        anchors.right: rowActions.left
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        spacing: 1

        ShellText {
            width: parent.width
            elide: Text.ElideRight
            text: row.title
            color: Theme.foreground
            font.pixelSize: 13
            font.weight: Font.DemiBold
        }

        ShellText {
            width: parent.width
            elide: Text.ElideRight
            visible: text.length > 0
            text: row.subtitle
            color: row.active ? Theme.primary : Theme.muted
            font.pixelSize: 11
        }
    }
}
