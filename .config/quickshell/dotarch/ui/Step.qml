import QtQuick
import "Singletons"

// A bounded integer as a pair of buttons. Holding repeats.
Row {
    id: step
    property int value: 0
    property int from: 0
    property int to: 100
    property int stepBy: 1
    signal modified(int v)

    spacing: 0

    Repeater {
        model: ["−", "+"]
        Rectangle {
            id: b
            required property string modelData
            required property int index
            readonly property bool up: index === 1
            readonly property bool spent: up ? step.value >= step.to : step.value <= step.from

            width: 29
            height: 24
            radius: Tokens.radius
            opacity: spent ? 0.3 : 1
            color: !spent && tap.pressed ? Tokens.tint16 : (bh.hovered && !spent ? Tokens.tint10 : "transparent")
            border.width: Tokens.border
            border.color: bh.hovered && !spent ? Tokens.lineStrong : Tokens.line
            Behavior on color { ColorAnimation { duration: Tokens.snap } }

            Text {
                anchors.centerIn: parent
                text: b.modelData
                color: Tokens.inkDim
                font.family: Tokens.ui
                font.pixelSize: 13
            }
            HoverHandler { id: bh; enabled: !b.spent; cursorShape: Qt.PointingHandCursor }
            TapHandler {
                id: tap
                enabled: !b.spent
                longPressThreshold: 0.4
                onTapped: step.bump(b.up)
                onLongPressed: rep.start()
                onPressedChanged: if (!pressed) rep.stop()
                onCanceled: rep.stop()
            }
            Timer {
                id: rep
                interval: 125
                repeat: true
                onTriggered: b.spent ? stop() : step.bump(b.up)
            }
        }
    }
    function bump(up) {
        var v = value + (up ? stepBy : -stepBy);
        modified(Math.max(from, Math.min(to, v)));
    }
}
