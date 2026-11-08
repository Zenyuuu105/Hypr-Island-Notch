import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import "components"

FloatingWindow {
    id: win
    title: "Shell Settings"
    visible: false
    color: Theme.shellBackground
    implicitWidth: 1060
    implicitHeight: 760

    readonly property var c: NotchSettings.cfg
    readonly property color accent: c.uiAccent.toString().toLowerCase() === "#0a84ff" ? Theme.primary : c.uiAccent
    property int page: 0
    property string query: ""

    onPageChanged: flick.contentY = 0
    onQueryChanged: flick.contentY = 0

    Shortcut { sequence: "Ctrl+W"; onActivated: win.visible = false }

    // ------------------------------------------------------------------
    //  Settings definition (everything in the UI is generated from this)
    // ------------------------------------------------------------------
    readonly property var pages: [
        {
            name: "Presets", icon: "star-four", color: Theme.orange, preview: true, resettable: false,
            sections: [
                {
                    title: "Layouts",
                    footer: "A preset changes shape, size and elements together. Fine-tune anything afterwards.",
                    items: [
                        { type: "button", label: "Classic notch", hint: "Attached to the top edge with flared corners", text: "Apply", action: "preset",
                          values: { shape: "notch", collapsedWidth: 0, collapsedHeight: 32, expandedWidth: 0, expandedHeight: 82, cornerRadius: 20, notchFlare: 16, offsetX: 0, backgroundOpacity: 100,
                                    showWorkspaces: true, showClock: true, showDate: false, showWifi: true, showBattery: true, showBluetooth: false, showVolume: false, showMedia: false, showBell: false,
                                    showHoverClock: true, showHoverDate: true, showHoverWorkspaces: true, showHoverStatus: true, showHoverMedia: true } },
                        { type: "button", label: "Dynamic Island", hint: "A floating pill with rounded corners", text: "Apply", action: "preset",
                          values: { shape: "island", islandTopMargin: 10, collapsedWidth: 200, collapsedHeight: 36, expandedWidth: 460, expandedHeight: 96, cornerRadius: 22, offsetX: 0,
                                    showWorkspaces: true, showClock: true, showDate: false, showWifi: true, showBattery: true, showBluetooth: false, showVolume: false, showMedia: false, showBell: false,
                                    showHoverClock: true, showHoverDate: true, showHoverWorkspaces: true, showHoverStatus: true, showHoverMedia: true } },
                        { type: "button", label: "Minimal", hint: "Small pill, just the clock", text: "Apply", action: "preset",
                          values: { shape: "notch", collapsedWidth: 120, collapsedHeight: 28, expandedWidth: 340, expandedHeight: 70, cornerRadius: 16, notchFlare: 12,
                                    showWorkspaces: false, showClock: true, showDate: false, showWifi: false, showBattery: false, showBluetooth: false, showVolume: false, showMedia: false, showBell: false,
                                    showHoverWorkspaces: false, showHoverStatus: false, showHoverMedia: false } },
                        { type: "button", label: "Informative", hint: "Every element switched on", text: "Apply", action: "preset",
                          values: { shape: "notch", collapsedWidth: 0, collapsedHeight: 34, expandedWidth: 560, expandedHeight: 96, cornerRadius: 22, notchFlare: 16,
                                    showWorkspaces: true, showClock: true, showDate: true, showWifi: true, showBattery: true, showBluetooth: true, showVolume: true, showMedia: true, showBell: true,
                                    showHoverClock: true, showHoverDate: true, showHoverWorkspaces: true, showHoverStatus: true, showHoverMedia: true } }
                    ]
                },
                {
                    title: "Backup",
                    items: [
                        { type: "button", label: "Back up settings", hint: "Copies settings.json to settings.backup.json", text: "Back Up", action: "backup" },
                        { type: "button", label: "Restore backup", hint: "Replaces current settings with the last backup", text: "Restore", action: "restore" }
                    ]
                }
            ]
        },
        {
            name: "Shape & Size", icon: "bounding-box", color: Theme.blue, preview: true,
            sections: [
                {
                    title: "Style",
                    items: [
                        { type: "choice", key: "shape", label: "Shape", hint: "Notch hugs the screen edge; island floats below it",
                          options: [{ key: "notch", text: "Notch" }, { key: "island", text: "Dynamic Island" }] }
                    ]
                },
                {
                    title: "Resting size",
                    items: [
                        { type: "slider", key: "collapsedWidth", label: "Width", min: 0, max: 400, unit: "px", zero: "Auto" },
                        { type: "slider", key: "collapsedHeight", label: "Height", min: 20, max: 80, unit: "px" }
                    ]
                },
                {
                    title: "Hover size",
                    items: [
                        { type: "slider", key: "expandedWidth", label: "Width", min: 0, max: 1000, unit: "px", zero: "Auto" },
                        { type: "slider", key: "expandedHeight", label: "Height", min: 50, max: 300, unit: "px" }
                    ]
                },
                {
                    title: "Geometry",
                    items: [
                        { type: "slider", key: "cornerRadius", label: "Corner radius", min: 0, max: 40, unit: "px" },
                        { type: "slider", key: "notchFlare", label: "Flare", hint: "Curved shoulders where the notch meets the edge", min: 0, max: 40, unit: "px", when: { k: "shape", v: "notch" } },
                        { type: "slider", key: "islandTopMargin", label: "Gap from top edge", min: 0, max: 40, unit: "px", when: { k: "shape", v: "island" } },
                        { type: "slider", key: "islandWindowGap", label: "Gap from bottom edge", hint: "Space between the island and the active window below it", min: 0, max: 60, unit: "px", when: { k: "shape", v: "island" } },
                        { type: "slider", key: "notchWindowGap", label: "Gap from bottom edge", hint: "Space between the notch and the active window below it", min: 0, max: 60, unit: "px", when: { k: "shape", v: "notch" } },
                        { type: "slider", key: "offsetX", label: "Horizontal offset", hint: "Shift left or right of centre", min: -600, max: 600, step: 5, unit: "px" }
                    ]
                }
            ]
        },
        {
            name: "Elements", icon: "squares-four", color: Theme.purple, preview: true,
            sections: [
                {
                    title: "Resting pill",
                    footer: "Choose what the notch shows when idle.",
                    items: [
                        { type: "toggle", key: "showWorkspaces", label: "Workspace indicator" },
                        { type: "toggle", key: "showClock", label: "Clock" },
                        { type: "toggle", key: "showDate", label: "Date" },
                        { type: "toggle", key: "showMedia", label: "Now-playing icon", hint: "Only while a media player is running" },
                        { type: "toggle", key: "showVolume", label: "Volume icon" },
                        { type: "toggle", key: "showBluetooth", label: "Bluetooth icon" },
                        { type: "toggle", key: "showWifi", label: "Wi-Fi" },
                        { type: "toggle", key: "showBell", label: "Notification bell" },
                        { type: "toggle", key: "showBattery", label: "Battery" }
                    ]
                },
                {
                    title: "Hover view",
                    items: [
                        { type: "toggle", key: "showHoverClock", label: "Clock" },
                        { type: "toggle", key: "showHoverDate", label: "Date" },
                        { type: "toggle", key: "showHoverWorkspaces", label: "Workspace dots" },
                        { type: "toggle", key: "showHoverStatus", label: "Bell, Wi-Fi and battery" },
                        { type: "toggle", key: "showHoverMedia", label: "Media card" }
                    ]
                }
            ]
        },
        {
            name: "Clock & Date", icon: "clock", color: Theme.green, preview: true,
            sections: [
                {
                    title: "Time",
                    items: [
                        { type: "toggle", key: "clock24h", label: "24-hour clock" },
                        { type: "toggle", key: "showSeconds", label: "Show seconds" },
                        { type: "slider", key: "clockSize", label: "Resting clock size", min: 10, max: 26, unit: "px" },
                        { type: "slider", key: "hoverClockSize", label: "Hover clock size", min: 10, max: 30, unit: "px" }
                    ]
                },
                {
                    title: "Date format",
                    items: [
                        { type: "choice", key: "dateFormat", label: "Format",
                          options: [{ key: "ddd, MMM d", text: "Fri, Oct 30" }, { key: "d MMM", text: "30 Oct" },
                                    { key: "dddd, d MMMM", text: "Friday, 30 October" }, { key: "M/d", text: "10/30" }] }
                    ]
                }
            ]
        },
        {
            name: "Panels", icon: "layout", color: Theme.red, preview: false,
            sections: [
                {
                    title: "Panel size",
                    footer: "Applies to the control center, launcher, clipboard, wallpaper, theme and other panels. Auto keeps each panel's own size.",
                    items: [
                        { type: "slider", key: "panelWidth", label: "Width", min: 0, max: 800, unit: "px", zero: "Auto" },
                        { type: "slider", key: "panelHeight", label: "Height", min: 0, max: 900, unit: "px", zero: "Auto" },
                        { type: "slider", key: "panelRadius", label: "Corner radius", min: 0, max: 40, unit: "px" }
                    ]
                }
            ]
        },
        {
            name: "Animation & Hover", icon: "lightning", color: Theme.aqua, preview: true,
            sections: [
                {
                    title: "Hover behaviour",
                    items: [
                        { type: "toggle", key: "expandOnHover", label: "Expand on hover", hint: "When off, the notch opens only from keybinds or clicks" },
                        { type: "slider", key: "hoverDelay", label: "Open delay", min: 0, max: 600, step: 10, unit: "ms" },
                        { type: "slider", key: "hoverExitDelay", label: "Close delay", min: 0, max: 1000, step: 10, unit: "ms" }
                    ]
                },
                {
                    title: "Animation",
                    items: [
                        { type: "toggle", key: "animationsEnabled", label: "Animations" },
                        { type: "slider", key: "animationDuration", label: "Duration", min: 80, max: 600, step: 10, unit: "ms" }
                    ]
                }
            ]
        },
        {
            name: "OSD", icon: "speaker-high", color: Theme.yellow, preview: false,
            sections: [
                {
                    title: "On-screen indicators",
                    footer: "Brief volume and brightness bars shown inside the notch.",
                    items: [
                        { type: "toggle", key: "osdVolume", label: "Volume indicator" },
                        { type: "toggle", key: "osdBrightness", label: "Brightness indicator" },
                        { type: "slider", key: "osdDuration", label: "Display time", min: 500, max: 4000, step: 100, unit: "ms" }
                    ]
                }
            ]
        },
        {
            name: "Appearance", icon: "palette", color: Theme.primary, preview: true,
            sections: [
                {
                    title: "Notch",
                    items: [
                        { type: "slider", key: "backgroundOpacity", label: "Background opacity", min: 30, max: 100, unit: "%" }
                    ]
                },
                {
                    title: "Settings app",
                    items: [
                        { type: "swatch", key: "uiAccent", label: "Accent colour",
                          swatches: ["#0a84ff", "#bf5af2", "#ff375f", "#ff9f0a", "#30d158", "#64d2ff", "#98989d"] }
                    ]
                }
            ]
        },
        {
            name: "Advanced", icon: "gear-six", color: Theme.muted, preview: false, resettable: false,
            sections: [
                {
                    title: "Shell",
                    items: [
                        { type: "button", label: "Restart shell", hint: "Reloads Quickshell completely", text: "Restart", action: "restart" },
                        { type: "button", label: "Open config folder", text: "Open", action: "openFolder" },
                        { type: "button", label: "Open settings.json", text: "Open", action: "openFile" }
                    ]
                },
                {
                    title: "Reset",
                    footer: "Resets every notch setting to the defaults that match your original look.",
                    items: [
                        { type: "button", label: "Reset all settings", text: "Reset Everything", action: "resetAll", danger: true }
                    ]
                }
            ]
        }
    ]

    // ------------------------------------------------------------------
    //  Logic
    // ------------------------------------------------------------------
    function shown(it) {
        if (!it.when) return true
        return win.c[it.when.k] === it.when.v
    }

    function visibleItems(sec) {
        return sec.items.filter(function (it) { return win.shown(it) })
    }

    function pageKeys(pg) {
        const keys = []
        for (const s of pg.sections)
            for (const it of s.items)
                if (it.key) keys.push(it.key)
        return keys
    }

    function searchPage() {
        const q = win.query.trim().toLowerCase()
        const found = []
        for (const pg of win.pages)
            for (const s of pg.sections)
                for (const it of s.items)
                    if (it.key && win.shown(it)
                        && (it.label + " " + (it.hint || "") + " " + pg.name).toLowerCase().indexOf(q) >= 0)
                        found.push(it)
        return {
            name: "Search", preview: false, resettable: false,
            sections: [{
                title: found.length > 0 ? "Results" : "",
                footer: found.length > 0 ? "" : "No settings match “" + win.query.trim() + "”.",
                items: found
            }]
        }
    }

    readonly property var activePage: win.query.trim() !== "" ? win.searchPage() : win.pages[win.page]

    function runAction(it) {
        const home = Quickshell.env("HOME")
        if (it.action === "preset") NotchSettings.apply(it.values)
        else if (it.action === "resetAll") NotchSettings.reset()
        else if (it.action === "backup") NotchSettings.backup()
        else if (it.action === "restore") NotchSettings.restore()
        else if (it.action === "openFolder") Quickshell.execDetached(["xdg-open", home + "/.config/quickshell/dotarch"])
        else if (it.action === "openFile") Quickshell.execDetached(["xdg-open", home + "/.config/quickshell/dotarch/settings.json"])
        else if (it.action === "restart")
            Quickshell.execDetached(["sh", "-c", "pkill -x qs; pkill -x quickshell; sleep 0.5; setsid -f qs --no-duplicate --path ~/.config/quickshell/dotarch >/dev/null 2>&1"])
    }

    // ------------------------------------------------------------------
    //  UI
    // ------------------------------------------------------------------
    RowLayout {
        anchors.fill: parent
        spacing: 0

        // ---------------- Sidebar ----------------
        Rectangle {
            Layout.preferredWidth: 250
            Layout.fillHeight: true
            color: Theme.shellBackground

            Rectangle { anchors.right: parent.right; width: 1; height: parent.height; color: Theme.cardBorder }

            Row {
                x: 18; y: 18; spacing: 8
                Rectangle {
                    width: 12; height: 12; radius: 6; color: "#ff5f57"
                    MouseArea { anchors.fill: parent; anchors.margins: -3; onClicked: win.visible = false }
                }
                Rectangle { width: 12; height: 12; radius: 6; color: "#4a4a4c" }
                Rectangle { width: 12; height: 12; radius: 6; color: "#4a4a4c" }
            }

            Rectangle {
                x: 14; y: 50
                width: parent.width - 28; height: 30
                radius: 8; color: Qt.alpha(Theme.shellForeground, 0.06)
                TextInput {
                    id: searchField
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    verticalAlignment: TextInput.AlignVCenter
                    color: Theme.foreground
                    font.pixelSize: 13
                    clip: true
                    selectByMouse: true
                    onTextChanged: win.query = text
                    Keys.onEscapePressed: { if (text !== "") text = ""; else win.visible = false }
                    Text {
                        visible: searchField.text === ""
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Search"
                        color: Theme.muted
                        font.pixelSize: 13
                    }
                }
            }

            Column {
                x: 10; y: 94
                width: parent.width - 20
                spacing: 2
                Repeater {
                    model: win.pages
                    delegate: Rectangle {
                        id: navItem
                        required property var modelData
                        required property int index
                        readonly property bool selected: win.page === index && win.query.trim() === ""
                        width: parent.width; height: 36; radius: 8
                        color: selected ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.16) : (navMouse.containsMouse ? Qt.alpha(Theme.shellForeground, 0.05) : "transparent")

                        Rectangle {
                            id: badge
                            x: 8
                            anchors.verticalCenter: parent.verticalCenter
                            width: 24; height: 24; radius: 7
                            color: navItem.selected ? navItem.modelData.color : Qt.rgba(navItem.modelData.color.r, navItem.modelData.color.g, navItem.modelData.color.b, 0.16)
                            Behavior on color { ColorAnimation { duration: 150 } }
                            Item {
                                anchors.centerIn: parent
                                width: 16; height: 16
                                Image {
                                    id: glyph
                                    anchors.fill: parent
                                    source: Qt.resolvedUrl("icons/" + navItem.modelData.icon + ".svg")
                                    sourceSize: Qt.size(64, 64)
                                    mipmap: true
                                    smooth: true
                                    visible: false
                                }
                                MultiEffect {
                                    anchors.fill: glyph
                                    source: glyph
                                    colorization: 1.0
                                    colorizationColor: navItem.selected ? Theme.shellBackground : navItem.modelData.color
                                }
                            }
                        }
                        Text {
                            anchors.left: badge.right
                            anchors.leftMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            text: navItem.modelData.name
                            color: navItem.selected ? Theme.foreground : Qt.alpha(Theme.shellForeground, 0.72)
                            font.pixelSize: 13
                            font.weight: navItem.selected ? Font.Medium : Font.Normal
                        }
                        MouseArea {
                            id: navMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: { searchField.text = ""; win.page = navItem.index }
                        }
                    }
                }
            }
        }

        // ---------------- Content ----------------
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 68
                color: Theme.shellBackground
                Text {
                    x: 28
                    anchors.verticalCenter: parent.verticalCenter
                    text: win.activePage.name
                    color: Theme.foreground
                    font.pixelSize: 24
                    font.weight: Font.DemiBold
                    font.letterSpacing: -0.3
                }
                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.cardBorder }
            }

            Flickable {
                id: flick
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                contentWidth: width
                contentHeight: body.implicitHeight + 48
                boundsBehavior: Flickable.StopAtBounds

                ColumnLayout {
                    id: body
                    x: 28; y: 22
                    width: flick.width - 56
                    spacing: 20

                    NotchPreview {
                        visible: win.activePage.preview === true
                        Layout.fillWidth: true
                        Layout.preferredHeight: 190
                        cfg: win.c
                        accent: win.accent
                        shellBg: Theme.shellBackground
                        fg: Theme.shellForeground
                        muted: Theme.muted
                        iconFont: Theme.iconFontFamily
                    }

                    Repeater {
                        model: win.activePage.sections
                        delegate: SSection {
                            id: sec
                            required property var modelData
                            Layout.fillWidth: true
                            title: modelData.title || ""
                            footer: modelData.footer || ""

                            Repeater {
                                model: win.visibleItems(sec.modelData)
                                delegate: SRow {
                                    required property var modelData
                                    required property int index
                                    Layout.fillWidth: true
                                    divider: index > 0
                                    accent: win.accent
                                    type: modelData.type
                                    label: modelData.label
                                    hint: modelData.hint || ""
                                    value: modelData.key ? win.c[modelData.key] : null
                                    from: modelData.min !== undefined ? modelData.min : 0
                                    to: modelData.max !== undefined ? modelData.max : 100
                                    step: modelData.step || 1
                                    unit: modelData.unit || ""
                                    zeroLabel: modelData.zero || ""
                                    options: modelData.options || []
                                    swatches: modelData.swatches || []
                                    buttonText: modelData.text || ""
                                    danger: modelData.danger === true
                                    onEdited: v => win.c[modelData.key] = v
                                    onActivated: win.runAction(modelData)
                                }
                            }
                        }
                    }

                    Rectangle {
                        visible: win.query.trim() === "" && win.activePage.resettable !== false
                        Layout.alignment: Qt.AlignRight
                        Layout.preferredWidth: resetText.implicitWidth + 28
                        Layout.preferredHeight: 28
                        radius: 7
                        color: Theme.bg2
                        Text { id: resetText; anchors.centerIn: parent; text: "Reset This Page"; color: Theme.foreground; font.pixelSize: 12 }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: NotchSettings.resetKeys(win.pageKeys(win.activePage))
                        }
                    }
                }
            }
        }
    }
}
