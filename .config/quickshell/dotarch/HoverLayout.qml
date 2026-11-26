import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import Quickshell
import Quickshell.Io

// hover-layout v12
Item {
    id: root

    property var player: null
    property var date: new Date()
    property string timeFormat: "hh:mm"
    property bool showClock: true
    property bool showDate: true
    property bool showMedia: true
    property bool showWorkspaces: false                // kept for Notch.qml compatibility, not used here
    property rect restDotsRect: Qt.rect(0, 0, 0, 0)    // kept for Notch.qml compatibility, not used here
    property color accent: Theme.primary
    readonly property color fg: Theme.shellForeground
    readonly property bool isLight: fg.hslLightness < 0.5
    readonly property color ink: isLight ? "#000000" : "#ffffff"
    property color clockColor: isLight ? "#000000" : "#F3DFC1"
    property alias contentItem: content

    signal clockClicked()

    // the clock Text below only reserves its slot; Notch.qml draws the travelling clock
    property bool externalClock: false
    property real clockMix: 0
    property alias clockItem: clockText

    readonly property string fontName: {
        const have = Qt.fontFamilies()
        const want = ["SF Compact Display", "SF Compact", "SF Pro Display", "Inter"]
        for (let i = 0; i < want.length; i++)
            if (have.indexOf(want[i]) >= 0) return want[i]
        return Theme.fontFamily
    }

    // constant scale from the FINAL pill size
    // the design below is drawn in plain pixels for a 500x122 pill (u = 1);
    // a different pill size just scales everything proportionally
    property real boost: 1.3
    readonly property real finalH: NotchSettings.cfg.expandedHeight > 0 ? NotchSettings.cfg.expandedHeight : 122
    readonly property real finalW: NotchSettings.cfg.expandedWidth > 0 ? NotchSettings.cfg.expandedWidth : 500
    readonly property real u: finalH / 122
    readonly property real sidePad: Math.round(24 * u)            // pill edge to art / week strip
    readonly property real contentW: finalW - 2 * sidePad

    // ---------- left cluster geometry (everything derives from u) ----------
    readonly property real artSize: Math.round(74 * u)            // big album art
    readonly property real vizH: Math.round(11 * u)
    readonly property real vizGap: Math.round(5 * u)
    readonly property real stackH: artSize + vizGap + vizH
    readonly property real infoX: artSize + Math.round(18 * u)    // where title / controls start
    readonly property real ctlSize: Math.round(22 * u)            // glyph box of each control
    readonly property real ctlGap: Math.round(12 * u)
    readonly property real ctlInset: ctlSize * 0.25               // empty margin inside each 24x24 icon box
    readonly property real ctlRowW: 3 * ctlSize + 2 * ctlGap
    // visualizer: runs along the bottom from the art's left edge to the end of the left-side
    // elements (the longer of the title/artist text and the forward button, capped at the text area)
    readonly property real infoRight: contentW - rightW - 36 * u  // breathing room before the clock block
    readonly property real textEnd: infoX + Math.max(titleText.implicitWidth, artistText.implicitWidth)
    readonly property real vizW: Math.max(infoX + ctlRowW - 2 * ctlInset, Math.min(infoRight, textEnd))
    readonly property real vizT: Math.max(2, Math.round(2 * u))    // line thickness
    readonly property real barMax: vizH - vizT
    readonly property real rightW: Math.round(Math.min(132 * u, contentW * 0.33))
    readonly property real weekW: Math.floor(rightW / 5) * 5      // whole pixels per day column

    function clamp01(x) { return Math.max(0, Math.min(1, x)) }
    function smooth(x) { const t = clamp01(x); return t * t * (3 - 2 * t) }

    // how far the pill has opened, read from the real pill width
    property real w0: width
    readonly property real wF: finalW * 0.9
    readonly property real reveal: clamp01((width - w0) / Math.max(1, wF - w0))
    readonly property real fade: smooth((reveal - 0.66) / 0.22)

    onVisibleChanged: {
        if (visible) { w0 = width; if (root.player) root.player.positionChanged() }
    }

    // ---------- playback progress ----------
    readonly property real progress: (player && player.length > 0)
        ? Math.min(1, player.position / player.length) : 0

    Timer {
        interval: 1000
        repeat: true
        running: root.visible && !!root.player && root.player.isPlaying
        onTriggered: root.player.positionChanged()
    }

    // ---------- audio visualizer data (cava) ----------
    readonly property int barCount: Math.max(12, Math.round(vizW / (5.4 * u)))
    property var levels: []
    readonly property var shownLevels: root.visible ? root.levels : []
    readonly property bool vizActive: showMedia && !!player && player.isPlaying
    onVizActiveChanged: if (!vizActive) levels = []

    function levelAt(i) {
        const n = shownLevels.length
        if (n === 0) return 0
        if (n >= barCount) {
            const a = Math.floor(i * n / barCount)
            const b = Math.max(a + 1, Math.floor((i + 1) * n / barCount))
            let m = 0
            for (let k = a; k < b && k < n; k++)
                m = Math.max(m, shownLevels[k])
            return m
        }
        // fewer cava values than bars: interpolate so the bars stay smooth
        const pos = barCount > 1 ? i * (n - 1) / (barCount - 1) : 0
        const lo = Math.floor(pos)
        const hi = Math.min(n - 1, lo + 1)
        const f = pos - lo
        return shownLevels[lo] * (1 - f) + shownLevels[hi] * f
    }

    function vizColor(t, played) {
        const c = root.accent
        const base = c.hslSaturation > 0.08
            ? Qt.hsla((c.hslHue + 0.12 * t) % 1, c.hslSaturation, c.hslLightness, 1) : c
        return played ? base : Qt.rgba(base.r, base.g, base.b, 0.4)
    }

    Process {
        id: cava
        running: root.vizActive
        command: ["cava", "-p", Quickshell.shellDir + "/scripts/cava-hover.conf"]
        stdout: SplitParser {
            onRead: data => {
                const p = data.split(";")
                const out = []
                for (let i = 0; i < p.length; i++) {
                    if (p[i] === "") continue
                    out.push(Math.min(1, Math.pow(parseInt(p[i]) / 100, 0.75) * 1.2))
                }
                root.levels = out
            }
        }
    }

    // Monday to Friday of the current week
    readonly property var dayLetters: ["M", "T", "W", "T", "F"]
    readonly property var dayNames: ["MON", "TUE", "WED", "THU", "FRI"]
    readonly property var weekDays: {
        const d = root.date
        const off = (d.getDay() + 6) % 7
        const out = []
        for (let i = 0; i < 5; i++) {
            const x = new Date(d.getFullYear(), d.getMonth(), d.getDate() - off + i)
            out.push({
                num: x.getDate(),
                today: x.getFullYear() === d.getFullYear() && x.getMonth() === d.getMonth() && x.getDate() === d.getDate()
            })
        }
        return out
    }

    // smooth vector media button (24x24 material paths, anti-aliased curve renderer, rounded corners)
    component Ctl: Item {
        id: ctl

        property string path: ""
        property color tint: "#ffffff"
        property real glyphSize: 16

        signal clicked()

        width: glyphSize
        height: glyphSize
        opacity: ctlMouse.pressed ? 0.55 : (ctlHover.hovered ? 0.8 : 1)
        HoverHandler { id: ctlHover }

        Behavior on opacity {
            NumberAnimation { duration: 90 }
        }

        Shape {
            width: 24
            height: 24
            scale: ctl.glyphSize / 24
            transformOrigin: Item.TopLeft
            preferredRendererType: Shape.CurveRenderer
            antialiasing: true

            ShapePath {
                strokeWidth: 1.6
                strokeColor: ctl.tint
                joinStyle: ShapePath.RoundJoin
                fillColor: ctl.tint

                PathSvg {
                    path: ctl.path
                }
            }
        }

        MouseArea {
            id: ctlMouse

            anchors.fill: parent
            anchors.margins: -6
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: ctl.clicked()
        }
    }

    // Everything lives in a fixed-size item pinned to the pill CENTER,
    // so nothing moves (or shimmers) while the pill grows around it.
    Item {
        id: content
        width: root.contentW
        height: root.height
        anchors.horizontalCenter: parent.horizontalCenter

        readonly property real stackTop: Math.round((height - root.stackH) / 2)

        // ---------- left: big album art ----------
        Item {
            id: artBox
            visible: root.showMedia
            opacity: root.fade
            x: 0
            y: content.stackTop
            width: root.artSize
            height: root.artSize

            Rectangle {
                anchors.fill: parent
                radius: 12 * root.u
                color: Qt.rgba(root.ink.r, root.ink.g, root.ink.b, 0.08)
            }
            Image {
                id: art
                anchors.fill: parent
                source: root.player ? root.player.trackArtUrl : ""
                asynchronous: true
                fillMode: Image.PreserveAspectCrop
                smooth: true
                mipmap: true
                antialiasing: true
                visible: false
                layer.enabled: true
                layer.smooth: true
                layer.mipmap: true
            }
            Item {
                id: musicFallback
                anchors.centerIn: parent
                width: Math.round(38 * root.u)
                height: Math.round(38 * root.u)
                visible: art.status !== Image.Ready

                Text {
                    anchors.centerIn: parent
                    text: "♪"
                    color: root.ink
                    opacity: 0.9
                    font.family: "SF Pro Display"
                    font.pixelSize: Math.round(36 * root.u)
                    font.weight: Font.DemiBold
                }
            }
            Rectangle {
                id: artMask
                anchors.fill: parent
                radius: 12 * root.u
                antialiasing: true
                visible: false
                layer.enabled: true
                layer.smooth: true
            }
            MultiEffect {
                anchors.fill: parent
                source: art
                maskEnabled: true
                maskSource: artMask
                maskThresholdMin: 0.5
                maskSpreadAtMin: 1.0
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: if (root.player) root.player.togglePlaying()
            }
        }

        // ---------- visualizer: bars along the bottom ----------
        // bars before the playhead use the full theme colour, bars after it are dimmed,
        // so it doubles as the progress bar
        Item {
            id: viz
            visible: root.showMedia
            opacity: root.fade
            x: 0
            y: content.stackTop + root.artSize + root.vizGap
            width: root.vizW
            height: root.vizH

            readonly property real barW: 2.4 * root.u

            Repeater {
                model: root.barCount

                Rectangle {
                    required property int index

                    width: viz.barW
                    height: Math.max(2.5 * root.u, Math.min(1, root.levelAt(index) * 1.35) * viz.height)
                    x: index * (viz.width - viz.barW) / (root.barCount - 1)
                    y: viz.height - height
                    radius: width / 2
                    antialiasing: true
                    color: root.vizColor(index / (root.barCount - 1),
                                         (index + 0.5) / root.barCount <= root.progress)
                    Behavior on height { NumberAnimation { duration: 40 } }
                }
            }
        }

        // ---------- middle: title, artist and controls as one fixed block, centred beside the art ----------
        Item {
            id: infoCol
            visible: root.showMedia
            opacity: root.fade
            x: root.infoX
            y: content.stackTop + Math.round((root.artSize - height) / 2)
            width: Math.max(0, root.infoRight - x)
            height: ctlRow.y + ctlRow.height

            Column {
                id: textCol
                width: parent.width
                spacing: 1 * root.u

                Text {
                    id: titleText
                    width: parent.width
                    height: Math.round(16 * root.u)
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                    text: root.player && root.player.trackTitle ? root.player.trackTitle : "Nothing playing"
                    color: root.ink
                    font.family: root.fontName; renderType: Text.NativeRendering
                    font.pixelSize: Math.round(16 * root.u)
                    font.weight: Font.Bold
                }
                Text {
                    id: artistText
                    width: parent.width
                    height: Math.round(12 * root.u)
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                    text: root.player ? root.player.trackArtist : ""
                    color: Qt.rgba(root.ink.r, root.ink.g, root.ink.b, 0.6)
                    font.family: root.fontName; renderType: Text.NativeRendering
                    font.pixelSize: Math.round(12.5 * root.u)
                    font.weight: Font.Medium
                }
            }

            // fixed position right under the text block (every text line has a fixed height),
            // visible icons line up with the title's left edge
            Row {
                id: ctlRow
                visible: !!root.player
                x: -root.ctlInset
                y: textCol.height + Math.round(6 * root.u)
                spacing: root.ctlGap

                Ctl {
                    glyphSize: root.ctlSize
                    tint: root.ink
                    path: "M6 6h2v12H6zm3.5 6l8.5 6V6z"
                    onClicked: if (root.player) root.player.previous()
                }
                Ctl {
                    glyphSize: root.ctlSize
                    tint: root.ink
                    path: root.player && root.player.isPlaying
                          ? "M6 19h4V5H6v14zm8-14v14h4V5h-4z"
                          : "M8 5v14l11-7z"
                    onClicked: if (root.player) root.player.togglePlaying()
                }
                Ctl {
                    glyphSize: root.ctlSize
                    tint: root.ink
                    path: "M6 18l8.5-6L6 6v12zM16 6v12h2V6h-2z"
                    onClicked: if (root.player) root.player.next()
                }
            }
        }

        // ---------- right: clock + week strip ----------
        // vertically centred on the art row, so the art, the text block and this
        // block share the same centre line (the visualizer sits below as a footer)
        Column {
            id: rightCol
            anchors.right: parent.right
            y: content.stackTop + Math.round((root.artSize - height) / 2)
            width: root.rightW
            spacing: Math.round(8 * root.u)

            Text {
                id: clockText
                x: Math.round((rightCol.width - width) / 2)
                opacity: root.externalClock ? root.clockMix : root.fade
                visible: root.showClock
                text: Qt.formatDateTime(root.date, root.timeFormat)
                color: root.clockColor
                font.family: root.fontName; renderType: Text.NativeRendering
                font.pixelSize: Math.round(29 * root.u)
                font.weight: Font.Bold
            }

            Row {
                id: weekRow
                width: root.weekW
                x: Math.floor((rightCol.width - width) / 2)
                visible: root.showDate
                opacity: root.fade
                layer.enabled: true

                Repeater {
                    model: root.weekDays

                    Column {
                        required property var modelData
                        required property int index

                        width: weekRow.width / 5
                        spacing: Math.round(3 * root.u)

                        Text {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            text: modelData.today ? root.dayNames[index] : root.dayLetters[index]
                            color: modelData.today ? root.ink : Qt.rgba(root.ink.r, root.ink.g, root.ink.b, 0.4)
                            font.family: root.fontName; renderType: Text.NativeRendering
                            font.pixelSize: Math.round(11 * root.u)
                            font.weight: modelData.today ? Font.Bold : Font.Medium
                        }

                        Item {
                            width: parent.width
                            height: Math.round(20 * root.u)

                            Text {
                                x: Math.round((parent.width - width) / 2)
                                y: Math.round((parent.height - height) / 2)
                                text: modelData.num
                                color: modelData.today ? root.accent : Qt.rgba(root.ink.r, root.ink.g, root.ink.b, 0.45)
                                font.family: root.fontName; renderType: Text.NativeRendering
                                font.pixelSize: Math.round((modelData.today ? 19 : 14) * root.u)
                                font.weight: modelData.today ? Font.Bold : Font.Medium
                            }
                        }
                    }
                }
            }
        }

        MouseArea {
            anchors.fill: rightCol
            cursorShape: Qt.PointingHandCursor
            onClicked: root.clockClicked()
        }
    }
}
