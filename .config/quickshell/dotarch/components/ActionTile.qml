import QtQuick
import qs

FocusScope {
    id: root

    property string icon: ""
    property string title: ""
    property string subtitle: ""
    property bool active: false
    property bool expandable: false
    property bool expanded: false
    property string detailAccessibleName: "Show " + title + " options"

    signal clicked()
    signal detailClicked()

    implicitHeight: 58
    activeFocusOnTab: true
    Keys.onReturnPressed: root.clicked()
    Keys.onEnterPressed: root.clicked()
    Keys.onSpacePressed: root.clicked()
    Accessible.role: Accessible.Button
    Accessible.name: title + (subtitle ? ", " + subtitle : "")

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusCard
        color: Theme.cardColor
        border.width: root.activeFocus || detailButton.activeFocus ? 2 : 1
        border.color: root.activeFocus || detailButton.activeFocus ? Theme.cardBorderSelected : Theme.cardBorder
    }

    Row {
        anchors.left: parent.left
        anchors.right: detailButton.visible ? detailButton.left : parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.margins: 9
        spacing: 8

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 32
            height: 32
            radius: 16
            color: root.active ? Theme.foreground : Theme.bg1

            Behavior on color {
                ColorAnimation {
                    duration: Theme.animationFast
                }
            }

            ShellText {
                anchors.centerIn: parent
                text: root.icon
                font.family: Theme.iconFontFamily
                color: root.active ? Theme.bgDim : Theme.muted
                font.pixelSize: 18
                font.weight: Font.Bold
            }
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 40
            spacing: 2

            ShellText {
                width: parent.width
                text: root.title
                color: Theme.foreground
                elide: Text.ElideRight
                font.pixelSize: 14
                font.weight: Font.DemiBold
            }

            ShellText {
                width: parent.width
                text: root.subtitle
                color: Theme.muted
                elide: Text.ElideRight
                font.pixelSize: 11
            }
        }
    }

    MouseArea {
        anchors.left: parent.left
        anchors.right: detailButton.visible ? detailButton.left : parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }

    FocusScope {
        id: detailButton

        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: root.expandable ? 31 : 0
        visible: root.expandable
        activeFocusOnTab: visible
        Keys.onReturnPressed: root.detailClicked()
        Keys.onEnterPressed: root.detailClicked()
        Keys.onSpacePressed: root.detailClicked()
        Accessible.role: Accessible.Button
        Accessible.name: root.detailAccessibleName

        Rectangle {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: 1
            height: parent.height - 18
            color: Theme.cardBorder
        }

        ShellText {
            anchors.centerIn: parent
            text: root.expanded ? "󰅃" : "󰅀"
            color: Theme.mutedDark
            font.pixelSize: 15
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.detailClicked()
        }
    }
}
