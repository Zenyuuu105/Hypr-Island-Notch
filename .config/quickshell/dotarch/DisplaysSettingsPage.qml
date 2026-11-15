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

    property var monitors: []
    property string selectedMonitor: ""
    property string selectedMode: ""
    property real selectedScale: 1.0
    property string status: "Detecting connected displays..."
    property bool applying: false

    function currentMonitor() {
        for (var i = 0; i < monitors.length; i++) {
            if (monitors[i].name === selectedMonitor)
                return monitors[i]
        }
        return monitors.length ? monitors[0] : null
    }

    function monitorOptions() {
        return monitors.map(function(m) {
            return { key: m.name, text: m.name }
        })
    }

    function modeOptions() {
        var m = currentMonitor()
        if (!m) return []
        return m.availableModes.map(function(mode) {
            return { key: mode, text: mode }
        })
    }

    function loadData(data) {
        monitors = data
        if (!monitors.length) {
            selectedMonitor = ""
            selectedMode = ""
            status = "No connected displays detected"
            return
        }

        var found = false
        for (var i = 0; i < monitors.length; i++) {
            if (monitors[i].name === selectedMonitor)
                found = true
        }
        if (!found)
            selectedMonitor = monitors[0].name

        var m = currentMonitor()
        if (m) {
            selectedMode = m.mode
            selectedScale = m.scale
            status = monitors.length + " display(s) detected"
        }
    }

    function refresh() {
        getProcess.exec([
            "python3",
            Quickshell.shellPath("scripts/display-settings.py"),
            "get"
        ])
    }

    Process {
        id: getProcess
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.loadData(JSON.parse(text))
                } catch (error) {
                    root.status = "Could not read display information"
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
            root.applying = false
            if (exitCode === 0) {
                root.status = "Display settings applied and saved"
                root.refresh()
            } else {
                root.status = "Could not apply display settings"
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim())
                    root.status = text.trim()
            }
        }
    }

    Component.onCompleted: refresh()

    ColumnLayout {
        id: contentColumn
        width: root.width
        spacing: 16

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            Text {
                text: "Displays"
                color: Tokens.ink
                font.pixelSize: 18
                font.weight: Font.DemiBold
            }

            Text {
                text: "Configure connected monitors, resolution and display scaling."
                color: Tokens.inkMuted
                font.family: Tokens.ui
                font.pixelSize: Tokens.fMicro
                wrapMode: Text.WordWrap
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: monitorColumn.implicitHeight + 32
            radius: 8
            color: Tokens.paperLift
            border.width: 1
            border.color: Tokens.line

            ColumnLayout {
                id: monitorColumn
                anchors.fill: parent
                anchors.margins: 16
                spacing: 13

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: "Connected displays"
                        color: Tokens.ink
                        font.family: Tokens.ui
                        font.pixelSize: Tokens.fSmall
                        font.weight: Font.DemiBold
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        implicitWidth: refreshLabel.implicitWidth + 22
                        implicitHeight: 30
                        radius: 9
                        color: Tokens.paper

                        Text {
                            id: refreshLabel
                            anchors.centerIn: parent
                            text: "↻  Refresh"
                            color: Tokens.ink
                            font.family: Tokens.ui
                            font.pixelSize: Tokens.fMicro
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.refresh()
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Repeater {
                        model: root.monitors

                        delegate: Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 78
                            radius: 8

                            property bool selected: modelData.name === root.selectedMonitor

                            color: selected ? Tokens.paperLift : "transparent"
                            border.width: selected ? 1 : 0
                            border.color: selected ? Tokens.ink : Tokens.line

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 10
                                anchors.topMargin: 9
                                anchors.bottomMargin: 9
                                spacing: 4

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 6

                                    Rectangle {
                                        Layout.preferredWidth: 7
                                        Layout.preferredHeight: 7
                                        radius: 4
                                        color: selected ? Tokens.ink : Tokens.inkMuted
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.name
                                        color: Tokens.ink
                                        font.family: Tokens.ui
                                        font.pixelSize: Tokens.fMicro
                                        font.weight: Font.DemiBold
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        text: selected ? "ACTIVE" : ""
                                        color: Tokens.ink
                                        font.family: Tokens.ui
                                        font.pixelSize: Tokens.fTiny
                                        font.weight: Font.DemiBold
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.width + " × " + modelData.height
                                          + "   ·   " + modelData.refreshRate.toFixed(2) + " Hz"
                                    color: Tokens.inkMuted
                                    font.family: Tokens.ui
                                    font.pixelSize: Tokens.fMicro
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.description
                                    color: Tokens.inkMuted
                                    font.family: Tokens.ui
                                    font.pixelSize: Tokens.fTiny
                                    elide: Text.ElideRight
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.selectedMonitor = modelData.name
                                    var m = root.currentMonitor()
                                    if (m) {
                                        root.selectedMode = m.mode
                                        root.selectedScale = m.scale
                                    }
                                }
                            }
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    visible: root.monitors.length === 0
                    text: "No connected displays detected."
                    color: Tokens.inkMuted
                    font.family: Tokens.ui
                    font.pixelSize: Tokens.fMicro
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Tokens.line
                }

                Text {
                    text: "Resolution and refresh rate"
                    color: Tokens.ink
                    font.family: Tokens.ui
                    font.pixelSize: Tokens.fSmall
                    font.weight: Font.DemiBold
                }

                SChoice {
                    Layout.fillWidth: true
                    label: "Available display modes"
                    options: root.modeOptions()
                    current: root.selectedMode
                    accent: Tokens.ink
                    onPicked: key => root.selectedMode = key
                }

                SettingSlider {
                    Layout.fillWidth: true
                    label: "Display scale  (100% = 1.00×)"
                    from: 50
                    to: 200
                    value: Math.round(root.selectedScale * 100)
                    unit: "%"
                    accent: Tokens.ink
                    onMoved: v => root.selectedScale = v / 100
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 40
                        radius: 11
                        color: Tokens.paper
                        opacity: root.applying ? 0.5 : 1

                        Text {
                            anchors.centerIn: parent
                            text: root.applying ? "Applying..." : "Apply display settings"
                            color: Tokens.ink
                            font.family: Tokens.ui
                            font.pixelSize: Tokens.fMicro
                            font.weight: Font.DemiBold
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: !root.applying && !!root.currentMonitor()
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (!root.selectedMonitor || !root.selectedMode)
                                    return
                                root.applying = true
                                root.status = "Applying display settings..."
                                applyProcess.exec([
                                    "python3",
                                    Quickshell.shellPath("scripts/display-settings.py"),
                                    "apply",
                                    root.selectedMonitor,
                                    root.selectedMode,
                                    String(root.selectedScale)
                                ])
                            }
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: "Changes are applied only when you press Apply. Your selected mode and scale are saved for future Hyprland sessions."
                    color: Tokens.inkMuted
                    font.family: Tokens.ui
                    font.pixelSize: Tokens.fTiny
                    wrapMode: Text.WordWrap
                }
            }
        }

        Rectangle {
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
                    color: root.applying ? Tokens.inkMuted : Tokens.ink
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
