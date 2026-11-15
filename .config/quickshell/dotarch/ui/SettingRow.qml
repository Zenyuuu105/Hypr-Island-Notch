import QtQuick
import "Singletons"

// One setting: label and description on the left, control on the right. A row
// with `block: true` (chips, a tall control) or `footH` (a field) puts its
// control in a band beneath the text instead.
//
//   value / unit  compact readout left of the control (a slider number)
//   def / changed struck default and a revert glyph, shown on hover when changed
Item {
    id: row
    width: parent ? parent.width : implicitWidth

    property string label: ""
    property string desc: ""
    property string value: ""
    property string unit: ""
    property string def: ""
    property bool changed: false
    property bool block: false
    property int footH: 0
    property bool divider: false
    property real controlWidth: 54

    signal resetRequested()

    default property alias control: slot.data

    readonly property int padV: Tokens.s3
    readonly property int padH: Tokens.s4
    readonly property bool banded: block || footH > 0
    readonly property real bandH: block
        ? Math.max(Tokens.ctlH, slot.children.length > 0 ? slot.children[0].implicitHeight : 0)
        : (footH > 0 ? footH : Tokens.ctlH)

    implicitHeight: banded
        ? padV + txt.implicitHeight + Tokens.s3 + bandH + padV
        : Math.max(Tokens.rowH, padV + txt.implicitHeight + padV)
    height: implicitHeight

    opacity: row.enabled ? 1 : 0.4
    Behavior on opacity { NumberAnimation { duration: Tokens.snap; easing.type: Tokens.ease } }

    // hover wash, quiet so a stack of rows does not strobe
    Rectangle {
        anchors.fill: parent
        anchors.margins: 1
        radius: Tokens.radius
        color: hh.hovered ? Tokens.tint5 : "transparent"
        Behavior on color { ColorAnimation { duration: Tokens.snap } }
    }
    HoverHandler { id: hh }

    // hairline between rows, inset so it reads as a rule
    Rectangle {
        visible: row.divider
        anchors { left: parent.left; right: parent.right; top: parent.top }
        anchors.leftMargin: row.padH
        anchors.rightMargin: row.padH
        height: 1
        color: Tokens.lineSoft
    }

    // changed reads as a solid ink edge; no colour is spent on it
    Rectangle {
        visible: row.changed
        anchors { left: parent.left; verticalCenter: parent.verticalCenter }
        width: 2
        height: parent.height - Tokens.s3
        color: Tokens.ink
    }

    Column {
        id: txt
        anchors {
            left: parent.left; leftMargin: row.padH
            top: parent.top; topMargin: row.padV
            right: row.banded ? parent.right : vcluster.left
            rightMargin: row.banded ? row.padH : Tokens.s3
        }
        spacing: 1
        Text {
            width: parent.width
            text: row.label
            color: Tokens.ink
            font.family: Tokens.ui
            font.pixelSize: Tokens.fRow
            font.weight: Font.Medium
            elide: Text.ElideRight
        }
        Text {
            visible: row.desc !== ""
            width: parent.width
            text: row.desc
            color: Tokens.inkMuted
            font.family: Tokens.ui
            font.pixelSize: Tokens.fSmall
            wrapMode: Text.WordWrap
            maximumLineCount: 2
            elide: Text.ElideRight
        }
    }

    // inline cluster, seated left of the control so nothing overlaps it
    Row {
        id: vcluster
        visible: !row.banded && (row.value !== "" || (row.changed && hh.hovered))
        anchors { right: slot.left; rightMargin: Tokens.s3; verticalCenter: parent.verticalCenter }
        spacing: Tokens.s2
        Text {
            visible: row.value !== ""
            text: row.value
            color: Tokens.ink
            font.family: Tokens.ui
            font.pixelSize: Tokens.fBody
            font.weight: Font.Light
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            visible: row.value !== "" && row.unit !== ""
            text: row.unit
            color: Tokens.inkMuted
            font.family: Tokens.ui
            font.pixelSize: 10
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            visible: row.changed && hh.hovered && row.def !== ""
            text: row.def + (row.unit ? " " + row.unit : "")
            color: Tokens.inkFaint
            font.family: Tokens.mono
            font.pixelSize: Tokens.fTiny
            font.strikeout: true
            anchors.verticalCenter: parent.verticalCenter
        }
        Rectangle {
            visible: row.changed && hh.hovered
            width: 18
            height: 18
            radius: Tokens.radius
            color: rh.hovered ? Tokens.tint10 : "transparent"
            border.width: Tokens.border
            border.color: rh.hovered ? Tokens.lineStrong : Tokens.line
            anchors.verticalCenter: parent.verticalCenter
            Text { anchors.centerIn: parent; text: "\u21ba"; color: Tokens.inkDim; font.family: Tokens.ui; font.pixelSize: 11 }
            HoverHandler { id: rh; cursorShape: Qt.PointingHandCursor }
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
