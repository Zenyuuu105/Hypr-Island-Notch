pragma ComponentBehavior: Bound

import QtQuick
import qs
import "../ui/Singletons"

// 2-4 exclusive named modes. Each segment hugs its own label with side padding;
// the group wraps to a second line if the width it is given cannot hold one row.
// `labels` maps a stored value to readable text ({ dwindle: "Dwindle" }).
Item {
    id: seg

    property var options: []
    property var labels: ({})
    property string current: ""
    signal chose(string key)

    readonly property color ink: Tokens.ink
    readonly property color inkDim: Qt.rgba(ink.r, ink.g, ink.b, 0.78)
    readonly property color line: Qt.rgba(ink.r, ink.g, ink.b, 0.26)
    readonly property color lineStrong: Qt.rgba(ink.r, ink.g, ink.b, 0.42)
    readonly property color tint10: Qt.rgba(ink.r, ink.g, ink.b, 0.10)
    readonly property color tint16: Qt.rgba(ink.r, ink.g, ink.b, 0.16)

    activeFocusOnTab: true
    function activate(i) { if (i >= 0 && i < options.length) chose(options[i]) }
    Keys.onPressed: event => {
        var i = options.indexOf(current);
        if (event.key === Qt.Key_Right || event.key === Qt.Key_Down) {
            activate(Math.min(options.length - 1, i + 1)); event.accepted = true;
        } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Up) {
            activate(Math.max(0, i - 1)); event.accepted = true;
        }
    }

    readonly property int minSeg: 52
    readonly property int padSeg: 18
    readonly property int segH: 24

    implicitWidth: measure.implicitWidth
    implicitHeight: flow.implicitHeight
    width: parent ? Math.min(measure.implicitWidth, parent.width) : measure.implicitWidth
    height: flow.implicitHeight

    // an off-screen single row, so the natural width is known before the visible
    // Flow (which can only report the width it was already given) lays out
    Row {
        id: measure
        visible: false
        spacing: 4
        Repeater {
            model: seg.options
            Item {
                required property string modelData
                readonly property string shown: seg.labels && seg.labels[modelData] !== undefined ? seg.labels[modelData] : modelData
                width: Math.max(seg.minSeg, mlab.implicitWidth + seg.padSeg)
                height: seg.segH
                Text {
                    id: mlab
                    text: parent.shown
                    font.family: Tokens.ui
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    font.letterSpacing: 0.6
                }
            }
        }
    }

    Flow {
        id: flow
        width: seg.width
        spacing: 4
        Repeater {
            model: seg.options
            Rectangle {
                id: cell
                required property string modelData
                readonly property bool on: seg.current === modelData
                readonly property string shown: seg.labels && seg.labels[modelData] !== undefined ? seg.labels[modelData] : modelData
                width: Math.max(seg.minSeg, lab.implicitWidth + seg.padSeg)
                height: seg.segH
                radius: 6
                color: on ? seg.ink : (tap.pressed ? seg.tint16 : (sh.hovered ? seg.tint10 : "transparent"))
                border.width: 1
                border.color: sh.hovered && !on ? seg.lineStrong : seg.line
                Behavior on color { ColorAnimation { duration: 90 } }

                Text {
                    id: lab
                    anchors.centerIn: parent
                    text: cell.shown
                    color: cell.on ? Tokens.inkOnBone : seg.inkDim
                    font.family: Tokens.ui
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    font.letterSpacing: 0.6
                }
                HoverHandler { id: sh; cursorShape: Qt.PointingHandCursor }
                TapHandler { id: tap; onTapped: seg.chose(cell.modelData) }
            }
        }
    }
}
