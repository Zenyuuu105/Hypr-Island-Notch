import QtQuick
import "Singletons"

// 2-4 exclusive named modes, each segment hugging its label.
Item {
    id: seg
    property var options: []
    property string current: ""
    signal chose(string key)

    implicitWidth: row.implicitWidth
    implicitHeight: 24

    Row {
        id: row
        spacing: Tokens.s1
        Repeater {
            model: seg.options
            Rectangle {
                id: plate
                required property string modelData
                readonly property bool on: seg.current === modelData
                width: Math.max(52, lab.implicitWidth + 18)
                height: 24
                radius: Tokens.radius
                color: on ? Tokens.bone : (tap.pressed ? Tokens.tint16 : (sh.hovered ? Tokens.tint10 : "transparent"))
                border.width: Tokens.border
                border.color: sh.hovered && !on ? Tokens.lineStrong : Tokens.line
                Behavior on color { ColorAnimation { duration: Tokens.snap } }

                Text {
                    id: lab
                    anchors.centerIn: parent
                    text: plate.modelData
                    color: plate.on ? Tokens.inkOnBone : Tokens.inkDim
                    font.family: Tokens.ui
                    font.pixelSize: 9
                    font.weight: Font.Medium
                    font.letterSpacing: 0.6
                }
                HoverHandler { id: sh; cursorShape: Qt.PointingHandCursor }
                TapHandler { id: tap; onTapped: seg.chose(plate.modelData) }
            }
        }
    }
}
