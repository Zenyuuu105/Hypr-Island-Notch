pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "components"
import "ui" as Ui
import "ui/Singletons"

// Shell Settings, in the Ryoku-Hub look. The page definitions, search, presets,
// preview, fonts and NotchSettings wiring are the originals; only the rendering
// changed (grouped rail + cards in balanced columns).
FloatingWindow {
    id: win
    title: "Shell Settings"
    visible: false
    color: Tokens.paper
    width: 1280
    height: 800
    implicitWidth: 1280
    implicitHeight: 800

    property bool sheetReady: false

    onVisibleChanged: {
        if (visible) {
            sheetReady = false;
            reloadTimer.restart();
        } else {
            sheetReady = false;
        }
    }

    Timer {
        id: reloadTimer
        interval: 40
        repeat: false
        onTriggered: win.sheetReady = true
    }

    readonly property var c: NotchSettings.cfg
    readonly property color accent: c.uiAccent.toString().toLowerCase() === "#0a84ff" ? Theme.primary : c.uiAccent
    property int page: 0
    property int dir: 1
    property string query: ""

    Shortcut { sequence: "Ctrl+W"; onActivated: win.visible = false }
    Shortcut { sequence: "Ctrl+K"; onActivated: searchField.grabFocus() }
    Shortcut { sequence: "Ctrl+F"; onActivated: searchField.grabFocus() }

    // ------------------------------------------------------------------
    //  Settings definition (the whole UI is generated from this)
    // ------------------------------------------------------------------
    readonly property var pages: [
        {
            name: "Presets", group: "NOTCH", preview: true, resettable: false,
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
            name: "Shape & Size", group: "NOTCH", preview: true,
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
            name: "Elements", group: "NOTCH", preview: true,
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
            name: "Clock & Date", group: "NOTCH", preview: true,
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
            name: "Animation & Hover", group: "NOTCH", preview: true,
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
            name: "Panels", group: "SHELL", preview: false,
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
            name: "OSD", group: "SHELL", preview: false,
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
            name: "Appearance", group: "SHELL", preview: true,
            sections: [
                {
                    title: "Notch",
                    items: [
                        { type: "slider", key: "backgroundOpacity", label: "Background opacity", min: 30, max: 100, unit: "%" }
                    ]
                },
                {
                    title: "Typography",
                    items: [
                        { type: "slider", key: "fontSize", label: "Shell font size", hint: "Adjust regular text throughout the shell", min: 10, max: 24, unit: "px" },
                        // fonts are listed from the system at runtime, so there is no hand-kept list
                        { type: "font", key: "bodyFontFamily", label: "Body font", hint: "Regular text throughout the shell" },
                        { type: "font", key: "displayFontFamily", label: "Display font", hint: "Clock and prominent headings" },
                        { type: "font", key: "iconFontFamily", label: "Icon font", hint: "Icons throughout the shell", filter: "nerd" }
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
            name: "Advanced", group: "SYSTEM", preview: false, resettable: false,
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
                        && (it.label + " " + (it.hint || "") + " " + pg.name).toLowerCase().indexOf(q) >= 0) {
                        const copy = Object.assign({}, it)
                        copy.pageName = pg.name
                        found.push(copy)
                    }
        return {
            name: "Search", group: "SEARCH", preview: false, resettable: false,
            empty: found.length > 0 ? "" : "No settings match \u201c" + win.query.trim() + "\u201d.",
            sections: [{ title: "Results", items: found }]
        }
    }

    readonly property var activePage: win.query.trim() !== "" ? win.searchPage() : win.pages[win.page]

    // rail groups, derived from each page's `group`
    readonly property var railGroups: {
        var out = [], idx = {}
        for (var i = 0; i < win.pages.length; i++) {
            var g = win.pages[i].group || ""
            if (idx[g] === undefined) { idx[g] = out.length; out.push({ name: g, items: [] }) }
            out[idx[g]].items.push({ index: i, name: win.pages[i].name })
        }
        return out
    }

    function go(i) {
        if (i === win.page && win.query.trim() === "") return
        win.dir = i >= win.page ? 1 : -1
        win.page = i
        searchField.clear()
        win.query = ""
        slide.from = win.dir * Tokens.s6 * 2
        slide.restart()
    }

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

    // fonts come from the system; an item may narrow them with `filter`
    property var pickItem: null
    function fontOptions(it) {
        var all = Qt.fontFamilies()
        if (!it || !it.filter) return all
        return all.filter(function (f) { return f.toLowerCase().indexOf(it.filter) >= 0 })
    }
    function openFontPicker(it) {
        win.pickItem = it
        fontPicker.title = it.label
        fontPicker.options = win.fontOptions(it)
        fontPicker.current = String(win.c[it.key] || "")
        fontPicker.open()
    }

    // ------------------------------------------------------------------
    //  UI
    // ------------------------------------------------------------------
    Rectangle {
        id: hub
        anchors.fill: parent
        color: Tokens.paper
        focus: true
        Keys.onEscapePressed: win.visible = false

        // ── rail ────────────────────────────────────────────────────────
        Item {
            id: rail
            anchors { left: parent.left; top: parent.top; bottom: bar.top }
            width: Tokens.railW

            Rectangle { anchors.right: parent.right; width: 1; height: parent.height; color: Tokens.line }

            Rectangle {
                id: mast
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: Tokens.s5 }
                height: 64
                color: "transparent"
                radius: Tokens.radius
                border.width: Tokens.border
                border.color: Tokens.line
                Column {
                    anchors { left: parent.left; leftMargin: Tokens.s4; verticalCenter: parent.verticalCenter }
                    spacing: 1
                    Text {
                        text: "DOTARCH"
                        color: Tokens.ink
                        font.family: Tokens.ui
                        font.pixelSize: 14
                        font.weight: Font.Medium
                        font.letterSpacing: 2.4
                    }
                    Text {
                        text: "SHELL SETTINGS"
                        color: Tokens.inkMuted
                        font.family: Tokens.mono
                        font.pixelSize: 10
                        font.letterSpacing: 1.4
                    }
                }
            }

            Ui.Field {
                id: searchField
                anchors { left: parent.left; right: parent.right; top: mast.bottom; margins: Tokens.s5 }
                anchors.topMargin: Tokens.s4
                placeholder: "Search settings\u2026"
                onEdited: (t) => win.query = t
                onEscaped: {
                    if (searchField.text !== "") { searchField.clear(); win.query = "" }
                    else win.visible = false
                }
            }

            Flickable {
                anchors { left: parent.left; right: parent.right; top: searchField.bottom; bottom: parent.bottom }
                anchors.margins: Tokens.s5
                anchors.topMargin: Tokens.s3
                contentHeight: nav.height
                clip: true

                Column {
                    id: nav
                    width: parent.width
                    spacing: 0

                    Repeater {
                        model: win.railGroups
                        Column {
                            id: grp
                            required property var modelData
                            required property int index
                            width: nav.width
                            spacing: 0

                            Item {
                                width: parent.width
                                height: 34
                                visible: grp.modelData.name !== ""
                                Row {
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: Tokens.s2
                                    Text {
                                        text: (grp.index + 1 < 10 ? "0" : "") + (grp.index + 1)
                                        color: Tokens.inkFaint
                                        font.family: Tokens.mono
                                        font.pixelSize: 9
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    Text {
                                        text: grp.modelData.name
                                        color: Tokens.inkFaint
                                        font.family: Tokens.ui
                                        font.pixelSize: 9
                                        font.weight: Font.Medium
                                        font.letterSpacing: 2
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    Rectangle {
                                        width: Math.max(0, nav.width - 110)
                                        height: 1
                                        color: Tokens.lineSoft
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }
                            }

                            Repeater {
                                model: grp.modelData.items
                                Item {
                                    id: navItem
                                    required property var modelData
                                    readonly property bool sel: win.page === modelData.index && win.query.trim() === ""
                                    width: nav.width
                                    height: 36

                                    Rectangle {
                                        anchors.fill: parent
                                        anchors.topMargin: 1
                                        anchors.bottomMargin: 1
                                        radius: Tokens.radius
                                        color: navItem.sel ? Tokens.bone : (nh.hovered ? Tokens.tint10 : "transparent")
                                        Behavior on color { ColorAnimation { duration: Tokens.snap } }
                                    }
                                    Row {
                                        x: Tokens.s3
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: Tokens.s2
                                        Text {
                                            visible: navItem.sel
                                            text: "//"
                                            color: Tokens.inkOnBoneDim
                                            font.family: Tokens.mono
                                            font.pixelSize: 11
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                        Text {
                                            text: navItem.modelData.name
                                            color: navItem.sel ? Tokens.inkOnBone : Tokens.inkDim
                                            font.family: Tokens.ui
                                            font.pixelSize: 14
                                            anchors.verticalCenter: parent.verticalCenter
                                            Behavior on color { ColorAnimation { duration: Tokens.snap } }
                                        }
                                    }
                                    HoverHandler { id: nh; cursorShape: Qt.PointingHandCursor }
                                    TapHandler { onTapped: win.go(navItem.modelData.index) }
                                }
                            }
                        }
                    }
                }
            }
        }

        // ── page host ───────────────────────────────────────────────────
        Item {
            id: host
            anchors {
                left: rail.right; right: parent.right
                top: parent.top; bottom: bar.top
                leftMargin: Tokens.s6; rightMargin: Tokens.s6
                topMargin: Tokens.s5; bottomMargin: Tokens.s3
            }
            clip: true

            Loader {
                id: sheetLoader
                anchors.fill: parent
                active: win.sheetReady
                sourceComponent: Ui.SchemaSheet {
                    width: host.width
                    height: host.height
                    page: win.activePage
                    cfg: win.c
                    onEdited: (key, value) => win.c[key] = value
                    onActivated: (item) => win.runAction(item)
                    onFontPickRequested: (item) => win.openFontPicker(item)

                    // the live miniature of the notch, riding above the cards
                    Item {
                        visible: win.activePage.preview === true
                        width: parent.width
                        height: 190
                        NotchPreview {
                            anchors.fill: parent
                            cfg: win.c
                            accent: win.accent
                            shellBg: Theme.shellBackground
                            fg: Theme.shellForeground
                            muted: Theme.muted
                            iconFont: Theme.iconFontFamily
                        }
                        Rectangle {
                            anchors.fill: parent
                            color: "transparent"
                            radius: Tokens.radius
                            border.width: Tokens.border
                            border.color: Tokens.line
                        }
                    }
                }
            }

            NumberAnimation {
                id: slide
                target: sheetLoader.item
                property: "x"
                to: 0
                duration: Tokens.move
                easing.type: Tokens.ease
            }
        }

        // ── footer ──────────────────────────────────────────────────────
        Item {
            id: bar
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            height: 60

            Rectangle { anchors.top: parent.top; width: parent.width; height: 1; color: Tokens.line }

            Row {
                anchors { left: parent.left; leftMargin: Tokens.s5; verticalCenter: parent.verticalCenter }
                spacing: Tokens.s3
                Text {
                    text: "///"
                    color: Tokens.inkFaint
                    font.family: Tokens.mono
                    font.pixelSize: 10
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: "SAVED \u00b7 LIVE ON YOUR SHELL"
                    color: Tokens.inkDim
                    font.family: Tokens.ui
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    font.letterSpacing: 1.6
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
            Ui.Btn {
                visible: win.query.trim() === "" && win.activePage.resettable !== false
                anchors { right: parent.right; rightMargin: Tokens.s6; verticalCenter: parent.verticalCenter }
                text: "RESET THIS PAGE"
                onAct: NotchSettings.resetKeys(win.pageKeys(win.activePage))
            }
        }

        // ── font picker overlay ─────────────────────────────────────────
        Ui.Picker {
            id: fontPicker
            anchors.fill: parent
            onChose: (name) => { if (win.pickItem) win.c[win.pickItem.key] = name }
        }
    }
}