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
    property string status: "Loading input settings..."
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
        status = "Applying input change..."
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
                    Quickshell.shellPath("scripts/input-settings.py"),
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
                    root.status = "Input settings loaded"
                } catch (error) {
                    root.status = "Could not read input settings"
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
                root.status = "Input change applied and saved"
                root.pendingKey = ""
                getProcess.exec([
                    "python3",
                    Quickshell.shellPath("scripts/input-settings.py"),
                    "get"
                ])
            } else {
                root.status = "Could not apply input setting"
                getProcess.exec([
                    "python3",
                    Quickshell.shellPath("scripts/input-settings.py"),
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
            Quickshell.shellPath("scripts/input-settings.py"),
            "get"
        ])
    }

    GridLayout {
        id: contentColumn
        width: root.width
        columns: 2
        columnSpacing: 14
        rowSpacing: 14

        ColumnLayout {
            Layout.columnSpan: 2
            Layout.fillWidth: true
            spacing: 4

            Text {
                text: "INPUT DEVICES"
                color: Tokens.ink
                font.pixelSize: 18
                font.weight: Font.DemiBold
            }

            Text {
                text: "Configure how you interact with your desktop."
                color: Tokens.inkMuted
                font.family: Tokens.ui
                font.pixelSize: Tokens.fMicro
            }
        }

        // KEYBOARD
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: keyboardColumn.implicitHeight + 32
            radius: 8
            color: Tokens.paperLift
            border.width: 1
            border.color: Tokens.line

            ColumnLayout {
                id: keyboardColumn
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                Text {
                    text: "Keyboard"
                    color: Tokens.ink
                    font.family: Tokens.ui
                    font.pixelSize: Tokens.fSmall
                    font.weight: Font.DemiBold
                }

                SChoice {
                    Layout.fillWidth: true
                    label: "Keyboard layout"
                    current: root.setting("kb_layout", "us")
                    accent: Tokens.ink
                    options: [
                        { key: "us", text: "US" },
                        { key: "gb", text: "UK" },
                        { key: "ara", text: "Arabic" },
                        { key: "de", text: "German" },
                        { key: "fr", text: "French" },
                        { key: "ru", text: "Russian" }
                    ]
                    onPicked: key => root.queue("kb_layout", key)
                }

                Text {
                    Layout.fillWidth: true
                    text: "Changes the active keyboard layout in Hyprland."
                    color: Tokens.inkMuted
                    font.family: Tokens.ui
                    font.pixelSize: Tokens.fTiny
                    wrapMode: Text.WordWrap
                }
            }
        }

        // POINTER
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: pointerColumn.implicitHeight + 32
            radius: 8
            color: Tokens.paperLift
            border.width: 1
            border.color: Tokens.line

            ColumnLayout {
                id: pointerColumn
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                Text {
                    text: "Pointer"
                    color: Tokens.ink
                    font.family: Tokens.ui
                    font.pixelSize: Tokens.fSmall
                    font.weight: Font.DemiBold
                }

                SettingSlider {
                    Layout.fillWidth: true
                    label: "Pointer sensitivity"
                    from: -100
                    to: 100
                    value: Math.round(root.setting("sensitivity", 0) * 100)
                    unit: "%"
                    onMoved: v => root.queue("sensitivity", v / 100)
                }

                Text {
                    Layout.fillWidth: true
                    text: "Zero is the default sensitivity. Negative values slow the pointer; positive values speed it up."
                    color: Tokens.inkMuted
                    font.family: Tokens.ui
                    font.pixelSize: Tokens.fTiny
                    wrapMode: Text.WordWrap
                }
            }
        }

        // TOUCHPAD
        Rectangle {
            Layout.columnSpan: 2
            Layout.fillWidth: true
            implicitHeight: touchpadColumn.implicitHeight + 32
            radius: 8
            color: Tokens.paperLift
            border.width: 1
            border.color: Tokens.line

            ColumnLayout {
                id: touchpadColumn
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                Text {
                    text: "Touchpad"
                    color: Tokens.ink
                    font.family: Tokens.ui
                    font.pixelSize: Tokens.fSmall
                    font.weight: Font.DemiBold
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    columnSpacing: 18
                    rowSpacing: 10

                    SettingSwitch {
                        Layout.fillWidth: true
                        label: "Natural scrolling"
                    description: "Move content in the direction of your fingers"
                    checked: root.setting("natural_scroll", true)
                    onToggled: v => root.queue("natural_scroll", v)
                }

                    SettingSwitch {
                        Layout.fillWidth: true
                        label: "Tap to click"
                    description: "Tap the touchpad instead of pressing it"
                    checked: root.setting("tap_to_click", true)
                    onToggled: v => root.queue("tap_to_click", v)
                }

                    SettingSwitch {
                        Layout.fillWidth: true
                        label: "Disable while typing"
                    description: "Prevent accidental touchpad input while typing"
                    checked: root.setting("disable_while_typing", true)
                        onToggled: v => root.queue("disable_while_typing", v)
                    }
                }

                SettingSlider {
                    Layout.fillWidth: true
                    label: "Touchpad scroll speed"
                    from: 10
                    to: 300
                    value: Math.round(root.setting("scroll_factor", 1) * 100)
                    unit: "%"
                    onMoved: v => root.queue("scroll_factor", v / 100)
                }
            }
        }

        Rectangle {
            Layout.columnSpan: 2
            Layout.fillWidth: true
            implicitHeight: statusRow.implicitHeight + 22
            radius: 12
            color: Tokens.paperLift
            border.width: 1
            border.color: Tokens.line

            RowLayout {
                id: statusRow
                anchors.fill: parent
                anchors.margins: 11
                spacing: 9

                Rectangle {
                    Layout.preferredWidth: 7
                    Layout.preferredHeight: 7
                    radius: 4
                    color: Tokens.ink
                }

                Text {
                    Layout.fillWidth: true
                    text: root.status
                    color: Tokens.inkMuted
                    font.family: Tokens.ui
                    font.pixelSize: Tokens.fMicro
                    wrapMode: Text.WordWrap
                }
            }
        }
    }
}
