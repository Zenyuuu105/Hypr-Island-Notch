import QtQuick
import QtQuick.Controls
import "Singletons"

// A page: eyebrow, big title, blurb, then a scrolling body of balanced card
// columns. Declare SettingCards directly inside it.
Item {
    id: page

    property string eyebrow: ""
    property string title: ""
    property string blurb: ""
    default property alias cards: body.content

    Column {
        id: head
        anchors { left: parent.left; top: parent.top }
        width: parent.width - Tokens.s3
        spacing: Tokens.s3

        Row {
            visible: page.eyebrow !== ""
            height: 18
            spacing: Tokens.s2
            Rectangle { width: 16; height: 1; color: Tokens.ink; anchors.verticalCenter: parent.verticalCenter }
            Text {
                text: page.eyebrow
                color: Tokens.inkMuted
                font.family: Tokens.ui
                font.pixelSize: 9
                font.weight: Font.Medium
                font.letterSpacing: Tokens.trackMark
                anchors.verticalCenter: parent.verticalCenter
            }
        }
        Text {
            text: page.title
            color: Tokens.ink
            font.family: Tokens.display
            font.pixelSize: Tokens.fTitle
        }
        Text {
            visible: page.blurb !== ""
            width: Math.min(parent.width, 720)
            text: page.blurb
            color: Tokens.inkMuted
            font.family: Tokens.ui
            font.pixelSize: Tokens.fBody
            wrapMode: Text.WordWrap
        }
    }

    Flickable {
        id: flick
        anchors { left: parent.left; right: parent.right; top: head.bottom; bottom: parent.bottom }
        anchors.topMargin: Tokens.s5
        contentWidth: width
        contentHeight: Math.max(body.height, height)
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollRail { policy: ScrollBar.AsNeeded }

        CardColumns {
            id: body
            width: flick.width - Tokens.s3
            fillTo: flick.height
        }
    }
}
