import QtQuick
import qs

FocusScope {
    id: root

    property string icon: ""
    property string title: ""
    property string subtitle: ""
    property bool active: false
    property bool busy: false
    property string actionText: ""
    property bool secondaryActionVisible: false
    property string secondaryActionName: ""
    property int titleFontSize: 13
    property int subtitleFontSize: 11
    property int actionFontSize: 11

    signal clicked()
    signal secondaryClicked()

    implicitHeight: 42
    activeFocusOnTab: true
    Keys.onReturnPressed: root.clicked()
    Keys.onEnterPressed: root.clicked()
    Keys.onSpacePressed: root.clicked()
    Accessible.role: Accessible.Button
    Accessible.name: title + (actionText ? ", " + actionText : "")

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusSmall + 4
        color: rowPointer.containsMouse ? Theme.bg1 : Theme.cardColor
        border.width: root.activeFocus ? 2 : 1
        border.color: root.activeFocus ? Theme.cardBorderSelected : Theme.cardBorder

        Behavior on color {
            ColorAnimation {
                duration: Theme.animationFast
            }
        }
    }

    MouseArea {
        id: rowPointer

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }

    Rectangle {
        id: badge

        anchors.left: parent.left
        anchors.leftMargin: 7
        anchors.verticalCenter: parent.verticalCenter
        width: 28
        height: 28
        radius: 14
        color: root.active ? Theme.foreground : Theme.bg1

        ShellText {
            anchors.centerIn: parent
            text: root.icon
            font.family: Theme.iconFontFamily
            color: root.active ? Theme.bgDim : Theme.muted
            font.pixelSize: 15
        }
    }

    Rectangle {
        id: pill

        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        height: 24
        width: pillText.implicitWidth + 22
        radius: 12
        color: root.active ? Theme.foreground : Theme.bg1
        border.width: root.active ? 0 : 1
        border.color: Theme.cardBorder
        opacity: root.busy ? 0.5 : 1

        ShellText {
            id: pillText

            anchors.centerIn: parent
            text: root.busy ? "…" : root.actionText
            color: root.active ? Theme.bgDim : Theme.foreground
            font.pixelSize: root.actionFontSize
            font.weight: Font.DemiBold
        }
    }

    Item {
        id: forgetButton

        anchors.right: pill.left
        anchors.rightMargin: 4
        anchors.verticalCenter: parent.verticalCenter
        width: 22
        height: 22
        visible: root.secondaryActionVisible && (rowPointer.containsMouse || forgetPointer.containsMouse)
        Accessible.role: Accessible.Button
        Accessible.name: root.secondaryActionName

        ShellText {
            anchors.centerIn: parent
            text: "󰅖"
            font.family: Theme.iconFontFamily
            color: forgetPointer.containsMouse ? Theme.red : Theme.mutedDark
            font.pixelSize: 14
        }

        MouseArea {
            id: forgetPointer

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.secondaryClicked()
        }
    }

    Column {
        anchors.left: badge.right
        anchors.leftMargin: 9
        anchors.right: forgetButton.visible ? forgetButton.left : pill.left
        anchors.rightMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        spacing: 1

        ShellText {
            width: parent.width
            text: root.title
            color: Theme.foreground
            elide: Text.ElideRight
            font.pixelSize: root.titleFontSize
            font.weight: Font.DemiBold
        }

        ShellText {
            width: parent.width
            text: root.subtitle
            color: Theme.muted
            elide: Text.ElideRight
            font.pixelSize: root.subtitleFontSize
            visible: text.length > 0
        }
    }
}
