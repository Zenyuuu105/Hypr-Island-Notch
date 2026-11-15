import QtQuick
import QtQuick.Controls
import "../ui/Singletons"

// A dropdown over a list of strings, in Ryoku's hairline box.
ComboBox {
    id: ctl
    font.family: Tokens.ui
    font.pixelSize: Tokens.fSmall
    implicitHeight: 34

    background: Rectangle {
        radius: Tokens.radius
        color: Tokens.paperLift
        border.width: 1
        border.color: (ctl.hovered || ctl.popup.visible) ? Tokens.lineStrong : Tokens.line
        Behavior on border.color { ColorAnimation { duration: Tokens.snap } }
    }

    contentItem: Text {
        leftPadding: Tokens.s3
        rightPadding: 30
        text: ctl.displayText
        color: Tokens.ink
        font: ctl.font
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    indicator: Text {
        x: ctl.width - width - Tokens.s3
        y: (ctl.height - height) / 2
        text: "▾"
        color: Tokens.inkMuted
        font.family: Tokens.ui
        font.pixelSize: Tokens.fSmall
    }

    delegate: ItemDelegate {
        id: dlg
        required property var modelData
        required property int index
        width: ctl.width
        height: 32
        highlighted: ctl.highlightedIndex === index

        contentItem: Text {
            leftPadding: Tokens.s3
            text: dlg.modelData
            color: dlg.highlighted ? Tokens.inkOnBone : Tokens.ink
            font: ctl.font
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }
        background: Rectangle {
            color: dlg.highlighted ? Tokens.bone : "transparent"
        }
    }

    popup: Popup {
        y: ctl.height + 2
        width: ctl.width
        padding: 1
        implicitHeight: Math.min(contentItem.implicitHeight + 2, 260)

        contentItem: ListView {
            clip: true
            implicitHeight: contentHeight
            model: ctl.popup.visible ? ctl.delegateModel : null
            currentIndex: ctl.highlightedIndex
        }
        background: Rectangle {
            radius: Tokens.radius
            color: Tokens.paperLift
            border.width: 1
            border.color: Tokens.lineStrong
        }
    }
}
