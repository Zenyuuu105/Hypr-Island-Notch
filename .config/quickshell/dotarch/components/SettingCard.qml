import QtQuick
import qs
import "../ui/Singletons"

// A titled group of rows drawn as one bordered sheet, rows parted by hairlines.
// The header caret folds the group away. Ryoku's card, on the dotarch Theme.
Item {
    id: card

    property string title: ""
    property bool collapsible: true
    property bool expanded: true
    // what a folded card is hiding, said in the header
    property string summary: ""

    default property alias content: body.data

    readonly property color ink: Tokens.ink
    readonly property color inkDim: Qt.rgba(ink.r, ink.g, ink.b, 0.78)
    readonly property color inkFaint: Qt.rgba(ink.r, ink.g, ink.b, 0.46)
    readonly property color line: Qt.rgba(ink.r, ink.g, ink.b, 0.26)
    readonly property color lineSoft: Qt.rgba(ink.r, ink.g, ink.b, 0.13)

    readonly property int headerH: 46
    implicitHeight: headerH + bodyWrap.height
    height: implicitHeight

    Rectangle {
        anchors.fill: parent
        radius: 6
        color: "transparent"
        border.width: 1
        border.color: card.line
    }

    Item {
        id: header
        anchors { left: parent.left; right: parent.right; top: parent.top }
        height: card.headerH

        Text {
            anchors { left: parent.left; leftMargin: 16; verticalCenter: parent.verticalCenter }
            text: card.title
            color: card.inkDim
            font.family: Tokens.ui
            font.pixelSize: 12
            font.weight: Font.Medium
            font.letterSpacing: 1.4
            font.capitalization: Font.AllUppercase
        }

        Text {
            visible: !card.expanded && card.summary !== ""
            anchors { right: caret.left; rightMargin: 12; verticalCenter: parent.verticalCenter }
            text: card.summary
            color: card.inkFaint
            font.family: Tokens.mono
            font.pixelSize: 9
            font.letterSpacing: 2.2
        }

        Text {
            id: caret
            visible: card.collapsible
            anchors { right: parent.right; rightMargin: 16; verticalCenter: parent.verticalCenter }
            text: "\u25b8"
            color: hh.hovered ? (tap.pressed ? card.ink : card.inkDim)
                : (card.expanded ? card.inkFaint : card.inkDim)
            font.family: Tokens.ui
            font.pixelSize: 10
            rotation: card.expanded ? 90 : 0
            Behavior on rotation { NumberAnimation { duration: 90; easing.type: Easing.OutQuad } }
            Behavior on color { ColorAnimation { duration: 90 } }
        }

        // the rule that closes the header, seen only while the group is open
        Rectangle {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            height: 1
            color: card.lineSoft
            opacity: card.expanded ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 90 } }
        }

        HoverHandler { id: hh; enabled: card.collapsible; cursorShape: Qt.PointingHandCursor }
        TapHandler { id: tap; enabled: card.collapsible; onTapped: card.expanded = !card.expanded }
    }

    Item {
        id: bodyWrap
        anchors { left: parent.left; right: parent.right; top: header.bottom }
        height: card.expanded ? body.implicitHeight : 0
        clip: true
        enabled: card.expanded
        opacity: card.expanded ? 1 : 0
        Behavior on height { NumberAnimation { duration: 210; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }

        Column {
            id: body
            anchors { left: parent.left; right: parent.right; top: parent.top }
            spacing: 0
        }
    }
}
