import QtQuick
import Quickshell.Services.Pipewire
import qs
import qs.components
import ".."

FocusScope {
    id: root

    property string mode: "region"
    property bool recordingMode: false
    readonly property var source: Pipewire.defaultAudioSource
    readonly property color accent: recordingMode ? Theme.red : Theme.primary

    readonly property var currentMode: {
        const modes = {
            "full": {
                "title": "Full screen",
                "shortTitle": "Display",
                "description": "Capture everything on this display",
                "icon": "󰍹"
            },
            "window": {
                "title": "Window",
                "shortTitle": "Window",
                "description": "Capture a single application window",
                "icon": "󰖲"
            },
            "region": {
                "title": "Region",
                "shortTitle": "Area",
                "description": "Select a precise area to capture",
                "icon": "󰆞"
            }
        }
        return modes[mode] || modes.region
    }

    function takeInitialFocus() {
        if (recordingMode) {
            const item = recordControls.itemAt(0)
            if (item)
                item.forceActiveFocus(Qt.TabFocusReason)
            return
        }
        focusScreenshotMode(Math.max(0, ["full", "window", "region"].indexOf(mode)))
    }

    function focusScreenshotMode(index) {
        const count = screenshotModes.count
        if (!count)
            return
        const next = (index + count) % count
        const item = screenshotModes.itemAt(next)
        if (item) {
            mode = item.modelData.key
            item.forceActiveFocus(Qt.TabFocusReason)
        }
    }

    implicitWidth: 390
    implicitHeight: content.implicitHeight

    PwObjectTracker {
        objects: [root.source]
    }

    Timer {
        id: captureDelay
        interval: Theme.animationNormal + 100
        onTriggered: Backend.capture(root.mode)
    }

    Shortcut {
        sequence: "Return"
        enabled: ShellState.panel === "capture"
        onActivated: captureButton.activate()
    }

    Shortcut {
        sequence: "Enter"
        enabled: ShellState.panel === "capture"
        onActivated: captureButton.activate()
    }

    Column {
        id: content
        width: parent.width
        spacing: 14

        // Header: the small accent mark echoes the notch's pill shape.
        Row {
            width: parent.width
            height: 43
            spacing: 10

            Rectangle {
                width: 42
                height: 42
                radius: 14
                color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.12)
                border.width: 1
                border.color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.22)

                Behavior on color {
                    ColorAnimation { duration: Theme.animationNormal }
                }

                ShellText {
                    anchors.centerIn: parent
                    text: root.recordingMode ? "󰑊" : "󰄀"
                    color: root.accent
                    font.pixelSize: 21
                }
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 42 - 10 - captureKind.width - 10
                spacing: 2

                ShellText {
                    text: root.recordingMode ? "Screen recording" : "Capture"
                    color: Theme.foreground
                    font.pixelSize: 17
                    font.weight: Font.Bold
                }

                ShellText {
                    text: root.recordingMode
                        ? (Backend.recording ? "Recording in progress" : "Ready to record")
                        : "Capture your screen"
                    color: root.recordingMode && Backend.recording ? Theme.red : Theme.muted
                    font.pixelSize: 10
                    font.weight: Font.Medium
                }
            }

            Rectangle {
                id: captureKind
                anchors.verticalCenter: parent.verticalCenter
                transform: Translate { y: 10 }
                width: 130
                height: 34
                radius: 12
                color: Theme.bg0
                border.width: 1
                border.color: Theme.cardBorder

                Row {
                    anchors.fill: parent
                    anchors.margins: 3
                    spacing: 3

                    Repeater {
                        model: [
                            { "title": "Still", "icon": "󰄀", "recording": false },
                            { "title": "Record", "icon": "󰑊", "recording": true }
                        ]

                        delegate: FocusScope {
                            id: kindButton
                            required property var modelData
                            readonly property bool selected: root.recordingMode === modelData.recording

                            width: (captureKind.width - 12) / 2
                            height: captureKind.height - 8
                            activeFocusOnTab: true

                            function activate() {
                                root.recordingMode = modelData.recording
                            }

                            Keys.onReturnPressed: activate()
                            Keys.onEnterPressed: activate()
                            Keys.onSpacePressed: activate()
                            Accessible.role: Accessible.Button
                            Accessible.name: modelData.title

                            Rectangle {
                                anchors.fill: parent
                                radius: 9
                                color: kindButton.selected
                                    ? (kindButton.modelData.recording
                                        ? Qt.rgba(Theme.red.r, Theme.red.g, Theme.red.b, 0.14)
                                        : Theme.bg2)
                                    : (kindPointer.containsMouse ? Theme.bg1 : "transparent")
                                border.width: kindButton.activeFocus ? 1 : 0
                                border.color: root.accent

                                Behavior on color {
                                    ColorAnimation { duration: Theme.animationFast }
                                }
                            }

                            Row {
                                anchors.centerIn: parent
                                spacing: 4
                                height: 18
                                anchors.verticalCenterOffset: 1

                                ShellText {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: kindButton.modelData.icon
                                    color: kindButton.selected
                                        ? (kindButton.modelData.recording ? Theme.red : Theme.primary)
                                        : Theme.mutedDark
                                    font.pixelSize: 13
                                }

                                ShellText {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: kindButton.modelData.title
                                    color: kindButton.selected ? Theme.foreground : Theme.muted
                                    font.pixelSize: 10
                                    font.weight: kindButton.selected ? Font.Bold : Font.Medium
                                }
                            }

                            MouseArea {
                                id: kindPointer
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: kindButton.activate()
                            }
                        }
                    }
                }
            }
        }

        // Main preview card.
        Rectangle {
            id: previewCard
            width: parent.width
            height: 174
            radius: 20
            color: Theme.cardColor
            border.width: 1
            border.color: Theme.cardBorder
            clip: true

            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                color: "transparent"
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.025)
            }

            // Quiet decorative glow, tinted by the active mode.
            Rectangle {
                width: 180
                height: 120
                radius: 60
                x: previewCard.width - width + 35
                y: -55
                color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.055)

                Behavior on color {
                    ColorAnimation { duration: Theme.animationNormal }
                }
            }

            Row {
                id: previewHeader
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.leftMargin: 15
                anchors.rightMargin: 15
                anchors.topMargin: 13
                height: 20

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 7

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 6
                        height: 6
                        radius: 3
                        color: root.recordingMode && Backend.recording ? Theme.red : root.accent

                        SequentialAnimation on opacity {
                            running: root.recordingMode && Backend.recording
                            loops: Animation.Infinite
                            NumberAnimation { to: 0.35; duration: 650 }
                            NumberAnimation { to: 1.0; duration: 650 }
                        }
                    }

                    ShellText {
                        text: root.recordingMode
                            ? (Backend.recording ? "RECORDING" : "RECORDING PREVIEW")
                            : "CAPTURE PREVIEW"
                        color: root.recordingMode && Backend.recording ? Theme.red : Theme.muted
                        font.pixelSize: 9
                        font.weight: Font.Bold
                    }
                }

                Item { width: 1; height: 1 }

                ShellText {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.recordingMode ? "DISPLAY" : root.currentMode.shortTitle.toUpperCase()
                    color: root.accent
                    font.pixelSize: 9
                    font.weight: Font.Bold
                }
            }

            // Stylized display preview.
            Rectangle {
                id: displayFrame
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: previewHeader.bottom
                anchors.topMargin: 10
                width: parent.width - 36
                height: 91
                radius: 9
                color: Theme.bg0
                border.width: 1
                border.color: Theme.bg3
                clip: true

                // Window title bar.
                Row {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.leftMargin: 9
                    anchors.rightMargin: 9
                    anchors.topMargin: 7
                    height: 7
                    spacing: 4

                    Repeater {
                        model: [Theme.red, Theme.yellow, Theme.green]

                        Rectangle {
                            required property color modelData
                            width: 5
                            height: 5
                            radius: 3
                            color: modelData
                            opacity: 0.75
                        }
                    }

                    Item { width: 1; height: 1 }
                }

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.topMargin: 20
                    height: 1
                    color: Theme.bg2
                }

                // Selection frame changes shape smoothly with the selected mode.
                Rectangle {
                    id: selectionFrame
                    anchors.centerIn: parent
                    width: root.recordingMode || root.mode === "full"
                        ? parent.width - 2
                        : root.mode === "window" ? parent.width * 0.53 : parent.width * 0.43
                    height: root.recordingMode || root.mode === "full"
                        ? parent.height - 2
                        : root.mode === "window" ? 49 : 37
                    radius: root.mode === "window" && !root.recordingMode ? 6 : 3
                    color: root.recordingMode
                        ? Qt.rgba(Theme.red.r, Theme.red.g, Theme.red.b, 0.07)
                        : Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.07)
                    border.width: 1
                    border.color: root.accent

                    Behavior on width {
                        SpringAnim {}
                    }
                    Behavior on height {
                        SpringAnim {}
                    }
                    Behavior on color {
                        ColorAnimation { duration: Theme.animationNormal }
                    }
                    Behavior on border.color {
                        ColorAnimation { duration: Theme.animationNormal }
                    }

                    Rectangle {
                        anchors.centerIn: parent
                        width: 20
                        height: 20
                        radius: root.recordingMode ? 6 : 10
                        color: Theme.red
                        visible: root.recordingMode

                        Rectangle {
                            anchors.centerIn: parent
                            width: 7
                            height: 7
                            radius: Backend.recording ? 1 : 4
                            color: Theme.bgDim

                            Behavior on radius {
                                NumberAnimation { duration: Theme.animationFast }
                            }
                        }
                    }

                    Repeater {
                        model: root.mode === "region" && !root.recordingMode ? 4 : 0

                        Rectangle {
                            required property int index
                            x: index % 2 === 0 ? -2 : parent.width - 2
                            y: index < 2 ? -2 : parent.height - 2
                            width: 5
                            height: 5
                            radius: 1
                            color: root.accent
                        }
                    }
                }
            }

            ShellText {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.leftMargin: 15
                anchors.rightMargin: 15
                anchors.bottomMargin: 10
                text: root.recordingMode
                    ? (root.source ? (root.source.description || "Default microphone") : "No microphone detected")
                    : root.currentMode.description
                color: Theme.muted
                font.pixelSize: 10
                elide: Text.ElideRight
            }
        }

        // Capture modes: three compact, touch-friendly tiles.
        Column {
            width: parent.width
            spacing: 8
            visible: !root.recordingMode

            Row {
                width: parent.width
                height: 13

                ShellText {
                    text: "CAPTURE MODE"
                    color: Theme.mutedDark
                    font.pixelSize: 9
                    font.weight: Font.Bold
                }

                ShellText {
                    anchors.right: parent.right
                    text: "Choose a target"
                    color: Theme.mutedDark
                    font.pixelSize: 9
                }
            }

            Row {
                width: parent.width
                spacing: 8

                Repeater {
                    id: screenshotModes
                    model: [
                        { "key": "full", "icon": "󰍹", "title": "Display", "hint": "Everything" },
                        { "key": "window", "icon": "󰖲", "title": "Window", "hint": "One app" },
                        { "key": "region", "icon": "󰆞", "title": "Area", "hint": "Select area" }
                    ]

                    delegate: FocusScope {
                        id: targetButton
                        required property var modelData
                        required property int index
                        readonly property bool selected: root.mode === modelData.key

                        width: (root.width - 16) / 3
                        height: 72
                        activeFocusOnTab: true

                        function activate() {
                            root.focusScreenshotMode(index)
                        }

                        Keys.onReturnPressed: activate()
                        Keys.onEnterPressed: activate()
                        Keys.onSpacePressed: activate()
                        Keys.onLeftPressed: root.focusScreenshotMode(index - 1)
                        Keys.onRightPressed: root.focusScreenshotMode(index + 1)
                        Accessible.role: Accessible.Button
                        Accessible.name: modelData.title

                        Rectangle {
                            anchors.fill: parent
                            radius: 14
                            color: targetButton.selected
                                ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.105)
                                : (targetPointer.containsMouse ? Theme.bg1 : Theme.bg0)
                            border.width: targetButton.selected || targetButton.activeFocus ? 1 : 0
                            border.color: targetButton.activeFocus ? root.accent
                                : Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.48)

                            Behavior on color {
                                ColorAnimation { duration: Theme.animationFast }
                            }
                        }

                        Column {
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 4

                            ShellText {
                                text: targetButton.modelData.icon
                                color: targetButton.selected ? root.accent : Theme.muted
                                font.pixelSize: 18
                            }

                            ShellText {
                                text: targetButton.modelData.title
                                color: targetButton.selected ? Theme.foreground : Theme.muted
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                            }

                            ShellText {
                                text: targetButton.modelData.hint
                                color: Theme.mutedDark
                                font.pixelSize: 9
                            }
                        }

                        Rectangle {
                            anchors.top: parent.top
                            anchors.right: parent.right
                            anchors.topMargin: 8
                            anchors.rightMargin: 8
                            width: 5
                            height: 5
                            radius: 3
                            color: root.accent
                            visible: targetButton.selected
                        }

                        MouseArea {
                            id: targetPointer
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: targetButton.activate()
                        }
                    }
                }
            }
        }

        // Recording options.
        Rectangle {
            width: parent.width
            height: 65
            radius: 15
            color: Theme.bg0
            border.width: 1
            border.color: Theme.cardBorder
            visible: root.recordingMode

            Row {
                anchors.fill: parent
                anchors.leftMargin: 13
                anchors.rightMargin: 12
                spacing: 11

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 38
                    height: 38
                    radius: 12
                    color: root.source && root.source.audio && !root.source.audio.muted
                        ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12)
                        : Theme.bg1

                    ShellText {
                        anchors.centerIn: parent
                        text: root.source && root.source.audio && root.source.audio.muted ? "󰍭" : "󰍬"
                        color: root.source && root.source.audio && !root.source.audio.muted
                            ? Theme.primary : Theme.muted
                        font.pixelSize: 19
                    }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 38 - 11 - 70 - 11
                    spacing: 3

                    ShellText {
                        text: "Microphone audio"
                        color: Theme.foreground
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                    }

                    ShellText {
                        text: !root.source ? "No input device detected"
                            : (root.source.audio && root.source.audio.muted ? "Audio is muted" : (root.source.description || "Default input"))
                        color: Theme.muted
                        font.pixelSize: 9
                        elide: Text.ElideRight
                    }
                }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 60
                    height: 29
                    radius: 10
                    color: micPointer.containsMouse ? Theme.bg2 : Theme.bg1
                    border.width: 1
                    border.color: Theme.cardBorder

                    ShellText {
                        anchors.centerIn: parent
                        text: root.source && root.source.audio && !root.source.audio.muted ? "On" : "Off"
                        color: root.source && root.source.audio && !root.source.audio.muted
                            ? Theme.primary : Theme.muted
                        font.pixelSize: 10
                        font.weight: Font.Bold
                    }

                    MouseArea {
                        id: micPointer
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        enabled: !!(root.source && root.source.audio)
                        onClicked: root.source.audio.muted = !root.source.audio.muted
                    }
                }
            }
        }

        // Main action button: high contrast without fighting the theme.
        FocusScope {
            id: captureButton

            function activate() {
                if (root.recordingMode) {
                    Backend.toggleRecording()
                } else {
                    ShellState.close()
                    captureDelay.restart()
                }
            }

            width: parent.width
            height: 51
            activeFocusOnTab: true
            Keys.onReturnPressed: activate()
            Keys.onEnterPressed: activate()
            Keys.onSpacePressed: activate()
            Accessible.role: Accessible.Button
            Accessible.name: root.recordingMode
                ? (Backend.recording ? "Stop recording" : "Start recording")
                : "Take screenshot"

            Rectangle {
                anchors.fill: parent
                radius: 15
                color: actionPointer.containsMouse
                    ? Qt.darker(root.accent, 1.06)
                    : Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.94)
                border.width: captureButton.activeFocus ? 2 : 1
                border.color: captureButton.activeFocus ? Theme.foreground
                    : Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.8)

                Behavior on color {
                    ColorAnimation { duration: Theme.animationFast }
                }
            }

            Row {
                anchors.fill: parent
                anchors.leftMargin: 15
                anchors.rightMargin: 12
                spacing: 11

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 30
                    height: 30
                    radius: 10
                    color: Qt.rgba(0, 0, 0, 0.12)

                    ShellText {
                        anchors.centerIn: parent
                        text: root.recordingMode ? (Backend.recording ? "󰓛" : "󰑊") : "󰄀"
                        color: Theme.bgDim
                        font.pixelSize: 18
                    }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 30 - 11 - 34 - 22
                    spacing: 2

                    ShellText {
                        text: root.recordingMode
                            ? (Backend.recording ? "Stop recording" : "Start recording")
                            : "Capture " + root.currentMode.title.toLowerCase()
                        color: Theme.bgDim
                        font.pixelSize: 12
                        font.weight: Font.Bold
                    }

                    ShellText {
                        text: root.recordingMode
                            ? "Full display · WebM"
                            : "Saved to Pictures"
                        color: Qt.rgba(Theme.bgDim.r, Theme.bgDim.g, Theme.bgDim.b, 0.78)
                        font.pixelSize: 9
                    }
                }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 30
                    height: 25
                    radius: 8
                    color: Qt.rgba(0, 0, 0, 0.10)
                    border.width: 1
                    border.color: Qt.rgba(0, 0, 0, 0.08)

                    ShellText {
                        anchors.centerIn: parent
                        text: "↵"
                        color: Theme.bgDim
                        font.pixelSize: 15
                        font.weight: Font.Bold
                    }
                }
            }

            MouseArea {
                id: actionPointer
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: captureButton.activate()
            }
        }

        // Errors and last-action feedback stay inside the panel.
        Rectangle {
            width: parent.width
            height: 34
            radius: 11
            color: Backend.lastError
                ? Qt.rgba(Theme.red.r, Theme.red.g, Theme.red.b, 0.09)
                : Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.06)
            border.width: 1
            border.color: Backend.lastError
                ? Qt.rgba(Theme.red.r, Theme.red.g, Theme.red.b, 0.18)
                : Theme.cardBorder
            visible: Backend.lastError.length > 0 || Backend.lastCapture.length > 0

            Row {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 7

                ShellText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Backend.lastError ? "󰅚" : "󰄬"
                    color: Backend.lastError ? Theme.red : Theme.primary
                    font.pixelSize: 13
                }

                ShellText {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 24
                    text: Backend.lastError || Backend.lastCapture
                    color: Backend.lastError ? Theme.red : Theme.muted
                    font.pixelSize: 10
                    elide: Text.ElideMiddle
                }
            }
        }
    }
}
