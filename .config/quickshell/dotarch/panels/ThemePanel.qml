import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs
import qs.components
import ".."

FocusScope {
    id: root

    // One knob for the whole panel. 1.0 = size measured from the recording (425 x 262).
    readonly property real ui: 1.25

    readonly property string query: searchInput.text.trim().toLowerCase()
    readonly property var liveThemes: AppearanceState.themes.filter(theme => query === "" || theme.name.toLowerCase().indexOf(query) >= 0)
    property var frozenThemes: []
    readonly property var themes: root.applying ? root.frozenThemes : root.liveThemes

    // Measured from the recording, times ui
    readonly property real rowH: Math.round(33.5 * ui)
    readonly property real expH: Math.round(69.5 * ui)
    readonly property real viewH: 4 * rowH + expH
    readonly property int applyDelay: 430

    // Header layout: everything below derives from these
    readonly property real padTop: Math.round(10 * ui)
    readonly property real searchH: Math.round(36 * ui)
    readonly property real dividerY: padTop + searchH
    readonly property real listY: dividerY + Math.round(6 * ui)

    property int currentIndex: 0
    property real wheelAccum: 0
    property bool applying: false
    property bool autoClose: false
    property var walls: ({})

    // Fractional selected index, one critically damped spring (~150ms settle)
    readonly property real sel: selSpring.value
    // How far the list still has to travel to reach the selected row
    readonly property real travel: Math.abs(currentIndex - sel)

    // Held key / fast wheel: the card dissolves while the rows glide past as plain
    // compact rows, then grows back where the list lands (matches the recording)
    property bool scrubbing: false
    onTravelChanged: {
        if (travel > 1.5)
            scrubbing = true;
        else if (travel < 0.8)
            scrubbing = false;
    }
    property real cardMix: scrubbing ? 0 : 1
    Behavior on cardMix {
        NumberAnimation {
            duration: root.scrubbing ? 70 : 170
            easing.type: Easing.OutCubic
        }
    }

    readonly property real scrollY: Math.max(0, Math.min(sel * rowH - 2 * rowH, Math.max(0, themes.length * rowH + (expH - rowH) * cardMix - viewH)))

    function lerp(a, b, t) { return a + (b - a) * t; }

    function previewFor(t) {
        let u = t.wallpaper || t.preview || t.image || root.walls[t.slug] || "";
        if (!u)
            return "";
        u = String(u);
        if (u.indexOf("~/") === 0)
            u = Quickshell.env("HOME") + u.substring(1);
        return u.indexOf("/") === 0 ? "file://" + u : u;
    }

    function takeInitialFocus() {
        applying = false;
        scrubbing = false;
        searchInput.clear();
        const index = root.themes.findIndex(theme => theme.slug === Theme.slug);
        root.currentIndex = Math.max(0, index);
        selSpring.snap(root.currentIndex);
        searchInput.forceActiveFocus(Qt.TabFocusReason);
    }

    function move(offset) {
        if (root.themes.length === 0)
            return;
        root.currentIndex = Math.max(0, Math.min(root.themes.length - 1, root.currentIndex + offset));
    }

    function activate(index) {
        if (root.applying)
            return;
        const theme = root.themes[index];
        if (!theme)
            return;
        root.frozenThemes = root.liveThemes;
        root.applying = true;
        AppearanceState.applyTheme(theme.slug);
        closeTimer.restart();
    }

    function handleKey(event) {
        const ctrl = (event.modifiers & Qt.ControlModifier);
        if (event.key === Qt.Key_Up || (ctrl && (event.key === Qt.Key_K || event.key === Qt.Key_P))) {
            root.move(-1);
            event.accepted = true;
        } else if (event.key === Qt.Key_Down || (ctrl && (event.key === Qt.Key_J || event.key === Qt.Key_N))) {
            root.move(1);
            event.accepted = true;
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.activate(root.currentIndex);
            event.accepted = true;
        }
    }

    implicitWidth: Math.round(425 * ui)
    implicitHeight: Math.round(listY + viewH + 4 * ui + 3 * ui)

    Keys.onPressed: event => root.handleKey(event)

    onVisibleChanged: {
        if (visible)
            Qt.callLater(() => searchInput.forceActiveFocus(Qt.TabFocusReason));
    }

    // Handler, not a binding, so snap() can never break it
    onCurrentIndexChanged: selSpring.target = root.currentIndex

    Timer {
        id: closeTimer
        interval: root.applyDelay
        onTriggered: {
            if (root.autoClose)
                ShellState.close();
            else
                root.applying = false;
        }
    }

    // First wallpaper per theme folder: ~/Pictures/Wallpapers/<theme-slug>/
    Process {
        id: wallScan
        command: ["bash", Quickshell.env("HOME") + "/.config/quickshell/dotarch/scripts/theme-walls.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                const m = {};
                text.split("\n").forEach(line => {
                    const i = line.indexOf("\t");
                    if (i > 0)
                        m[line.substring(0, i)] = line.substring(i + 1).trim();
                });
                root.walls = m;
            }
        }
    }

    Component.onCompleted: wallScan.running = true

    Connections {
        target: ShellState

        function onPanelChanged() {
            if (ShellState.panel === "theme") {
                AppearanceState.refreshThemes();
                wallScan.running = true;
            }
        }
    }

    // Measured from the recording: ~150ms to settle, no overshoot
    Spring {
        id: selSpring
        omega: 30
        zeta: 1.0
    }

    Item {
        id: content
        anchors.fill: parent
        opacity: 1

        Behavior on opacity {
            NumberAnimation {
                duration: root.applying ? 120 : 140
                easing.type: Easing.OutCubic
            }
        }

        // Search row (same look as the launcher): icon, large text, divider underneath
        Item {
            id: searchRow
            x: Math.round(10 * root.ui)
            y: root.padTop
            width: parent.width - 2 * Math.round(10 * root.ui)
            height: root.searchH

            ShellText {
                id: searchIcon
                x: Math.round(18 * root.ui) - width / 2
                y: Math.round(searchInput.y + searchInput.baselineOffset - 0.32 * searchInput.font.pixelSize - height / 2)
                text: "\uDB80\uDF49"
                font.family: Theme.iconFontFamily
                font.pixelSize: Math.round(13 * root.ui)
                color: Theme.muted
            }

            TextInput {
                id: searchInput
                anchors.left: parent.left
                anchors.leftMargin: Math.round(36 * root.ui)
                anchors.right: counter.left
                anchors.rightMargin: Math.round(12 * root.ui)
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                color: Theme.foreground
                font.family: Theme.fontFamily
                font.pixelSize: Math.round(12 * root.ui)
                verticalAlignment: TextInput.AlignVCenter
                clip: true
                selectByMouse: true
                onTextChanged: {
                    root.currentIndex = 0;
                    selSpring.snap(0);
                }

                Keys.onPressed: event => root.handleKey(event)

                ShellText {
                    y: Math.round(searchInput.baselineOffset - baselineOffset)
                    visible: !parent.text
                    text: "Search themes..."
                    color: Theme.mutedDark
                    font.pixelSize: Math.round(12 * root.ui)
                }
            }

            ShellText {
                id: counter
                anchors.right: parent.right
                anchors.rightMargin: Math.round(7 * root.ui)
                y: Math.round(searchInput.y + searchInput.baselineOffset - baselineOffset)
                text: root.themes.length === 0 ? "0/0" : (root.currentIndex + 1) + "/" + root.themes.length
                color: Qt.alpha(Theme.shellForeground, 0.4)
                font.pixelSize: Math.round(8 * root.ui)
            }
        }

        // Divider, same width as the cards
        Rectangle {
            x: Math.round(10 * root.ui)
            y: root.dividerY
            width: parent.width - 2 * Math.round(10 * root.ui)
            height: 1
            color: Theme.bg1
        }

        // List viewport
        Item {
            id: viewport
            x: 0
            y: root.listY
            width: parent.width
            height: root.viewH + 4 * root.ui
            clip: true

            WheelHandler {
                target: null
                onWheel: event => {
                    root.wheelAccum += event.angleDelta.y !== 0 ? event.angleDelta.y : event.angleDelta.x;
                    if (Math.abs(root.wheelAccum) >= 90) {
                        root.move(root.wheelAccum > 0 ? -1 : 1);
                        root.wheelAccum = 0;
                    }
                    event.accepted = true;
                }
            }

            Repeater {
                model: root.themes

                delegate: Item {
                    id: row

                    required property int index
                    required property var modelData

                    readonly property var c: modelData.colors
                    readonly property bool isCurrent: modelData.slug === Theme.slug
                    readonly property bool picked: index === root.currentIndex
                    // 1 when selected, 0 when one row away: drives the whole morph
                    readonly property real e: Math.max(0, Math.min(1, 1 - Math.abs(index - root.sel))) * root.cardMix
                    // measured: theme bg + 4% white, flat
                    readonly property color surf: Qt.tint(c.bg0, Qt.rgba(1, 1, 1, 0.04))
                    readonly property real dotD: root.lerp(5.5, 8, e) * root.ui
                    readonly property real dotS: root.lerp(2.5, 4, e) * root.ui
                    readonly property real dotsWCompact: 6 * 5.5 * root.ui + 5 * 2.5 * root.ui

                    // Only the row the list lands on loads its image, and it stays cached.
                    // Rows that scroll past during a held key never trigger a decode.
                    readonly property bool want: picked && !root.scrubbing
                    property string loadedSrc: ""
                    onWantChanged: {
                        if (want && loadedSrc === "")
                            loadedSrc = root.previewFor(modelData);
                    }

                    x: Math.round(10 * root.ui)
                    y: Math.round(2 * root.ui + index * root.rowH + Math.max(0, Math.min(1, index - root.sel)) * (root.expH - root.rowH) * root.cardMix - root.scrollY)
                    width: viewport.width - 2 * Math.round(10 * root.ui)
                    height: Math.round(root.rowH + e * (root.expH - root.rowH))
                    visible: y + height > 0 && y < viewport.height

                    // Selection marker while scrubbing (no card on screen)
                    Rectangle {
                        anchors.fill: parent
                        radius: 10 * root.ui
                        color: Qt.alpha(Theme.shellForeground, 0.06)
                        opacity: row.picked ? (1 - root.cardMix) : 0
                    }

                    // Hover highlight (compact rows)
                    Rectangle {
                        anchors.fill: parent
                        radius: 10 * root.ui
                        color: Qt.alpha(Theme.shellForeground, 0.06)
                        opacity: rowMouse.containsMouse ? (1 - row.e) : 0
                        Behavior on opacity { NumberAnimation { duration: 120 } }
                    }

                    // Selected card: flat theme surface + wallpaper preview
                    ClippingRectangle {
                        id: card
                        anchors.fill: parent
                        radius: Math.round(14 * root.ui)
                        color: row.surf
                        opacity: Math.min(1, row.e * 1.8)

                        Item {
                            id: preview
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: parent.width * 0.5
                            // time based: gone within a frame or two on the old row,
                            // quick fade-in on the new one
                            opacity: row.want ? 1 : 0
                            Behavior on opacity {
                                NumberAnimation {
                                    duration: row.want ? 140 : 45
                                    easing.type: Easing.OutCubic
                                }
                            }

                            Rectangle {
                                anchors.fill: parent
                                gradient: Gradient {
                                    orientation: Gradient.Horizontal
                                    GradientStop { position: 0.0; color: Qt.alpha(row.c.primary, 0) }
                                    GradientStop { position: 1.0; color: Qt.alpha(row.c.primary, 0.30) }
                                }
                            }

                            Image {
                                id: img
                                anchors.fill: parent
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                cache: true
                                sourceSize.width: 560
                                source: row.loadedSrc
                                opacity: status === Image.Ready ? 1 : 0
                                Behavior on opacity { NumberAnimation { duration: 140 } }
                            }

                            // Blend the image into the card on its left side
                            Rectangle {
                                anchors.fill: parent
                                gradient: Gradient {
                                    orientation: Gradient.Horizontal
                                    GradientStop { position: 0.0; color: row.surf }
                                    GradientStop { position: 0.55; color: Qt.alpha(row.surf, 0) }
                                }
                            }
                        }
                    }

                    // Icon tile (compact only)
                    Rectangle {
                        x: 8.5 * root.ui
                        y: root.rowH / 2 - height / 2
                        width: 23 * root.ui
                        height: 23 * root.ui
                        radius: Math.round(7 * root.ui)
                        color: row.surf
                        opacity: Math.max(0, 1 - row.e * 2.2)
                        scale: 1 - 0.2 * row.e

                        Rectangle {
                            anchors.centerIn: parent
                            width: 10 * root.ui
                            height: 10 * root.ui
                            radius: width / 2
                            color: row.c.primary
                        }
                    }

                    // Applied marker (compact only)
                    Rectangle {
                        visible: row.isCurrent
                        x: 50 * root.ui
                        y: root.rowH / 2 - height / 2
                        width: 4 * root.ui
                        height: 4 * root.ui
                        radius: width / 2
                        color: row.c.primary
                        opacity: Math.max(0, 1 - row.e * 2.5)
                    }

                    // Name: two fixed-size copies crossfade while sliding, so there are
                    // no font-size steps and each one is crisp when it is the one at rest
                    ShellText {
                        text: row.modelData.name
                        font.pixelSize: Math.round(10.5 * root.ui)
                        font.weight: Font.DemiBold
                        color: Qt.alpha(Theme.shellForeground, 0.72)
                        transformOrigin: Item.Left
                        scale: root.lerp(1, 14 / 10.5, row.e)
                        opacity: Math.max(0, Math.min(1, (0.7 - row.e) / 0.5))
                        visible: opacity > 0
                        x: Math.round(root.lerp(50 * root.ui + (row.isCurrent ? 9 * root.ui : 0), 12 * root.ui, row.e))
                        y: Math.round(root.lerp(root.rowH / 2, 25 * root.ui, row.e) - height / 2)
                    }

                    ShellText {
                        text: row.modelData.name
                        font.pixelSize: Math.round(14 * root.ui)
                        font.weight: Font.DemiBold
                        color: row.c.foreground
                        transformOrigin: Item.Left
                        scale: root.lerp(10.5 / 14, 1, row.e)
                        opacity: Math.max(0, Math.min(1, (row.e - 0.3) / 0.5))
                        visible: opacity > 0
                        x: Math.round(root.lerp(50 * root.ui + (row.isCurrent ? 9 * root.ui : 0), 12 * root.ui, row.e))
                        y: Math.round(root.lerp(root.rowH / 2, 25 * root.ui, row.e) - height / 2)
                    }

                    // Palette dots: slide from the right edge to under the name
                    Row {
                        spacing: row.dotS
                        x: root.lerp(row.width - 7 * root.ui - row.dotsWCompact, 12 * root.ui, row.e)
                        y: root.lerp(root.rowH / 2, 46.5 * root.ui, row.e) - row.dotD / 2

                        Repeater {
                            model: [row.c.red, row.c.green, row.c.yellow, row.c.blue, row.c.purple, row.c.aqua]

                            Rectangle {
                                required property var modelData
                                width: row.dotD
                                height: row.dotD
                                radius: width / 2
                                color: modelData || "#888888"
                            }
                        }
                    }

                    MouseArea {
                        id: rowMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.currentIndex === row.index)
                                root.activate(row.index);
                            else
                                root.currentIndex = row.index;
                        }
                    }
                }
            }

            ShellText {
                anchors.centerIn: parent
                visible: root.themes.length === 0
                text: "No themes found"
                color: Theme.mutedDark
                font.pixelSize: Math.round(10.5 * root.ui)
            }
        }
    }
}
