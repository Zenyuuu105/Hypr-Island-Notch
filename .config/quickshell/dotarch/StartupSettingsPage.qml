import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs
import "components"
import "ui/Singletons"

Flickable {
    id: root
    clip: true
    contentWidth: availableWidth
    contentHeight: contentColumn.implicitHeight
    boundsBehavior: Flickable.StopAtBounds

    property var services: []
    property var custom: []
    property string status: "Loading startup entries…"
    property string newName: ""
    property string newCommand: ""

    function refresh() {
        getProcess.running = true
    }

    function setEnabled(id, enabled) {
        setProcess.exec([
            "python3", Quickshell.shellPath("scripts/startup-settings.py"),
            "set", id, enabled ? "true" : "false"
        ])
    }

    function addEntry() {
        if (!newName.trim() || !newCommand.trim()) {
            status = "Enter both an application name and command."
            return
        }
        addProcess.exec([
            "python3", Quickshell.shellPath("scripts/startup-settings.py"),
            "add", newName.trim(), newCommand.trim()
        ])
    }

    function removeEntry(id) {
        removeProcess.exec([
            "python3", Quickshell.shellPath("scripts/startup-settings.py"),
            "remove", id
        ])
    }

    Process {
        id: getProcess
        command: ["python3", Quickshell.shellPath("scripts/startup-settings.py"), "get"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text)
                    root.services = data.services || []
                    root.custom = data.custom || []
                    root.status = "Startup settings loaded"
                } catch (e) {
                    root.status = "Could not read startup settings"
                }
            }
        }
    }

    Process {
        id: setProcess
        onExited: (code) => {
            root.status = code === 0 ? "Startup preference saved" : "Could not save preference"
            root.refresh()
        }
    }

    Process {
        id: addProcess
        onExited: (code) => {
            if (code === 0) {
                root.newName = ""
                root.newCommand = ""
                root.status = "Startup command added"
            } else {
                root.status = "Could not add startup command"
            }
            root.refresh()
        }
    }

    Process {
        id: removeProcess
        onExited: (code) => {
            root.status = code === 0 ? "Startup command removed" : "Could not remove command"
            root.refresh()
        }
    }

    ColumnLayout {
        id: contentColumn
        width: root.width
        spacing: 17

        // Page heading
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 5

            Text {
                text: "Startup applications"
                color: Tokens.ink
                font.family: Tokens.ui
                font.pixelSize: 22
                font.weight: Font.DemiBold
            }

            Text {
                text: "Choose what starts automatically when your desktop session begins."
                color: Tokens.inkMuted
                font.family: Tokens.ui
                font.pixelSize: Tokens.fMicro
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
        }

        // Summary
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Repeater {
                model: [
                    {
                        label: "ENABLED SERVICES",
                        value: root.services.filter(function(item) { return item.enabled }).length,
                        detail: "Desktop components"
                    },
                    {
                        label: "CUSTOM LAUNCHERS",
                        value: root.custom.filter(function(item) { return item.enabled }).length,
                        detail: "Active startup commands"
                    }
                ]

                delegate: Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.preferredHeight: 82
                    radius: 7
                    color: Tokens.paperLift
                    border.width: 1
                    border.color: Tokens.line

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 13

                        Rectangle {
                            width: 34
                            height: 34
                            radius: 6
                            color: Tokens.paper

                            Text {
                                anchors.centerIn: parent
                                text: modelData.value
                                color: Tokens.ink
                                font.family: Tokens.ui
                                font.pixelSize: 17
                                font.weight: Font.DemiBold
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            Text {
                                text: modelData.label
                                color: Tokens.ink
                                font.family: Tokens.ui
                                font.pixelSize: Tokens.fTiny
                                font.weight: Font.DemiBold
                                font.letterSpacing: 0.8
                            }

                            Text {
                                text: modelData.detail
                                color: Tokens.inkMuted
                                font.family: Tokens.ui
                                font.pixelSize: Tokens.fTiny
                            }
                        }
                    }
                }
            }
        }

        // Desktop services
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 9

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "Desktop services"
                    color: Tokens.ink
                    font.family: Tokens.ui
                    font.pixelSize: Tokens.fSmall
                    font.weight: Font.DemiBold
                }

                Text {
                    text: root.services.length + " SERVICES"
                    color: Tokens.inkMuted
                    font.family: Tokens.ui
                    font.pixelSize: Tokens.fTiny
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: "SESSION"
                    color: Tokens.inkMuted
                    font.family: Tokens.ui
                    font.pixelSize: Tokens.fTiny
                    font.letterSpacing: 1
                }
            }

            Rectangle {
                Layout.fillWidth: true
                radius: 7
                color: Tokens.paperLift
                border.width: 1
                border.color: Tokens.line
                implicitHeight: serviceList.implicitHeight + 12

                ColumnLayout {
                    id: serviceList
                    anchors.fill: parent
                    anchors.margins: 6
                    spacing: 0

                    Repeater {
                        model: root.services

                        delegate: ColumnLayout {
                            required property var modelData
                            Layout.fillWidth: true
                            spacing: 0

                            RowLayout {
                                Layout.fillWidth: true
                                Layout.minimumHeight: 61
                                Layout.leftMargin: 9
                                Layout.rightMargin: 9
                                spacing: 12

                                Rectangle {
                                    width: 7
                                    height: 7
                                    radius: 4
                                    color: modelData.enabled ? Tokens.ink : Tokens.inkMuted
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 3

                                    Text {
                                        text: modelData.name
                                        color: Tokens.ink
                                        font.family: Tokens.ui
                                        font.pixelSize: Tokens.fMicro
                                        font.weight: Font.DemiBold
                                    }

                                    Text {
                                        text: modelData.description
                                        color: Tokens.inkMuted
                                        font.family: Tokens.ui
                                        font.pixelSize: Tokens.fTiny
                                        wrapMode: Text.WordWrap
                                        Layout.fillWidth: true
                                    }
                                }

                                Sw {
                                    on: modelData.enabled
                                    onToggled: value => root.setEnabled(modelData.id, value)
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.leftMargin: 9
                                Layout.rightMargin: 9
                                height: 1
                                color: Tokens.line
                            }
                        }
                    }

                    Text {
                        visible: root.services.length === 0
                        text: "No desktop services found."
                        color: Tokens.inkMuted
                        font.family: Tokens.ui
                        font.pixelSize: Tokens.fMicro
                        Layout.margins: 12
                    }
                }
            }
        }

        // Custom launchers
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 9

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "Custom launchers"
                    color: Tokens.ink
                    font.family: Tokens.ui
                    font.pixelSize: Tokens.fSmall
                    font.weight: Font.DemiBold
                }

                Text {
                    text: root.custom.length + " COMMANDS"
                    color: Tokens.inkMuted
                    font.family: Tokens.ui
                    font.pixelSize: Tokens.fTiny
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: "USER DEFINED"
                    color: Tokens.inkMuted
                    font.family: Tokens.ui
                    font.pixelSize: Tokens.fTiny
                    font.letterSpacing: 1
                }
            }

            Rectangle {
                Layout.fillWidth: true
                radius: 7
                color: Tokens.paperLift
                border.width: 1
                border.color: Tokens.line
                implicitHeight: launcherList.implicitHeight + 12

                ColumnLayout {
                    id: launcherList
                    anchors.fill: parent
                    anchors.margins: 6
                    spacing: 0

                    Repeater {
                        model: root.custom

                        delegate: ColumnLayout {
                            required property var modelData
                            Layout.fillWidth: true
                            spacing: 0

                            RowLayout {
                                Layout.fillWidth: true
                                Layout.minimumHeight: 59
                                Layout.leftMargin: 9
                                Layout.rightMargin: 9
                                spacing: 11

                                Rectangle {
                                    width: 30
                                    height: 30
                                    radius: 5
                                    color: Tokens.paper

                                    Text {
                                        anchors.centerIn: parent
                                        text: "⌘"
                                        color: Tokens.ink
                                        font.family: Tokens.ui
                                        font.pixelSize: Tokens.fRow
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 3

                                    Text {
                                        text: modelData.name
                                        color: Tokens.ink
                                        font.family: Tokens.ui
                                        font.pixelSize: Tokens.fMicro
                                        font.weight: Font.DemiBold
                                    }

                                    Text {
                                        text: modelData.command
                                        color: Tokens.inkMuted
                                        font.family: Tokens.ui
                                        font.pixelSize: Tokens.fTiny
                                        elide: Text.ElideMiddle
                                        Layout.fillWidth: true
                                    }
                                }

                                Sw {
                                    on: modelData.enabled
                                    onToggled: value => root.setEnabled(modelData.id, value)
                                }

                                Button {
                                    text: "Remove"
                                    onClicked: root.removeEntry(modelData.id)
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.leftMargin: 9
                                Layout.rightMargin: 9
                                height: 1
                                color: Tokens.line
                            }
                        }
                    }

                    Text {
                        visible: root.custom.length === 0
                        text: "No custom commands yet. Add one below."
                        color: Tokens.inkMuted
                        font.family: Tokens.ui
                        font.pixelSize: Tokens.fMicro
                        Layout.margins: 12
                    }
                }
            }

            // Inline launcher editor
            Rectangle {
                Layout.fillWidth: true
                radius: 7
                color: Tokens.paperLift
                border.width: 1
                border.color: Tokens.line
                implicitHeight: addLauncherColumn.implicitHeight + 24

                ColumnLayout {
                    id: addLauncherColumn
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 9

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text: "ADD LAUNCHER"
                            color: Tokens.ink
                            font.family: Tokens.ui
                            font.pixelSize: Tokens.fTiny
                            font.weight: Font.DemiBold
                            font.letterSpacing: 1
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            text: "RUNS AT LOGIN"
                            color: Tokens.inkMuted
                            font.family: Tokens.ui
                            font.pixelSize: Tokens.fTiny
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 9

                        TextField {
                            Layout.preferredWidth: 145
                            Layout.fillWidth: true
                            placeholderText: "Application name"
                            text: root.newName
                            onTextChanged: root.newName = text
                        }

                        TextField {
                            Layout.fillWidth: true
                            placeholderText: "Command (e.g. discord)"
                            text: root.newCommand
                            onTextChanged: root.newCommand = text
                        }

                        Button {
                            text: "Add command"
                            onClicked: root.addEntry()
                        }
                    }
                }
            }
        }

        // Status and information
        Rectangle {
            Layout.fillWidth: true
            radius: 6
            color: Tokens.paperLift
            border.width: 1
            border.color: Tokens.line
            implicitHeight: statusColumn.implicitHeight + 20

            ColumnLayout {
                id: statusColumn
                anchors.fill: parent
                anchors.margins: 10
                spacing: 5

                Text {
                    Layout.fillWidth: true
                    text: root.status
                    color: Tokens.ink
                    font.family: Tokens.ui
                    font.pixelSize: Tokens.fTiny
                    wrapMode: Text.WordWrap
                }

                Text {
                    Layout.fillWidth: true
                    text: "Changes are saved immediately and take effect on your next login. They do not stop services already running in this session."
                    color: Tokens.inkMuted
                    font.family: Tokens.ui
                    font.pixelSize: Tokens.fTiny
                    wrapMode: Text.WordWrap
                }
            }
        }
    }

    Component.onCompleted: refresh()
}
