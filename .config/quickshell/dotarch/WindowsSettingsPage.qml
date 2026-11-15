import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs
import "components"

import "ui/Singletons"
Flickable {
    id: root

    Layout.fillWidth: true
    Layout.fillHeight: true
    clip: true
    contentWidth: width
    contentHeight: contentColumn.implicitHeight
    boundsBehavior: Flickable.StopAtBounds
    flickableDirection: Flickable.VerticalFlick

    property var settings: ({})
    property string status: "Loading current settings..."
    property string pendingKey: ""
    property string pendingValue: ""

    function setting(key, fallback) {
        return settings[key] === undefined ? fallback : settings[key]
    }

    function queue(key, value) {
        var next = Object.assign({}, settings)
        next[key] = value
        settings = next
        pendingKey = key
        pendingValue = String(value)
        status = "Applying changes..."
        applyTimer.restart()
    }

    Timer {
        id: applyTimer
        interval: 350
        repeat: false
        onTriggered: {
            if (applyProcess.running) {
                restart()
                return
            }
            if (root.pendingKey !== "") {
                applyProcess.exec([
                    "python3",
                    Quickshell.shellPath("scripts/window-settings.py"),
                    "set",
                    root.pendingKey,
                    root.pendingValue
                ])
            }
        }
    }

    Process {
        id: getProcess

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.settings = JSON.parse(text)
                    root.status = "Settings loaded"
                } catch (error) {
                    root.status = "Could not read current settings"
                }
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim())
                    root.status = text.trim()
            }
        }
    }

    Process {
        id: applyProcess

        onExited: (exitCode) => {
            if (exitCode === 0) {
                root.status = "Changes applied and saved"
                root.pendingKey = ""
            } else {
                root.status = "Could not apply setting — check Hyprland"
                getProcess.exec([
                    "python3",
                    Quickshell.shellPath("scripts/window-settings.py"),
                    "get"
                ])
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim())
                    root.status = text.trim()
            }
        }
    }

    Component.onCompleted: {
        getProcess.exec([
            "python3",
            Quickshell.shellPath("scripts/window-settings.py"),
            "get"
        ])
    }

    ColumnLayout {
        id: contentColumn
        width: root.width
        spacing: Tokens.s4


        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.s4

            ColumnLayout {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                spacing: Tokens.s4

                SettingCard {
                    Layout.fillWidth: true
                    title: "Spacing & shape"

                    SettingRow {
                        label: "Inner gaps"
                        desc: "Space between tiled windows"
                        value: String(root.setting("gaps_in", 7))
                        unit: "px"
                        block: true
                        divider: false

                        Slid {
                            anchors.fill: parent
                            from: 0
                            to: 50
                            value: root.setting("gaps_in", 7)
                            onModified: v => root.queue("gaps_in", v)
                        }
                    }

                    SettingRow {
                        label: "Outer gaps"
                        desc: "Space between windows and screen edges"
                        value: String(root.setting("gaps_out", 20))
                        unit: "px"
                        block: true
                        divider: true

                        Slid {
                            anchors.fill: parent
                            from: 0
                            to: 80
                            value: root.setting("gaps_out", 20)
                            onModified: v => root.queue("gaps_out", v)
                        }
                    }

                    SettingRow {
                        label: "Window rounding"
                        desc: "Corner radius of window surfaces"
                        value: String(root.setting("rounding", 20))
                        unit: "px"
                        block: true
                        divider: true

                        Slid {
                            anchors.fill: parent
                            from: 0
                            to: 40
                            value: root.setting("rounding", 20)
                            onModified: v => root.queue("rounding", v)
                        }
                    }

                    SettingRow {
                        label: "Rounding power"
                        value: String(root.setting("rounding_power", 5))
                        block: true
                        divider: true

                        Slid {
                            anchors.fill: parent
                            from: 1
                            to: 10
                            value: root.setting("rounding_power", 5)
                            onModified: v => root.queue("rounding_power", v)
                        }
                    }

                    SettingRow {
                        label: "Border thickness"
                        value: String(root.setting("border_size", 0))
                        unit: "px"
                        block: true
                        divider: true

                        Slid {
                            anchors.fill: parent
                            from: 0
                            to: 10
                            value: root.setting("border_size", 0)
                            onModified: v => root.queue("border_size", v)
                        }
                    }
                }

                SettingCard {
                    Layout.fillWidth: true
                    title: "Window layout"

                    SettingRow {
                        label: "Default tiling layout"
                        desc: "Choose how new windows are arranged"
                        block: true
                        footH: 32

                        Seg {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            options: ["dwindle", "master", "scrolling"]
                            labels: ({ dwindle: "Dwindle", master: "Master", scrolling: "Scrolling" })
                            current: root.setting("layout", "dwindle")
                            onChose: key => root.queue("layout", key)
                        }
                    }

                    SettingRow {
                        label: "Preserve split"
                        desc: "Keep the current split direction when adding windows"
                        divider: true

                        Sw {
                            anchors.fill: parent
                            on: root.setting("preserve_split", true)
                            onToggled: v => root.queue("preserve_split", v)
                        }
                    }

                    SettingRow {
                        label: "Fullscreen on one column"
                        divider: true

                        Sw {
                            anchors.fill: parent
                            on: root.setting("fullscreen_on_one_column", true)
                            onToggled: v => root.queue("fullscreen_on_one_column", v)
                        }
                    }

                    SettingRow {
                        label: "Resize on window borders"
                        divider: true

                        Sw {
                            anchors.fill: parent
                            on: root.setting("resize_on_border", false)
                            onToggled: v => root.queue("resize_on_border", v)
                        }
                    }

                    SettingRow {
                        label: "Allow screen tearing"

                        Sw {
                            anchors.fill: parent
                            on: root.setting("allow_tearing", false)
                            onToggled: v => root.queue("allow_tearing", v)
                        }
                    }
                }

                SettingCard {
                    Layout.fillWidth: true
                    title: "Window opacity"

                    SettingRow {
                        label: "Active window"
                        desc: "Opacity of the focused window"
                        value: String(root.setting("active_opacity", 100))
                        unit: "%"
                        block: true

                        Slid {
                            anchors.fill: parent
                            from: 10
                            to: 100
                            value: root.setting("active_opacity", 100)
                            onModified: v => root.queue("active_opacity", v)
                        }
                    }

                    SettingRow {
                        label: "Inactive windows"
                        desc: "Opacity of unfocused windows"
                        value: String(root.setting("inactive_opacity", 100))
                        unit: "%"
                        block: true
                        divider: true

                        Slid {
                            anchors.fill: parent
                            from: 10
                            to: 100
                            value: root.setting("inactive_opacity", 100)
                            onModified: v => root.queue("inactive_opacity", v)
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                spacing: Tokens.s4

                SettingCard {
                    Layout.fillWidth: true
                    title: "Background blur"

                    SettingRow {
                        label: "Enable blur"
                        desc: "Blur transparent window backgrounds"
                        divider: false
                        controlWidth: 54

                        Sw {
                            anchors.fill: parent
                            on: root.setting("blur_enabled", true)
                            onToggled: v => root.queue("blur_enabled", v)
                        }
                    }

                    SettingRow {
                        label: "Blur size"
                        value: String(root.setting("blur_size", 7))
                        block: true
                        divider: true

                        Slid {
                            anchors.fill: parent
                            from: 0
                            to: 20
                            value: root.setting("blur_size", 7)
                            onModified: v => root.queue("blur_size", v)
                        }
                    }

                    SettingRow {
                        label: "Blur passes"
                        value: String(root.setting("blur_passes", 3))
                        block: true
                        divider: true

                        Slid {
                            anchors.fill: parent
                            from: 0
                            to: 10
                            value: root.setting("blur_passes", 3)
                            onModified: v => root.queue("blur_passes", v)
                        }
                    }

                    SettingRow {
                        label: "Noise"
                        value: String(root.setting("blur_noise", 8))
                        block: true
                        divider: true

                        Slid {
                            anchors.fill: parent
                            from: 0
                            to: 30
                            value: root.setting("blur_noise", 8)
                            onModified: v => root.queue("blur_noise", v)
                        }
                    }

                    SettingRow {
                        label: "Contrast"
                        value: String(root.setting("blur_contrast", 150))
                        block: true
                        divider: true

                        Slid {
                            anchors.fill: parent
                            from: 50
                            to: 250
                            value: root.setting("blur_contrast", 150)
                            onModified: v => root.queue("blur_contrast", v)
                        }
                    }

                    SettingRow {
                        label: "Ignore window opacity"
                        divider: true

                        Sw {
                            anchors.fill: parent
                            on: root.setting("blur_ignore_opacity", true)
                            onToggled: v => root.queue("blur_ignore_opacity", v)
                        }
                    }

                    SettingRow {
                        label: "X-ray blur"
                        desc: "Apply blur beyond transparent regions"
                        divider: true

                        Sw {
                            anchors.fill: parent
                            on: root.setting("blur_xray", false)
                            onToggled: v => root.queue("blur_xray", v)
                        }
                    }

                    SettingRow {
                        label: "New blur optimizations"

                        Sw {
                            anchors.fill: parent
                            on: root.setting("blur_new_optimizations", true)
                            onToggled: v => root.queue("blur_new_optimizations", v)
                        }
                    }
                }

                SettingCard {
                    Layout.fillWidth: true
                    title: "Window shadows"

                    SettingRow {
                        label: "Enable shadows"

                        Sw {
                            anchors.fill: parent
                            on: root.setting("shadow_enabled", false)
                            onToggled: v => root.queue("shadow_enabled", v)
                        }
                    }

                    SettingRow {
                        label: "Shadow range"
                        value: String(root.setting("shadow_range", 20))
                        block: true
                        divider: true

                        Slid {
                            anchors.fill: parent
                            from: 0
                            to: 50
                            value: root.setting("shadow_range", 20)
                            onModified: v => root.queue("shadow_range", v)
                        }
                    }

                    SettingRow {
                        label: "Render power"
                        value: String(root.setting("shadow_render_power", 3))
                        block: true
                        divider: true

                        Slid {
                            anchors.fill: parent
                            from: 1
                            to: 5
                            value: root.setting("shadow_render_power", 3)
                            onModified: v => root.queue("shadow_render_power", v)
                        }
                    }
                }
            }
        }

            Text {
                Layout.fillWidth: true
                text: root.status
                color: Tokens.inkMuted
                font.family: Tokens.mono
                font.pixelSize: Tokens.fTiny
                font.letterSpacing: Tokens.trackLabel
                font.capitalization: Font.AllUppercase
                wrapMode: Text.WordWrap
            }
    }
}
