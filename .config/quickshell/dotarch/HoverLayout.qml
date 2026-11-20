import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Item {
    id: root

    property var player: null
    property var date: new Date()
    property string timeFormat: "hh:mm"
    property bool showClock: true
    property bool showDate: true
    property bool showMedia: true
    property bool showWorkspaces: true
    property rect restDotsRect: Qt.rect(0, 0, 0, 0)   // resting dots rect, in contentItem coords (set by Notch.qml)
    property color accent: Theme.primary
    readonly property color fg: Theme.shellForeground
    readonly property bool isLight: fg.hslLightness < 0.5
    readonly property color ink: isLight ? "#000000" : "#ffffff"
    property color clockColor: isLight ? "#000000" : "#F3DFC1"
    property alias contentItem: content

    signal clockClicked()

    readonly property string fontName: {
        const have = Qt.fontFamilies()
        const want = ["SF Compact Display", "SF Compact", "SF Pro Display", "Inter"]
        for (let i = 0; i < want.length; i++)
            if (have.indexOf(want[i]) >= 0) return want[i]
        return Theme.fontFamily
    }

    // constant scale from the FINAL pill size
    property real boost: 1.3
    readonly property real finalH: NotchSettings.cfg.expandedHeight > 0 ? NotchSettings.cfg.expandedHeight : 106
    readonly property real finalW: NotchSettings.cfg.expandedWidth > 0 ? NotchSettings.cfg.expandedWidth : 445
    readonly property real u: Math.min(finalH / 106, finalW / 445) * boost
    readonly property real contentW: finalW - 36

    function clamp01(x) { return Math.max(0, Math.min(1, x)) }
    function smooth(x) { const t = clamp01(x); return t * t * (3 - 2 * t) }

    // how far the pill has opened, read from the real pill width
    property real w0: width
    readonly property real wF: finalW * 0.9
    readonly property real reveal: clamp01((width - w0) / Math.max(1, wF - w0))
    readonly property real fade: smooth((reveal - 0.4) / 0.4)

    // workspace dots timeline (time based, independent of the pill spring)
    property real dotsP: 1
    NumberAnimation { id: dotsAnim; target: root; property: "dotsP"; from: 0; to: 1; duration: 520; easing.type: Easing.OutCubic }
    onVisibleChanged: {
        if (visible) { w0 = width; dotsP = 0; dotsAnim.restart(); if (root.player) root.player.positionChanged() }
    }

    readonly property int wsActive: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1
    readonly property int wsCount: {
        let m = 5
        const ws = Hyprland.workspaces.values
        for (let i = 0; i < ws.length; i++)
            if (ws[i].id > m) m = ws[i].id
        return m
    }

    readonly property real progress: (player && player.length > 0)
        ? Math.min(1, player.position / player.length) : 0

    function vizColor(t, played) {
        const c = root.accent
        const base = c.hslSaturation > 0.08
            ? Qt.hsla((c.hslHue + 0.12 * t) % 1, c.hslSaturation, c.hslLightness, 1) : c
        return played ? base : Qt.rgba(base.r, base.g, base.b, 0.5)
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.visible && !!root.player && root.player.isPlaying
        onTriggered: root.player.positionChanged()
    }

    // ---------- audio visualizer data (cava) ----------
    readonly property int barCount: 32
    property var levels: []
    readonly property var shownLevels: root.visible ? root.levels : []
    readonly property bool vizActive: showMedia && !!player && player.isPlaying
    onVizActiveChanged: if (!vizActive) levels = []

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

    // Everything lives in a fixed-size item pinned to the pill CENTER,
    // so nothing moves (or shimmers) while the pill grows around it.
    Item {
        id: content
        width: root.contentW
        height: root.height
        anchors.horizontalCenter: parent.horizontalCenter

        // ---------- left: clock + date ----------
        Column {
            id: leftCol
            anchors.left: parent.left
            anchors.leftMargin: 8 * root.u
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2 * root.u
            opacity: root.fade

            Text {
                visible: root.showClock
                text: Qt.formatDateTime(root.date, root.timeFormat)
                color: root.clockColor
                font.family: root.fontName; renderType: Text.NativeRendering
                font.pixelSize: Math.round(22 * root.u)
                font.weight: Font.Bold
            }
            Text {
                visible: root.showDate
                text: Qt.formatDate(root.date, "dddd, MMMM d")
                color: Qt.rgba(root.ink.r, root.ink.g, root.ink.b, 0.5)
                font.family: root.fontName; renderType: Text.NativeRendering
                font.pixelSize: Math.round(10 * root.u)
                font.weight: Font.Medium
            }
        }

        MouseArea {
            anchors.fill: leftCol
            cursorShape: Qt.PointingHandCursor
            onClicked: root.clockClicked()
        }

        // ---------- right: media + progress + visualizer ----------
        Column {
            id: rightCol
            anchors.right: parent.right
            anchors.rightMargin: 4 * root.u
            anchors.verticalCenter: parent.verticalCenter
            width: 163 * root.u
            spacing: 4 * root.u

            Item {
                id: mediaRow
                width: parent.width
                height: 28 * root.u
                visible: root.showMedia
                opacity: root.fade

                Item {
                    id: artBox
                    width: 28 * root.u
                    height: 28 * root.u
                    anchors.right: parent.right

                    Rectangle { anchors.fill: parent; radius: 6 * root.u; color: Qt.rgba(root.ink.r, root.ink.g, root.ink.b, 0.08) }
                    Image {
                        id: art
                        anchors.fill: parent
                        source: root.player ? root.player.trackArtUrl : ""
                        asynchronous: true
                        fillMode: Image.PreserveAspectCrop
                        visible: false
                        layer.enabled: true
                    }
                    Rectangle { id: artMask; anchors.fill: parent; radius: 6 * root.u; visible: false; layer.enabled: true }
                    MultiEffect { anchors.fill: parent; source: art; maskEnabled: true; maskSource: artMask }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (root.player) root.player.togglePlaying()
                    }
                }

                Column {
                    anchors.right: artBox.left
                    anchors.rightMargin: 8 * root.u
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 1 * root.u

                    Text {
                        width: parent.width
                        horizontalAlignment: Text.AlignRight
                        elide: Text.ElideRight
                        text: root.player ? root.player.trackTitle : "Nothing playing"
                        color: root.ink
                        font.family: root.fontName; renderType: Text.NativeRendering
                        font.pixelSize: Math.round(9.5 * root.u)
                        font.weight: Font.Bold
                    }
                    Text {
                        width: parent.width
                        horizontalAlignment: Text.AlignRight
                        elide: Text.ElideRight
                        text: root.player ? root.player.trackArtist : ""
                        color: Qt.rgba(root.ink.r, root.ink.g, root.ink.b, 0.5)
                        font.family: root.fontName; renderType: Text.NativeRendering
                        font.pixelSize: Math.round(8 * root.u)
                        font.weight: Font.Medium
                    }
                }
            }

            // thin progress line
            Rectangle {
                width: parent.width
                height: Math.max(1, Math.round(root.u))
                visible: root.showMedia
                color: Qt.rgba(root.ink.r, root.ink.g, root.ink.b, 0.12)
                opacity: root.fade
                Rectangle {
                    height: parent.height
                    color: Qt.rgba(root.ink.r, root.ink.g, root.ink.b, 0.35)
                    width: parent.width * root.progress
                }
            }

            // audio visualizer (theme gradient)
            Item {
                id: viz
                width: parent.width
                height: 12 * root.u
                visible: root.showMedia
                opacity: root.fade

                readonly property real barW: 2.2 * root.u
                readonly property real gap: (width - root.barCount * barW) / (root.barCount - 1)

                Row {
                    anchors.fill: parent
                    spacing: viz.gap

                    Repeater {
                        model: root.barCount
                        Item {
                            required property int index
                            width: viz.barW
                            height: viz.height

                            Rectangle {
                                readonly property real v: root.shownLevels.length > index ? root.shownLevels[index] : 0
                                anchors.centerIn: parent
                                width: parent.width
                                height: Math.max(2 * root.u, v * viz.height)
                                radius: width / 2
                                color: root.vizColor(index / (root.barCount - 1),
                                                     (index + 0.5) / root.barCount <= root.progress)
                                Behavior on height { NumberAnimation { duration: 40 } }
                            }
                        }
                    }
                }
            }

            // layout slot reserved for the workspace dots
            Item { id: dotsSlot; width: parent.width; height: 7 * root.u; visible: root.showWorkspaces }
        }

        // ---------- workspace dots: slide from the resting pill into this slot ----------
        readonly property bool hasRest: root.restDotsRect.width > 0 && root.restDotsRect.height > 0

        Item {
            id: dots
            z: 5
            visible: root.showWorkspaces
            width: dotsRow.width
            height: 7 * root.u

            readonly property real finalX: rightCol.x + rightCol.width - width
            readonly property real finalY: rightCol.y + dotsSlot.y + (dotsSlot.height - height) / 2
            readonly property real startX: content.hasRest
                ? root.restDotsRect.x + (root.restDotsRect.width - width) / 2
                : finalX - 28 * root.u
            readonly property real startY: content.hasRest
                ? root.restDotsRect.y + (root.restDotsRect.height - height) / 2
                : finalY

            readonly property real dotStage: root.clamp01((root.dotsP - 0.3) / 0.7)
            x: finalX - (1 - dotStage) * 28 * root.u
            y: finalY
            opacity: dotStage

            Row {
                id: dotsRow
                spacing: 6 * root.u

                Repeater {
                    model: root.wsCount
                    Item {
                        required property int index
                        readonly property bool active: index + 1 === root.wsActive
                        width: (active ? 18 : 5) * root.u
                        height: 7 * root.u
                        Behavior on width { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width
                            height: (parent.active ? 7 : 5) * root.u
                            radius: height / 2
                            color: parent.active ? root.accent
                                                 : Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.32)
                            Behavior on height { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                            Behavior on color { ColorAnimation { duration: 180 } }
                        }
                    }
                }
            }
        }
    }
}
