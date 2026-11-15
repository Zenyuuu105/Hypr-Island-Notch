import QtQuick
import qs
import "../ui/Singletons"

// One setting as a compact row: label first, description under it, the control on
// the right, or in a band beneath the text for a control that needs room (a slider,
// a segmented bar). Rows stack inside a SettingCard parted by a hairline. Ryoku's
// row, on the dotarch Theme, with the same properties the pages already use.
Item {
    id: row

    property string label: ""
    property string desc: ""
    property string value: ""       // compact readout (a slider number); empty hides
    property string unit: ""
    property string def: ""         // factory value, struck through when changed
    property bool changed: false
    property bool block: false      // control band beneath the text
    property int footH: 0           // control band of a fixed height
    property bool divider: true     // hairline above the row; never drawn on a card's first row
    property real controlWidth: 54  // width reserved for an inline control

    signal resetRequested()

    default property alias control: slot.data

    readonly property color ink: Tokens.ink
    readonly property color inkMuted: Qt.rgba(ink.r, ink.g, ink.b, 0.66)
    readonly property color inkFaint: Qt.rgba(ink.r, ink.g, ink.b, 0.46)
    readonly property color line: Qt.rgba(ink.r, ink.g, ink.b, 0.26)
    readonly property color lineSoft: Qt.rgba(ink.r, ink.g, ink.b, 0.13)
    readonly property color lineStrong: Qt.rgba(ink.r, ink.g, ink.b, 0.42)
    readonly property color tint5: Qt.rgba(ink.r, ink.g, ink.b, 0.05)
    readonly property color tint10: Qt.rgba(ink.r, ink.g, ink.b, 0.10)
    readonly property color tint16: Qt.rgba(ink.r, ink.g, ink.b, 0.16)

    readonly property int padV: 12
    readonly property int padH: 16
    readonly property int minH: 48
    readonly property int ctlH: 24
    readonly property bool banded: block || footH > 0
    readonly property bool isFirst: !parent || parent.children.length === 0 || parent.children[0] === row
    readonly property real bandH: footH > 0
        ? footH
        : (block ? Math.max(ctlH, slot.children.length > 0 ? slot.children[0].implicitHeight : 0) : ctlH)

    width: parent ? parent.width : 300
    implicitHeight: banded
        ? padV + txt.implicitHeight + 12 + bandH + padV
        : Math.max(minH, padV + txt.implicitHeight + padV)
    height: implicitHeight

    // a row gated by a master switch stops looking live as well as stopping input
    opacity: row.enabled ? 1 : 0.4
    Behavior on opacity { NumberAnimation { duration: 90 } }

    // hover wash, quiet enough that a stack of rows does not strobe
    Rectangle {
        anchors.fill: parent
        anchors.margins: 1
        radius: 6
        color: hh.hovered ? row.tint5 : "transparent"
        Behavior on color { ColorAnimation { duration: 90 } }
    }
    HoverHandler { id: hh }

    // the part between rows, inset so it reads as a rule and not a box edge
    Rectangle {
        visible: row.divider && !row.isFirst
        anchors { left: parent.left; right: parent.right; top: parent.top }
        anchors.leftMargin: row.padH
        anchors.rightMargin: row.padH
        height: 1
        color: row.lineSoft
    }

    // changed reads as a solid ink edge; no colour is spent on it
    Rectangle {
        visible: row.changed
        anchors { left: parent.left; verticalCenter: parent.verticalCenter }
        width: 2
        height: parent.height - 12
        color: row.ink
    }

    // label, then description. Its right edge stops at the readout or control.
    Column {
        id: txt
        anchors {
            left: parent.left; leftMargin: row.padH
            top: parent.top; topMargin: row.padV
            right: row.banded ? parent.right : (vcluster.visible ? vcluster.left : slot.left)
            rightMargin: row.banded
                ? row.padH + (vcluster.visible ? vcluster.width + 12 : 0)
                : 12
        }
        spacing: 1

        Text {
            width: parent.width
            text: row.label
            color: row.ink
            font.family: Tokens.ui
            font.pixelSize: 15
            font.weight: Font.Medium
            elide: Text.ElideRight
        }
        Text {
            visible: row.desc !== ""
            width: parent.width
            text: row.desc
            color: row.inkMuted
            font.family: Tokens.ui
            font.pixelSize: 13
            wrapMode: Text.WordWrap
            maximumLineCount: 2
            elide: Text.ElideRight
        }
    }

    // readout cluster: the number (and unit), plus a struck default and a revert
    // glyph on hover when changed. Sits left of an inline control, or at the top
    // right of a banded row.
    Row {
        id: vcluster
        visible: row.value !== "" || (row.changed && hh.hovered)
        spacing: 8
        anchors.right: row.banded ? parent.right : slot.left
        anchors.rightMargin: row.banded ? row.padH : 12
        anchors.top: row.banded ? parent.top : undefined
        anchors.topMargin: row.padV
        anchors.verticalCenter: row.banded ? undefined : parent.verticalCenter

        Text {
            visible: row.value !== ""
            text: row.value
            color: row.ink
            font.family: Tokens.ui
            font.pixelSize: 14
            font.weight: Font.Light
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            visible: row.value !== "" && row.unit !== ""
            text: row.unit
            color: row.inkMuted
            font.family: Tokens.ui
            font.pixelSize: 10
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            visible: row.changed && hh.hovered && row.def !== ""
            text: row.def + (row.unit ? " " + row.unit : "")
            color: row.inkFaint
            font.family: Tokens.mono
            font.pixelSize: 9
            font.strikeout: true
            anchors.verticalCenter: parent.verticalCenter
        }
        Rectangle {
            visible: row.changed && hh.hovered
            width: 18
            height: 18
            radius: 6
            color: rhi.hovered ? row.tint10 : "transparent"
            border.width: 1
            border.color: rhi.hovered ? row.lineStrong : row.line
            anchors.verticalCenter: parent.verticalCenter
            Text {
                anchors.centerIn: parent
                text: "\u21ba"
                color: row.ink
                font.family: Tokens.ui
                font.pixelSize: 11
            }
            HoverHandler { id: rhi; cursorShape: Qt.PointingHandCursor }
            TapHandler { onTapped: row.resetRequested() }
        }
    }

    // the control: inline at the right, or a full-width band beneath the text
    Item {
        id: slot
        anchors.right: parent.right
        anchors.rightMargin: row.padH
        anchors.verticalCenter: row.banded ? undefined : parent.verticalCenter
        anchors.left: row.banded ? parent.left : undefined
        anchors.leftMargin: row.padH
        anchors.bottom: row.banded ? parent.bottom : undefined
        anchors.bottomMargin: row.padV
        width: row.banded ? undefined : row.controlWidth
        height: row.bandH
    }
}
