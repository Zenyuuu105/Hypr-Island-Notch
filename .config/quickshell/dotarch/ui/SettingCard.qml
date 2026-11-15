import QtQuick
import "Singletons"

// A titled, collapsible group of rows drawn as one bordered sheet. `note` is a
// faint explanatory paragraph under the rows; `summary` says what a folded card hides.
Item {
    id: card

    property string title: ""
    property bool collapsible: true
    property bool expanded: true
    property string summary: ""
    property string note: ""

    default property alias content: body.data

    readonly property int headerH: 46
    readonly property real noteH: note !== "" ? noteText.implicitHeight + Tokens.s3 * 2 : 0
    implicitHeight: headerH + bodyWrap.height
    height: implicitHeight

    Rectangle {
        anchors.fill: parent
        radius: Tokens.radius
        color: "transparent"
        border.width: Tokens.border
        border.color: Tokens.line
    }

    Item {
        id: header
        anchors { left: parent.left; right: parent.right; top: parent.top }
        height: card.headerH

        Text {
            anchors { left: parent.left; leftMargin: Tokens.s4; verticalCenter: parent.verticalCenter }
            text: card.title
            color: Tokens.inkDim
            font.family: Tokens.ui
            font.pixelSize: Tokens.fBody
            font.weight: Font.Medium
            font.letterSpacing: Tokens.trackLabel
        }
        Text {
            visible: !card.expanded && card.summary !== ""
            anchors { right: caret.left; rightMargin: Tokens.s3; verticalCenter: parent.verticalCenter }
            text: card.summary
            color: Tokens.inkFaint
            font.family: Tokens.mono
            font.pixelSize: Tokens.fTiny
            font.letterSpacing: Tokens.trackMark
        }
        Text {
            id: caret
            visible: card.collapsible
            anchors { right: parent.right; rightMargin: Tokens.s4; verticalCenter: parent.verticalCenter }
            text: "\u25b8"
            color: hh.hovered ? Tokens.inkDim : (card.expanded ? Tokens.inkFaint : Tokens.inkDim)
            font.family: Tokens.ui
            font.pixelSize: 10
            rotation: card.expanded ? 90 : 0
            Behavior on rotation { NumberAnimation { duration: Tokens.snap; easing.type: Tokens.easeSnap } }
        }
        Rectangle {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            anchors.leftMargin: Tokens.s4
            anchors.rightMargin: Tokens.s4
            height: 1
            color: Tokens.lineSoft
            opacity: card.expanded ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Tokens.snap } }
        }
        HoverHandler { id: hh; enabled: card.collapsible; cursorShape: Qt.PointingHandCursor }
        TapHandler { enabled: card.collapsible; onTapped: card.expanded = !card.expanded }
    }

    Item {
        id: bodyWrap
        anchors { left: parent.left; right: parent.right; top: header.bottom }
        height: card.expanded ? body.implicitHeight + card.noteH : 0
        clip: true
        enabled: card.expanded
        opacity: card.expanded ? 1 : 0
        Behavior on height { NumberAnimation { duration: Tokens.swap; easing.type: Tokens.ease } }
        Behavior on opacity { NumberAnimation { duration: Tokens.flap; easing.type: Tokens.ease } }

        Column {
            id: body
            anchors { left: parent.left; right: parent.right; top: parent.top }
            spacing: 0
        }
        Text {
            id: noteText
            visible: card.note !== ""
            anchors {
                left: parent.left; right: parent.right; top: body.bottom
                leftMargin: Tokens.s4; rightMargin: Tokens.s4; topMargin: Tokens.s3
            }
            text: card.note
            wrapMode: Text.WordWrap
            color: Tokens.inkFaint
            font.family: Tokens.ui
            font.pixelSize: 12
        }
    }
}
