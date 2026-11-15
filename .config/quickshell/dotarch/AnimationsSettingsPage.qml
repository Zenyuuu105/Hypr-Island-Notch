import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs
import "ui" as RUI
import "ui/Singletons"

Flickable {
    id: root

    Layout.fillWidth: true
    Layout.fillHeight: true
    clip: true
    contentWidth: width
    contentHeight: contentColumn.y + contentColumn.implicitHeight + Tokens.s5
    boundsBehavior: Flickable.StopAtBounds
    flickableDirection: Flickable.VerticalFlick

    property var settings: ({})
    property string status: "Loading animation settings..."
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
        status = "Applying animation..."
        applyTimer.restart()
    }

    Timer {
        id: applyTimer
        interval: 350
        onTriggered: {
            if (applyProcess.running) {
                restart()
                return
            }
            if (root.pendingKey !== "") {
                applyProcess.exec([
                    "python3",
                    Quickshell.shellPath("scripts/animation-settings.py"),
                    "set", root.pendingKey, root.pendingValue
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
                    root.status = "Animation settings loaded"
                } catch (error) {
                    root.status = "Could not read animation settings"
                }
            }
        }
        stderr: StdioCollector {
            onStreamFinished: if (text.trim()) root.status = text.trim()
        }
    }

    Process {
        id: applyProcess
        onExited: (exitCode) => {
            if (exitCode === 0) {
                root.status = "Animation applied and saved"
                root.pendingKey = ""
            } else {
                root.status = "Could not apply animation setting"
                getProcess.exec([
                    "python3",
                    Quickshell.shellPath("scripts/animation-settings.py"),
                    "get"
                ])
            }
        }
        stderr: StdioCollector {
            onStreamFinished: if (text.trim()) root.status = text.trim()
        }
    }

    Component.onCompleted: {
        getProcess.exec([
            "python3",
            Quickshell.shellPath("scripts/animation-settings.py"),
            "get"
        ])
    }

    GridLayout {
        id: contentColumn
        x: Tokens.s5
        y: Tokens.s5
        width: Math.max(0, root.width - Tokens.s5 * 2)
        columns: 2
        columnSpacing: Tokens.s4
        rowSpacing: Tokens.s4

        // PAGE INTRODUCTION
        ColumnLayout {
            Layout.columnSpan: 2
            Layout.fillWidth: true
            spacing: Tokens.s2

            Text {
                text: "// MOTION SYSTEM"
                color: Tokens.inkMuted
                font.family: Tokens.ui
                font.pixelSize: Tokens.fMicro
                font.letterSpacing: Tokens.trackMark
            }

            Text {
                text: "Animations"
                color: Tokens.ink
                font.family: Tokens.display
                font.pixelSize: Tokens.fTitle
            }

            Text {
                text: "Fine-tune the timing and movement of your desktop."
                color: Tokens.inkMuted
                font.family: Tokens.ui
                font.pixelSize: Tokens.fBody
                wrapMode: Text.WordWrap
            }
        }

        // GLOBAL ANIMATIONS
        RUI.SettingCard {
            Layout.columnSpan: 2
            Layout.fillWidth: true
            title: "Global animations"
            note: "The master switch controls all configured Hyprland animations."

            RUI.SettingRow {
                label: "Enable animations"
                desc: "Master switch for all configured animations"
                controlWidth: 54

                RUI.Sw {
                    anchors.centerIn: parent
                    on: root.setting("global_enabled", true)
                    onToggled: v => root.queue("global_enabled", v)
                }
            }

            RUI.SettingRow {
                label: "Global speed"
                desc: "Current value: " + root.setting("global_speed", 100) + " ×10"
                block: true

                RUI.Slid {
                    anchors.fill: parent
                    from: 1
                    to: 200
                    value: root.setting("global_speed", 100)
                    onModified: v => root.queue("global_speed", v)
                }
            }
        }

        // WINDOW TRANSITIONS
        RUI.SettingCard {
            Layout.fillWidth: true
            title: "Window transitions"
            note: "Window movement keeps your existing easy spring. Opening and closing retain the pop-in style."

            RUI.SettingRow {
                label: "Window animations"
                controlWidth: 54

                RUI.Sw {
                    anchors.centerIn: parent
                    on: root.setting("windows_enabled", true)
                    onToggled: v => root.queue("windows_enabled", v)
                }
            }

            RUI.SettingRow {
                label: "Movement speed"
                desc: "Current value: " + root.setting("windows_speed", 48) + " ×10"
                block: true

                RUI.Slid {
                    anchors.fill: parent
                    from: 1
                    to: 100
                    value: root.setting("windows_speed", 48)
                    onModified: v => root.queue("windows_speed", v)
                }
            }

            RUI.SettingRow {
                label: "Opening speed"
                desc: "Current value: " + root.setting("windows_in_speed", 41) + " ×10"
                block: true

                RUI.Slid {
                    anchors.fill: parent
                    from: 1
                    to: 100
                    value: root.setting("windows_in_speed", 41)
                    onModified: v => root.queue("windows_in_speed", v)
                }
            }

            RUI.SettingRow {
                label: "Closing speed"
                desc: "Current value: " + root.setting("windows_out_speed", 15) + " ×10"
                block: true

                RUI.Slid {
                    anchors.fill: parent
                    from: 1
                    to: 100
                    value: root.setting("windows_out_speed", 15)
                    onModified: v => root.queue("windows_out_speed", v)
                }
            }
        }

        // FADE EFFECTS
        RUI.SettingCard {
            Layout.fillWidth: true
            title: "Fade effects"

            RUI.SettingRow {
                label: "Enable fade animations"
                controlWidth: 54

                RUI.Sw {
                    anchors.centerIn: parent
                    on: root.setting("fade_enabled", true)
                    onToggled: v => root.queue("fade_enabled", v)
                }
            }

            RUI.SettingRow {
                label: "Fade in"
                desc: "Current value: " + root.setting("fade_in_speed", 17) + " ×10"
                block: true

                RUI.Slid {
                    anchors.fill: parent
                    from: 1
                    to: 100
                    value: root.setting("fade_in_speed", 17)
                    onModified: v => root.queue("fade_in_speed", v)
                }
            }

            RUI.SettingRow {
                label: "Fade out"
                desc: "Current value: " + root.setting("fade_out_speed", 15) + " ×10"
                block: true

                RUI.Slid {
                    anchors.fill: parent
                    from: 1
                    to: 100
                    value: root.setting("fade_out_speed", 15)
                    onModified: v => root.queue("fade_out_speed", v)
                }
            }

            RUI.SettingRow {
                label: "General fade"
                desc: "Current value: " + root.setting("fade_speed", 30) + " ×10"
                block: true

                RUI.Slid {
                    anchors.fill: parent
                    from: 1
                    to: 100
                    value: root.setting("fade_speed", 30)
                    onModified: v => root.queue("fade_speed", v)
                }
            }
        }

        // WORKSPACE TRANSITIONS
        RUI.SettingCard {
            Layout.columnSpan: 2
            Layout.fillWidth: true
            title: "Workspace transitions"
            note: "Your original slide transition is retained. Only its speed and curve are adjustable here."

            RUI.SettingRow {
                label: "Enable workspace animations"
                controlWidth: 54

                RUI.Sw {
                    anchors.centerIn: parent
                    on: root.setting("workspaces_enabled", true)
                    onToggled: v => root.queue("workspaces_enabled", v)
                }
            }

            RUI.SettingRow {
                label: "Workspace speed"
                desc: "Current value: " + root.setting("workspaces_speed", 40) + " ×10"
                block: true

                RUI.Slid {
                    anchors.fill: parent
                    from: 1
                    to: 100
                    value: root.setting("workspaces_speed", 40)
                    onModified: v => root.queue("workspaces_speed", v)
                }
            }

            RUI.SettingRow {
                label: "Transition curve"
                desc: "Choose the easing curve used when switching workspaces."
                block: true

                RUI.Seg {
                    anchors.centerIn: parent
                    options: [
                        "easeInOutCubic",
                        "easeOutQuint",
                        "linear",
                        "quick"
                    ]
                    current: root.setting("workspace_curve", "easeInOutCubic")
                    onChose: key => root.queue("workspace_curve", key)
                }
            }
        }

        // LAYERS AND INTERFACE
        RUI.SettingCard {
            Layout.columnSpan: 2
            Layout.fillWidth: true
            title: "Layers & interface"

            RUI.SettingRow {
                label: "Enable layer animations"
                controlWidth: 54

                RUI.Sw {
                    anchors.centerIn: parent
                    on: root.setting("layers_enabled", true)
                    onToggled: v => root.queue("layers_enabled", v)
                }
            }

            RUI.SettingRow {
                label: "Layer speed"
                desc: "Current value: " + root.setting("layers_speed", 38) + " ×10"
                block: true

                RUI.Slid {
                    anchors.fill: parent
                    from: 1
                    to: 100
                    value: root.setting("layers_speed", 38)
                    onModified: v => root.queue("layers_speed", v)
                }
            }

            RUI.SettingRow {
                label: "Layer opening"
                desc: "Current value: " + root.setting("layers_in_speed", 40) + " ×10"
                block: true

                RUI.Slid {
                    anchors.fill: parent
                    from: 1
                    to: 100
                    value: root.setting("layers_in_speed", 40)
                    onModified: v => root.queue("layers_in_speed", v)
                }
            }

            RUI.SettingRow {
                label: "Layer closing"
                desc: "Current value: " + root.setting("layers_out_speed", 15) + " ×10"
                block: true

                RUI.Slid {
                    anchors.fill: parent
                    from: 1
                    to: 100
                    value: root.setting("layers_out_speed", 15)
                    onModified: v => root.queue("layers_out_speed", v)
                }
            }

            RUI.SettingRow {
                label: "Layer fade in"
                desc: "Current value: " + root.setting("fade_layers_in_speed", 18) + " ×10"
                block: true

                RUI.Slid {
                    anchors.fill: parent
                    from: 1
                    to: 100
                    value: root.setting("fade_layers_in_speed", 18)
                    onModified: v => root.queue("fade_layers_in_speed", v)
                }
            }

            RUI.SettingRow {
                label: "Layer fade out"
                desc: "Current value: " + root.setting("fade_layers_out_speed", 14) + " ×10"
                block: true

                RUI.Slid {
                    anchors.fill: parent
                    from: 1
                    to: 100
                    value: root.setting("fade_layers_out_speed", 14)
                    onModified: v => root.queue("fade_layers_out_speed", v)
                }
            }

            RUI.SettingRow {
                label: "Enable border animations"
                controlWidth: 54

                RUI.Sw {
                    anchors.centerIn: parent
                    on: root.setting("border_enabled", true)
                    onToggled: v => root.queue("border_enabled", v)
                }
            }

            RUI.SettingRow {
                label: "Border speed"
                desc: "Current value: " + root.setting("border_speed", 54) + " ×10"
                block: true

                RUI.Slid {
                    anchors.fill: parent
                    from: 1
                    to: 100
                    value: root.setting("border_speed", 54)
                    onModified: v => root.queue("border_speed", v)
                }
            }

            RUI.SettingRow {
                label: "Enable zoom animation"
                controlWidth: 54

                RUI.Sw {
                    anchors.centerIn: parent
                    on: root.setting("zoom_enabled", true)
                    onToggled: v => root.queue("zoom_enabled", v)
                }
            }

            RUI.SettingRow {
                label: "Zoom speed"
                desc: "Current value: " + root.setting("zoom_speed", 70) + " ×10"
                block: true

                RUI.Slid {
                    anchors.fill: parent
                    from: 1
                    to: 100
                    value: root.setting("zoom_speed", 70)
                    onModified: v => root.queue("zoom_speed", v)
                }
            }
        }

        // STATUS
        Text {
            Layout.columnSpan: 2
            Layout.fillWidth: true
            Layout.topMargin: Tokens.s2
            text: root.status
            color: Tokens.inkMuted
            font.family: Tokens.mono
            font.pixelSize: Tokens.fMicro
            wrapMode: Text.WordWrap
        }
    }
}
