import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs
import "ui/Singletons"

Item {
    id: root

    Layout.fillWidth: true
    Layout.fillHeight: true

    property string selectedTheme: "nier-automata"
    property string activeTheme: ""
    property string status: "Loading Qylock themes..."
    property var themes: []
    property bool busy: false

    function refresh() {
        getProcess.exec([
            "python3",
            Quickshell.shellPath("scripts/lock-settings.py"),
            "get"
        ])
    }

    function selectTheme(key) {
        selectedTheme = key
    }

    function saveTheme() {
        busy = true
        status = "Applying selected theme to SDDM..."
        saveProcess.exec([
            "python3",
            Quickshell.shellPath("scripts/lock-settings.py"),
            "save",
            selectedTheme
        ])
    }

    function previewTheme() {
        busy = true
        status = "Opening safe theme preview..."
        previewProcess.exec([
            "python3",
            Quickshell.shellPath("scripts/lock-settings.py"),
            "preview",
            selectedTheme
        ])
    }

    Process {
        id: getProcess

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text)
                    root.activeTheme = data.active || ""
                    root.selectedTheme = data.selected
                    root.themes = data.themes
                    root.status = root.themes.length + " themes available · SDDM: " + (data.sddm_current || "not configured")
                } catch (error) {
                    root.status = "Could not load Qylock themes"
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
        id: saveProcess

        onExited: (code) => {
            root.busy = false
            if (code === 0) {
                root.status = "SDDM theme applied: " + root.selectedTheme + ". It will appear at the next greeter launch. Hyprlock is unchanged."
                root.refresh()
            } else {
                root.status = "Could not save the selected theme"
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
        id: previewProcess

        onExited: (code) => {
            root.busy = false
            root.status = code === 0
                ? "Preview launched"
                : "Could not launch preview"
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
        anchors.fill: parent
        spacing: 12

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 5

            Text {
                text: "Login Screen"
                color: Tokens.ink
                font.pixelSize: 18
                font.weight: Font.DemiBold
            }

            Text {
                text: "Choose the theme displayed by SDDM before you sign in."
                color: Tokens.inkMuted
                font.family: Tokens.ui
                font.pixelSize: Tokens.fMicro
                wrapMode: Text.WordWrap
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: actionsColumn.implicitHeight + 26
            radius: 14
            color: Tokens.paperLift
            border.width: 1
            border.color: Tokens.line

            ColumnLayout {
                id: actionsColumn
                anchors.fill: parent
                anchors.margins: 13
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 3

                        Text {
                            text: "SELECTED THEME"
                            color: Tokens.inkMuted
                            font.family: Tokens.ui
                            font.pixelSize: Tokens.fTiny
                            font.weight: Font.DemiBold
                        }

                        Text {
                            Layout.fillWidth: true
                            text: root.selectedTheme.replace(/[-_]/g, " ")
                            color: Tokens.ink
                            font.pixelSize: 16
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }

                        Text {
                            text: root.selectedTheme === root.activeTheme
                                ? "This theme is already active"
                                : "Ready to apply to the SDDM greeter"
                            color: Tokens.inkMuted
                            font.family: Tokens.ui
                            font.pixelSize: Tokens.fMicro
                        }
                    }

                    Rectangle {
                        implicitWidth: 1
                        Layout.preferredHeight: 42
                        color: Tokens.line
                    }

                    ColumnLayout {
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 3

                        Text {
                            text: "CURRENTLY ACTIVE"
                            color: Tokens.inkMuted
                            font.family: Tokens.ui
                            font.pixelSize: Tokens.fTiny
                            font.weight: Font.DemiBold
                        }

                        Text {
                            text: root.activeTheme
                                ? root.activeTheme.replace(/[-_]/g, " ")
                                : "Not configured"
                            color: Tokens.ink
                            font.family: Tokens.ui
                            font.pixelSize: Tokens.fMicro
                            font.weight: Font.DemiBold
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 9

                    Rectangle {
                        Layout.fillWidth: true
                        height: 38
                        radius: 10
                        color: Tokens.paper
                        opacity: root.busy ? 0.5 : 1

                        Text {
                            anchors.centerIn: parent
                            text: "Preview theme"
                            color: Tokens.ink
                            font.family: Tokens.ui
                            font.pixelSize: Tokens.fMicro
                            font.weight: Font.DemiBold
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: !root.busy
                            onClicked: root.previewTheme()
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 38
                        radius: 10
                        color: root.selectedTheme === root.activeTheme
                            ? Tokens.paperLift : Tokens.ink
                        opacity: root.busy ? 0.5 : 1

                        Text {
                            anchors.centerIn: parent
                            text: "Apply to SDDM"
                            color: root.selectedTheme === root.activeTheme
                                ? Tokens.inkMuted : Tokens.inkOnBone
                            font.family: Tokens.ui
                            font.pixelSize: Tokens.fMicro
                            font.weight: Font.DemiBold
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: !root.busy &&
                                root.selectedTheme !== root.activeTheme
                            onClicked: root.saveTheme()
                        }
                    }
                }
            }
        }

        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentWidth: width
            contentHeight: contentColumn.implicitHeight
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: contentColumn
                width: parent.width
                spacing: 16




        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "Qylock themes"
                color: Tokens.ink
                font.family: Tokens.ui
                font.pixelSize: Tokens.fBody
                font.weight: Font.DemiBold
            }

            Item { Layout.fillWidth: true }

            Text {
                text: root.themes.length + " themes"
                color: Tokens.inkMuted
                font.family: Tokens.ui
                font.pixelSize: Tokens.fMicro
            }
        }

        GridLayout {
            Layout.fillWidth: true
            columns: root.width > 650 ? 2 : 1
            columnSpacing: 12
            rowSpacing: 12

            Repeater {
                model: root.themes

                delegate: Rectangle {
                    id: themeCard

                    required property var modelData

                    Layout.fillWidth: true
                    Layout.preferredHeight: 184

                    radius: Tokens.radius
                    color: root.selectedTheme === modelData.key
                        ? Tokens.tint10 : Tokens.paperLift
                    border.width: root.selectedTheme === modelData.key ? 2 : 1
                    border.color: root.selectedTheme === modelData.key
                        ? Tokens.ink : Tokens.line

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 9
                        spacing: 7

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: Tokens.radius
                            clip: true
                            color: Tokens.paper

                            Image {
                                anchors.fill: parent
                                source: modelData.preview
                                    ? "file://" + modelData.preview : ""
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                cache: true
                            }

                            Text {
                                anchors.centerIn: parent
                                visible: !modelData.preview
                                text: modelData.animated ? "▶  ANIMATED THEME" : "QYLOCK THEME"
                                color: Tokens.ink
                                font.family: Tokens.ui
                                font.pixelSize: Tokens.fMicro
                                font.weight: Font.DemiBold
                            }

                            Rectangle {
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.margins: 7
                                width: 48
                                height: 21
                                radius: 10
                                color: "#cc20252b"
                                visible: modelData.animated

                                Text {
                                    anchors.centerIn: parent
                                    text: "VIDEO"
                                    color: "#ffffff"
                                    font.family: Tokens.ui
                                    font.pixelSize: Tokens.fTiny
                                    font.weight: Font.Bold
                                }
                            }

                            Rectangle {
                                anchors.left: parent.left
                                anchors.bottom: parent.bottom
                                anchors.margins: 7
                                width: 58
                                height: 21
                                radius: 10
                                color: Tokens.ink
                                visible: root.activeTheme === modelData.key

                                Text {
                                    anchors.centerIn: parent
                                    text: "ACTIVE"
                                    color: Tokens.inkOnBone
                                    font.family: Tokens.ui
                                    font.pixelSize: Tokens.fTiny
                                    font.weight: Font.Bold
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

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
                                    Layout.fillWidth: true
                                    text: modelData.key
                                    color: Tokens.inkMuted
                                    font.family: Tokens.ui
                                    font.pixelSize: Tokens.fTiny
                                    elide: Text.ElideRight
                                }
                            }

                            Rectangle {
                                implicitWidth: 67
                                height: 27
                                radius: Tokens.radius
                                color: root.selectedTheme === modelData.key
                                    ? Tokens.ink : Tokens.paperLift

                                Text {
                                    anchors.centerIn: parent
                                    text: root.selectedTheme === modelData.key
                                        ? "Selected" : "Select"
                                    color: root.selectedTheme === modelData.key
                                        ? Tokens.inkOnBone : Tokens.ink
                                    font.family: Tokens.ui
                                    font.pixelSize: Tokens.fMicro
                                    font.weight: Font.DemiBold
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: root.selectTheme(modelData.key)
                                }
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        z: -1
                        onClicked: root.selectTheme(modelData.key)
                    }
                }
            }
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
