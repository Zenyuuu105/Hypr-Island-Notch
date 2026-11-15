import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs
import "components"
import "ui/Singletons"

ColumnLayout {
    id: root
    spacing: 14

    property var settings: ({
        cursor_theme: "macOS",
        cursor_size: 36,
        gtk_font: "Pomodoro",
        gtk_size: 11,
        qt_font: "Inter SemiBold",
        qt_size: 11,
        qt_fixed_font: "JetBrainsMono Nerd Font",
        qt_fixed_size: 11,
        cursor_themes: ["macOS"]
    })

    property string status: "Loading cursor and font settings…"
    property bool busy: false

    function refresh() {
        if (!getProcess.running)
            getProcess.running = true
    }

    function apply() {
        if (busy)
            return
        busy = true
        status = "Applying cursor and font settings…"
        applyProcess.exec([
            "python3", Quickshell.shellPath("scripts/cursor-font-settings.py"),
            "apply",
            String(settings.cursor_theme),
            String(settings.cursor_size),
            String(settings.gtk_font),
            String(settings.gtk_size),
            String(settings.qt_font),
            String(settings.qt_size),
            String(settings.qt_fixed_font),
            String(settings.qt_fixed_size)
        ])
    }

    Process {
        id: getProcess
        command: ["python3", Quickshell.shellPath("scripts/cursor-font-settings.py"), "get"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.settings = JSON.parse(text)
                    root.status = "Settings loaded"
                } catch (e) {
                    root.status = "Unable to read appearance settings"
                }
            }
        }
    }

    Process {
        id: applyProcess
        onExited: (code) => {
            root.busy = false
            if (code === 0) {
                root.status = "Applied. Restart open apps to refresh their fonts."
                root.refresh()
            } else {
                root.status = "Could not apply settings. Check the backend error."
            }
        }
        stderr: StdioCollector {
            onStreamFinished: if (text.trim()) root.status = text.trim()
        }
    }

    function section(title, description) {
        return title
    }

    GridLayout {
        Layout.fillWidth: true
        columns: 2
        columnSpacing: 14
        rowSpacing: 14

        // Cursor showcase
        Rectangle {
            Layout.columnSpan: 2
            Layout.fillWidth: true
            Layout.preferredHeight: 166
            radius: 8
            color: Tokens.paperLift
            border.width: 1
            border.color: Tokens.line

            RowLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 18

                Rectangle {
                    Layout.preferredWidth: 145
                    Layout.fillHeight: true
                    radius: 6
                    color: Tokens.paper
                    border.width: 1
                    border.color: Tokens.line

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 3

                        Canvas {
                            id: arrow
                            visible: root.previewPath === ""
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredWidth: 64
                            Layout.preferredHeight: 64
                            readonly property real px: Math.max(16, Math.min(64, root.settings.cursor_size))
                            onPxChanged: requestPaint()
                            onPaint: {
                                var c = getContext("2d")
                                c.reset()
                                var p = [[0, 0], [0, 0.85], [0.22, 0.66], [0.37, 1.0],
                                         [0.5, 0.94], [0.35, 0.62], [0.62, 0.62]]
                                c.beginPath()
                                for (var i = 0; i < p.length; i++) {
                                    var x = 2 + p[i][0] * px * 0.95, y = 2 + p[i][1] * px * 0.95
                                    if (i === 0) c.moveTo(x, y); else c.lineTo(x, y)
                                }
                                c.closePath()
                                c.fillStyle = Tokens.ink
                                c.fill()
                                c.lineWidth = 1.5
                                c.strokeStyle = Tokens.paper
                                c.stroke()
                            }
                            Component.onCompleted: requestPaint()
                        }

                        Item {
                            visible: root.previewPath !== ""
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredWidth: 64
                            Layout.preferredHeight: 64

                            Image {
                                anchors.centerIn: parent
                                width: root.previewSize
                                height: root.previewSize
                                source: root.previewPath !== "" ? "file://" + root.previewPath : ""
                                fillMode: Image.PreserveAspectFit
                                smooth: false
                                cache: false
                            }
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "SIZE PREVIEW"
                            color: Tokens.inkMuted
                            font.family: Tokens.ui
                            font.pixelSize: Tokens.fTiny
                            font.letterSpacing: 0.8
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 9

                    RowLayout {
                        Layout.fillWidth: true

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 3

                            Text {
                                text: "Cursor appearance"
                                color: Tokens.ink
                                font.family: Tokens.ui
                                font.pixelSize: 16
                                font.weight: Font.DemiBold
                            }

                            Text {
                                text: "Pointer theme and display size"
                                color: Tokens.inkMuted
                                font.family: Tokens.ui
                                font.pixelSize: Tokens.fTiny
                            }
                        }

                        Text {
                            text: root.settings.cursor_size + " PX"
                            color: Tokens.ink
                            font.family: Tokens.ui
                            font.pixelSize: Tokens.fMicro
                            font.weight: Font.DemiBold
                        }
                    }

                    StyledCombo {
                        font.family: Tokens.ui
                        id: cursorCombo
                        Layout.fillWidth: true
                        model: root.settings.cursor_themes
                        currentIndex: Math.max(0, model.indexOf(root.settings.cursor_theme))
                        onActivated: { root.settings.cursor_theme = currentText; previewTimer.restart() }
                    }

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text: "Cursor size"
                            color: Tokens.ink
                            font.family: Tokens.ui
                            font.pixelSize: Tokens.fMicro
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            font.family: Tokens.ui
                            text: "16"
                            color: Tokens.inkMuted
                            font.pixelSize: Tokens.fTiny
                        }

                        Slid {
                            Layout.preferredWidth: 180
                            from: 16
                            to: 64
                            value: root.settings.cursor_size
                            onModified: v => { root.settings.cursor_size = Math.round(v / 2) * 2; previewTimer.restart() }
                        }

                        Text {
                            font.family: Tokens.ui
                            text: "64"
                            color: Tokens.inkMuted
                            font.pixelSize: Tokens.fTiny
                        }
                    }
                }
            }
        }

        // GTK typography
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumWidth: 0
            Layout.preferredHeight: 260
            radius: 8
            color: Tokens.paperLift
            border.width: 1
            border.color: Tokens.line

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Rectangle {
                        width: 35
                        height: 35
                        radius: 5
                        color: Tokens.paper

                        Text {
                            font.family: Tokens.ui
                            anchors.centerIn: parent
                            text: "Aa"
                            color: Tokens.ink
                            font.pixelSize: 18
                            font.weight: Font.DemiBold
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: "GTK typography"
                            color: Tokens.ink
                            font.family: Tokens.ui
                            font.pixelSize: Tokens.fSmall
                            font.weight: Font.DemiBold
                        }

                        Text {
                            text: "GNOME and GTK applications"
                            color: Tokens.inkMuted
                            font.family: Tokens.ui
                            font.pixelSize: Tokens.fTiny
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Tokens.line
                }

                Text {
                    text: "FONT FAMILY"
                    color: Tokens.inkMuted
                    font.family: Tokens.ui
                    font.pixelSize: Tokens.fTiny
                    font.weight: Font.DemiBold
                    font.letterSpacing: 1
                }

                StyledField {
                    font.family: Tokens.ui
                    Layout.fillWidth: true
                    text: root.settings.gtk_font
                    onEditingFinished: root.settings.gtk_font = text.trim()
                }

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: "Font size"
                        color: Tokens.ink
                        font.family: Tokens.ui
                        font.pixelSize: Tokens.fMicro
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        font.family: Tokens.ui
                        text: root.settings.gtk_size + " pt"
                        color: Tokens.ink
                        font.pixelSize: Tokens.fMicro
                        font.weight: Font.DemiBold
                    }
                }

                Slid {
                    Layout.fillWidth: true
                    from: 8
                    to: 24
                    value: root.settings.gtk_size
                    onModified: v => root.settings.gtk_size = Math.round(v / 1) * 1
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumHeight: 65
                    radius: 5
                    color: Tokens.paper
                    border.width: 1
                    border.color: Tokens.line

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 4

                        Text {
                            text: "The quick brown fox"
                            color: Tokens.ink
                            font.family: root.settings.gtk_font
                            font.pixelSize: root.settings.gtk_size
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        Text {
                            text: "ABCDEFGHIJKLMNOPQRSTUVWXYZ 0123456789"
                            color: Tokens.inkMuted
                            font.family: root.settings.gtk_font
                            font.pixelSize: Math.max(8, root.settings.gtk_size - 2)
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }

        // Qt typography
        Rectangle {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            implicitHeight: qtContent.implicitHeight + 28
            radius: 8
            color: Tokens.paperLift
            border.width: 1
            border.color: Tokens.line

            ColumnLayout {
                id: qtContent
                anchors.fill: parent
                anchors.margins: 14
                spacing: 9

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Rectangle {
                        width: 35
                        height: 35
                        radius: 5
                        color: Tokens.paper

                        Text {
                            font.family: Tokens.ui
                            anchors.centerIn: parent
                            text: "Qt"
                            color: Tokens.ink
                            font.pixelSize: 17
                            font.weight: Font.DemiBold
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: "Qt typography"
                            color: Tokens.ink
                            font.family: Tokens.ui
                            font.pixelSize: Tokens.fSmall
                            font.weight: Font.DemiBold
                        }

                        Text {
                            text: "Interface and fixed-width fonts"
                            color: Tokens.inkMuted
                            font.family: Tokens.ui
                            font.pixelSize: Tokens.fTiny
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Tokens.line
                }

                Text {
                    text: "GENERAL FONT"
                    color: Tokens.inkMuted
                    font.family: Tokens.ui
                    font.pixelSize: Tokens.fTiny
                    font.weight: Font.DemiBold
                    font.letterSpacing: 1
                }

                StyledField {
                    font.family: Tokens.ui
                    Layout.fillWidth: true
                    text: root.settings.qt_font
                    onEditingFinished: root.settings.qt_font = text.trim()
                }

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        font.family: Tokens.ui
                        text: "General size"
                        color: Tokens.ink
                        font.pixelSize: Tokens.fMicro
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        font.family: Tokens.ui
                        text: root.settings.qt_size + " pt"
                        color: Tokens.ink
                        font.pixelSize: Tokens.fMicro
                    }
                }

                Slid {
                    Layout.fillWidth: true
                    from: 8
                    to: 24
                    value: root.settings.qt_size
                    onModified: v => root.settings.qt_size = Math.round(v / 1) * 1
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Tokens.line
                }

                Text {
                    text: "FIXED-WIDTH FONT"
                    color: Tokens.inkMuted
                    font.family: Tokens.ui
                    font.pixelSize: Tokens.fTiny
                    font.weight: Font.DemiBold
                    font.letterSpacing: 1
                }

                StyledField {
                    font.family: Tokens.ui
                    Layout.fillWidth: true
                    text: root.settings.qt_fixed_font
                    onEditingFinished: root.settings.qt_fixed_font = text.trim()
                }

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        font.family: Tokens.ui
                        text: "Monospace size"
                        color: Tokens.ink
                        font.pixelSize: Tokens.fMicro
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        font.family: Tokens.ui
                        text: root.settings.qt_fixed_size + " pt"
                        color: Tokens.ink
                        font.pixelSize: Tokens.fMicro
                    }
                }

                Slid {
                    Layout.fillWidth: true
                    from: 8
                    to: 24
                    value: root.settings.qt_fixed_size
                    onModified: v => root.settings.qt_fixed_size = Math.round(v / 1) * 1
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 42
                    radius: 5
                    color: Tokens.paper
                    border.width: 1
                    border.color: Tokens.line

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 7
                        spacing: 2

                        Text {
                            text: "Aa Bb Cc 012345"
                            color: Tokens.ink
                            font.family: root.settings.qt_font
                            font.pixelSize: root.settings.qt_size
                        }

                        Text {
                            text: "sudo pacman -S package"
                            color: Tokens.inkMuted
                            font.family: root.settings.qt_fixed_font
                            font.pixelSize: root.settings.qt_fixed_size
                        }
                    }
                }
            }
        }

        // Apply footer
        Rectangle {
            Layout.columnSpan: 2
            Layout.fillWidth: true
            implicitHeight: 52
            radius: 7
            color: Tokens.paperLift
            border.width: 1
            border.color: Tokens.line

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 10

                Rectangle {
                    width: 6
                    height: 6
                    radius: 3
                    color: root.status.startsWith("Could not") ? Tokens.alert : Tokens.ink
                }

                Text {
                    Layout.fillWidth: true
                    text: root.status
                    color: root.status.startsWith("Could not") ? Tokens.alert : Tokens.inkMuted
                    font.family: Tokens.ui
                    font.pixelSize: Tokens.fTiny
                    wrapMode: Text.WordWrap
                }

                Button {
                    font.family: Tokens.ui
                    text: root.busy ? "Applying…" : "Apply changes"
                    enabled: !root.busy
                    onClicked: root.apply()
                }
            }
        }
    }

    property string previewPath: ""
    property int previewSize: 36
    readonly property string previewKey: String(settings.cursor_theme) + "|" + String(settings.cursor_size)
    onPreviewKeyChanged: previewTimer.restart()

    Process {
        id: previewProc
        stdout: StdioCollector {
            onStreamFinished: root.previewPath = text.trim()
        }
    }

    Timer {
        id: previewTimer
        interval: 150
        onTriggered: {
            if (previewProc.running) { restart(); return }
            root.previewSize = Math.max(16, Math.min(64, Number(root.settings.cursor_size) || 36))
            previewProc.exec(["python3", Quickshell.shellPath("scripts/cursor-preview.py"),
                String(root.settings.cursor_theme), String(root.settings.cursor_size)])
        }
    }

    Timer {
        interval: 800
        running: true
        onTriggered: previewTimer.restart()
    }

    Component.onCompleted: refresh()
}
