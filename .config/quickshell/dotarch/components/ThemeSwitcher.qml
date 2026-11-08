// ThemeSwitcher.qml
// Searchable theme carousel that springs out of the clock pill.
// All numbers measured frame-by-frame from a 1366x768 / 60fps screen recording.
import QtQuick

Item {
    id: root

    // ───────────── API ─────────────
    property var    themes: []          // [{ name, bg, fg, colors: [6 hex], accent? }]
    property string activeName: ""      // currently applied theme (gets the small dot)
    property bool   open: false
    property string clockText: ""
    property string fontFamily: "Inter"
    property int    applyDelay: 430     // ms between Enter and the collapse (wallpaper crossfades ~200ms meanwhile)
    signal applied(string name)
    signal closed()

    // ───────────── Measured geometry (px) ─────────────
    readonly property real pillW:  59
    readonly property real pillH:  21
    readonly property real panelW: 572
    readonly property real panelH: 158
    readonly property real cardW:  133
    readonly property real cardH:  69
    readonly property real pitch:  138.5   // card width + gap
    readonly property real lift:   6       // selected card rises 6px
    readonly property real cardTop: 48     // neighbours' top, from panel top

    implicitWidth:  panelW
    implicitHeight: panelH

    // ───────────── Springs (fit to the recording) ─────────────
    // open ≈ w 18 / zeta 0.78 (≈1.5% overshoot in the video), close ≈ w 24 / zeta 0.8 (undershoots to ~51x19)
    Spring { id: morph;  target: root.open ? 1 : 0; omega: root.open ? 18 : 24; zeta: root.open ? 0.78 : 0.8 }
    Spring { id: scroll; omega: 19; zeta: 0.88 }

    // width AND height follow the same curve
    readonly property real m: morph.value
    readonly property real mc: Math.max(0, Math.min(1, m))
    function ramp(a, b) { return Math.max(0, Math.min(1, (mc - a) / (b - a))) }

    // content fades out fast on close (~110ms), before the shell has finished shrinking
    property real cf: open ? 1 : 0
    Behavior on cf { NumberAnimation { duration: root.open ? 60 : 110; easing.type: Easing.OutQuad } }

    // ───────────── State ─────────────
    property string query: ""
    readonly property var filtered: {
        var q = query.toLowerCase()
        return themes.filter(function (t) { return t.name.toLowerCase().indexOf(q) !== -1 })
    }
    property int current: 0

    onCurrentChanged: scroll.target = current
    onFilteredChanged: current = 0

    onOpenChanged: {
        if (open) {
            query = ""
            input.text = ""
            var i = 0
            for (var k = 0; k < themes.length; k++)
                if (themes[k].name === activeName) i = k
            current = i
            scroll.snap(i)
            input.forceActiveFocus()
        } else {
            closeTimer.stop()
            input.focus = false
        }
    }

    function move(d) {
        if (filtered.length === 0) return
        current = Math.max(0, Math.min(filtered.length - 1, current + d))
    }

    function apply() {
        if (filtered.length === 0) return
        var t = filtered[current]
        activeName = t.name
        applied(t.name)               // start your wallpaper/theme crossfade here (~200ms ease-out)
        closeTimer.restart()
    }

    function close() { open = false; closed() }

    Timer { id: closeTimer; interval: root.applyDelay; onTriggered: root.close() }

    // ───────────── The island ─────────────
    Rectangle {
        id: island
        anchors.horizontalCenter: parent.horizontalCenter
        y: 0
        width:  Math.max(24, root.pillW + (root.panelW - root.pillW) * root.m)
        height: Math.max(12, root.pillH + (root.panelH - root.pillH) * root.m)
        radius: Math.min(height / 2, 20)
        color: "#101010"
        border.width: 1
        border.color: "#12ffffff"
        clip: true

        // clock, only while it's a pill
        Text {
            text: root.clockText
            anchors.horizontalCenter: parent.horizontalCenter
            y: (root.pillH - height) / 2
            font.family: root.fontFamily
            font.pixelSize: 11
            font.weight: Font.DemiBold
            color: "#f2f2f2"
            opacity: 1 - root.ramp(0, 0.2)
        }

        // Content lives at its final size, centred, and is revealed by the island growing
        Item {
            id: content
            width: root.panelW
            height: root.panelH
            x: (island.width - width) / 2
            opacity: root.cf

            // ── search row ──
            Item {
                width: parent.width
                height: 41
                opacity: root.ramp(0.08, 0.3)

                Rectangle {                       // magnifier
                    x: 10.5; y: 16; width: 9; height: 9; radius: 4.5
                    color: "transparent"
                    border.width: 1.4
                    border.color: "#8a8a8a"
                }
                Rectangle {
                    x: 18.2; y: 23.8; width: 4; height: 1.4
                    color: "#8a8a8a"
                    rotation: 45
                    transformOrigin: Item.Left
                }

                TextInput {
                    id: input
                    x: 30
                    y: 20.5 - height / 2
                    width: 400
                    font.family: root.fontFamily
                    font.pixelSize: 11
                    color: "#e8e8e8"
                    selectionColor: "#40ffffff"
                    selectByMouse: true
                    clip: true
                    onTextChanged: root.query = text

                    Keys.onPressed: function (e) {
                        var ctrl = (e.modifiers & Qt.ControlModifier)
                        if (e.key === Qt.Key_Left || (ctrl && e.key === Qt.Key_H)) {
                            root.move(-1); e.accepted = true
                        } else if (e.key === Qt.Key_Right || (ctrl && e.key === Qt.Key_L)) {
                            root.move(1); e.accepted = true
                        } else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
                            root.apply(); e.accepted = true
                        } else if (e.key === Qt.Key_Escape) {
                            root.close(); e.accepted = true
                        }
                    }
                }

                Text {
                    visible: input.text.length === 0
                    x: input.x
                    y: input.y
                    text: "Search themes..."
                    font.family: root.fontFamily
                    font.pixelSize: 11
                    color: "#6e6e6e"
                }

                Text {                            // 15/18
                    anchors.right: parent.right
                    anchors.rightMargin: 10.5
                    y: 20.5 - height / 2
                    text: root.filtered.length ? (root.current + 1) + "/" + root.filtered.length : "0/0"
                    font.family: root.fontFamily
                    font.pixelSize: 9
                    color: "#5c5c5c"
                }
            }

            // ── carousel (clipped 10px in from each side) ──
            Item {
                id: car
                x: 10
                y: 30
                width: root.panelW - 20
                height: 100
                clip: true
                opacity: root.ramp(0.25, 0.5)

                Repeater {
                    model: root.filtered

                    delegate: Rectangle {
                        id: card
                        required property var modelData
                        required property int index

                        // 1 when this card is the (animated) selection, 0 when a full card away
                        readonly property real selT: Math.max(0, 1 - Math.abs(index - scroll.value))
                        readonly property bool isActive: modelData.name === root.activeName
                        readonly property color fg: modelData.fg
                        readonly property color bgc: modelData.bg
                        readonly property color ringColor: isActive ? (modelData.accent || modelData.fg) : "#ececec"

                        x: car.width / 2 - root.cardW / 2 + (index - scroll.value) * root.pitch
                        y: root.cardTop - car.y - root.lift * selT
                        width: root.cardW
                        height: root.cardH
                        radius: 11
                        color: Qt.rgba(bgc.r, bgc.g, bgc.b, 0.72 + 0.28 * selT)

                        // selection ring: fades in as the card becomes the selection
                        Rectangle {
                            anchors.fill: parent
                            radius: 12
                            color: "transparent"
                            border.width: 2
                            border.color: Qt.rgba(card.ringColor.r, card.ringColor.g, card.ringColor.b, card.selT)
                        }

                        // six palette dots, 10px, ~2.7px apart
                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: 23
                            spacing: 2.7
                            Repeater {
                                model: card.modelData.colors
                                delegate: Rectangle {
                                    required property string modelData
                                    width: 10; height: 10; radius: 5
                                    color: modelData
                                }
                            }
                        }

                        // name
                        Text {
                            width: parent.width - 16
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: 56.5 - height / 2
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                            text: card.modelData.name
                            font.family: root.fontFamily
                            font.pixelSize: 9
                            font.weight: card.selT > 0.5 ? Font.DemiBold : Font.Medium
                            color: Qt.rgba(card.fg.r, card.fg.g, card.fg.b, 0.6 + 0.4 * card.selT)
                        }

                        // "currently applied" dot
                        Rectangle {
                            visible: card.isActive
                            x: root.cardW - 8.5 - width / 2
                            y: 8 - height / 2
                            width: 5; height: 5; radius: 2.5
                            color: card.ringColor
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (card.index === root.current) root.apply()
                                else root.current = card.index
                            }
                        }
                    }
                }
            }

            // ── footer hint ──
            Text {
                anchors.right: parent.right
                anchors.rightMargin: 10.5
                y: 141 - height / 2
                text: "Enter to apply"
                font.family: root.fontFamily
                font.pixelSize: 9
                font.letterSpacing: -0.15
                color: "#646464"
                opacity: root.ramp(0.8, 1)
            }
        }
    }
}
