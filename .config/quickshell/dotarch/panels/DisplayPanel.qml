import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import qs
import qs.components

// Display page: back button + title, one card per monitor (brightness for the
// internal panel, scale chips, resolution/refresh picker) and a Night Light card.
// Monitor data comes from `hyprctl monitors -j`; changes go through
// `hyprctl keyword monitor`. Brightness / night light reuse Backend.
FocusScope {
    id: root

    property var monitors: []
    property string expandedMonitor: ""
    readonly property var scaleChoices: [1, 1.25, 1.5, 1.75, 2]
    readonly property bool nlAvailable: Backend.nightLightStatus !== "unavailable"
    readonly property bool nlOn: Backend.nightLightStatus !== "off" && nlAvailable

    function refresh() {
        monitorProc.running = true;
        Backend.refreshStatus();
    }

    function takeInitialFocus() {
        refresh();
        forceActiveFocus(Qt.TabFocusReason);
    }

    function fmtScale(s) {
        const t = (Math.round(s * 100) / 100).toString();
        return (t.indexOf(".") < 0 ? t + ".0" : t) + "×";
    }

    function isInternal(name) {
        return /^(eDP|LVDS|DSI)/i.test(name);
    }

    function modeOf(m) {
        return m.width + "x" + m.height + "@" + m.refreshRate.toFixed(2);
    }

    function isCurrentMode(m, mode) {
        const parts = mode.replace("Hz", "").split("@");
        const size = parts[0];
        const rate = parseFloat(parts[1]);
        return size === m.width + "x" + m.height && Math.abs(rate - m.refreshRate) < 0.05;
    }

    function applyMonitor(m, mode, scale) {
        Quickshell.execDetached(["hyprctl", "keyword", "monitor", m.name + "," + mode + "," + m.x + "x" + m.y + "," + scale]);
        refreshTimer.restart();
    }

    implicitWidth: 400
    implicitHeight: content.implicitHeight
    focus: true
    onVisibleChanged: {
        if (visible)
            refresh();
    }
    Keys.onEscapePressed: ShellState.setPanel("control")
    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Backspace) {
            ShellState.setPanel("control");
            event.accepted = true;
        }
    }

    Timer {
        id: refreshTimer

        interval: 700
        onTriggered: root.refresh()
    }

    Process {
        id: monitorProc

        command: ["hyprctl", "monitors", "-j"]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.monitors = JSON.parse(text);
                } catch (e) {
                    console.warn("DisplayPanel: could not parse hyprctl output", e);
                }
            }
        }
    }

    // ---- small reusable pieces -------------------------------------------
    component VIcon: Shape {
        id: ic

        property string d: ""
        property color col: Theme.foreground
        property real px: 16
        property real sw: 1.8

        width: px
        height: px
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeWidth: ic.sw
            strokeColor: ic.col
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            scale: Qt.size(ic.px / 24, ic.px / 24)

            PathSvg {
                path: ic.d
            }
        }
    }

    component PillSlider: Item {
        id: ps

        property real value: 0
        property string icon: ""

        signal moved(real v)

        height: 26

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            antialiasing: true
            color: Theme.isLight ? Qt.darker(Theme.cardColor, 1.18) : Qt.rgba(1, 1, 1, 0.10)
        }

        Rectangle {
            width: Math.max(parent.height, parent.width * ps.value)
            height: parent.height
            radius: height / 2
            antialiasing: true
            color: Theme.primary

            VIcon {
                anchors.left: parent.left
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                d: ps.icon
                col: Theme.bgDim
                px: 14
            }
        }

        MouseArea {
            anchors.fill: parent
            preventStealing: true
            cursorShape: Qt.PointingHandCursor
            onPressed: (e) => ps.moved(Math.max(0, Math.min(1, e.x / width)))
            onPositionChanged: (e) => {
                if (pressed)
                    ps.moved(Math.max(0, Math.min(1, e.x / width)));
            }
        }
    }

    readonly property string sunPath: "M12 8a4 4 0 1 0 0 8 4 4 0 1 0 0-8Z M12 2v2 M12 20v2 M4.9 4.9l1.4 1.4 M17.7 17.7l1.4 1.4 M2 12h2 M20 12h2 M4.9 19.1l1.4-1.4 M17.7 6.3l1.4-1.4"
    readonly property string moonPath: "M12 3a6 6 0 0 0 9 9 9 9 0 1 1-9-9Z"
    readonly property string monitorPath: "M4 5h16a1 1 0 0 1 1 1v9a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1V6a1 1 0 0 1 1-1Z M9 20h6 M12 16v4"

    // ---- page ------------------------------------------------------------
    Column {
        id: content

        width: parent.width
        spacing: 10

        Row {
            height: 30
            spacing: 10

            Rectangle {
                width: 30
                height: 30
                radius: 15
                antialiasing: true
                color: Theme.isLight ? Qt.darker(Theme.cardColor, 1.1) : Qt.rgba(1, 1, 1, 0.06)
                border.width: 1
                border.color: Theme.cardBorder

                VIcon {
                    anchors.centerIn: parent
                    d: "M15 5l-7 7 7 7"
                    px: 14
                    sw: 2
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: ShellState.setPanel("control")
                }
            }

            ShellText {
                anchors.verticalCenter: parent.verticalCenter
                text: "Display"
                color: Theme.foreground
                font.pixelSize: 15
                font.weight: Font.DemiBold
            }
        }

        Repeater {
            model: root.monitors

            delegate: Rectangle {
                id: card

                required property var modelData
                readonly property bool internal: root.isInternal(modelData.name)
                readonly property bool open: root.expandedMonitor === modelData.name

                width: content.width
                height: mcol.implicitHeight + 24
                radius: Theme.radiusCard
                antialiasing: true
                color: Theme.isLight ? Qt.darker(Theme.cardColor, 1.1) : Qt.rgba(1, 1, 1, 0.06)
                border.width: 1
                border.color: Theme.cardBorder

                Column {
                    id: mcol

                    x: 12
                    y: 12
                    width: parent.width - 24
                    spacing: 10

                    Row {
                        width: parent.width
                        spacing: 10

                        Rectangle {
                            width: 32
                            height: 32
                            radius: 16
                            antialiasing: true
                            color: Qt.rgba(1, 1, 1, 0.12)

                            VIcon {
                                anchors.centerIn: parent
                                d: root.monitorPath
                                col: Theme.muted
                                px: 16
                            }
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 42 - (focusedTag.visible ? focusedTag.width + 10 : 0)
                            spacing: 1

                            ShellText {
                                text: modelData.name
                                color: Theme.foreground
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                            }

                            ShellText {
                                width: parent.width
                                text: modelData.width + "×" + modelData.height + " · " + Math.round(modelData.refreshRate) + " Hz · " + root.fmtScale(modelData.scale)
                                color: Theme.muted
                                elide: Text.ElideRight
                                font.pixelSize: 11
                            }
                        }

                        ShellText {
                            id: focusedTag

                            anchors.verticalCenter: parent.verticalCenter
                            visible: modelData.focused
                            text: "focused"
                            color: Theme.primary
                            font.pixelSize: 11
                        }
                    }

                    // brightness (internal panel only; external monitors have no backlight here)
                    Row {
                        visible: card.internal
                        width: parent.width
                        spacing: 10

                        PillSlider {
                            width: parent.width - 40
                            value: Backend.brightness / 100
                            icon: root.sunPath
                            onMoved: (v) => Backend.setBrightness(v * 100)
                        }

                        ShellText {
                            width: 30
                            anchors.verticalCenter: parent.verticalCenter
                            horizontalAlignment: Text.AlignRight
                            text: Backend.brightness + "%"
                            color: Theme.muted
                            font.pixelSize: 11
                        }
                    }

                    // scale chips
                    Row {
                        width: parent.width
                        spacing: 6

                        Repeater {
                            model: root.scaleChoices

                            delegate: Rectangle {
                                required property real modelData
                                readonly property bool active: Math.abs(card.modelData.scale - modelData) < 0.01

                                width: (mcol.width - 4 * 6) / 5
                                height: 28
                                radius: 9
                                antialiasing: true
                                color: active ? Theme.primary : (Theme.isLight ? Qt.darker(Theme.cardColor, 1.18) : Qt.rgba(1, 1, 1, 0.08))

                                Behavior on color {
                                    ColorAnimation {
                                        duration: Theme.animationFast
                                    }
                                }

                                ShellText {
                                    anchors.centerIn: parent
                                    text: root.fmtScale(parent.modelData)
                                    color: parent.active ? Theme.bgDim : Theme.foreground
                                    font.pixelSize: 11
                                    font.weight: Font.Medium
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.applyMonitor(card.modelData, root.modeOf(card.modelData), parent.modelData)
                                }
                            }
                        }
                    }

                    // resolution row
                    Rectangle {
                        width: parent.width
                        height: 34
                        radius: 10
                        antialiasing: true
                        color: Theme.isLight ? Qt.darker(Theme.cardColor, 1.18) : Qt.rgba(1, 1, 1, 0.06)

                        ShellText {
                            anchors.left: parent.left
                            anchors.leftMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Resolution"
                            color: Theme.muted
                            font.pixelSize: 11
                        }

                        ShellText {
                            anchors.right: chev.left
                            anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            text: card.modelData.width + "×" + card.modelData.height + " @ " + Math.round(card.modelData.refreshRate) + " Hz"
                            color: Theme.foreground
                            font.pixelSize: 11
                            font.weight: Font.Medium
                        }

                        VIcon {
                            id: chev

                            anchors.right: parent.right
                            anchors.rightMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            d: card.open ? "M6 9l6 6 6-6" : "M9 6l6 6-6 6"
                            col: Theme.muted
                            px: 13
                            sw: 2
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.expandedMonitor = card.open ? "" : card.modelData.name
                        }
                    }

                    // available modes (expanded)
                    Column {
                        visible: card.open
                        width: parent.width
                        spacing: 4

                        Repeater {
                            model: card.modelData.availableModes

                            delegate: Rectangle {
                                required property string modelData
                                readonly property bool current: root.isCurrentMode(card.modelData, modelData)

                                width: parent.width
                                height: 28
                                radius: 8
                                antialiasing: true
                                color: current ? Qt.alpha(Theme.primary, 0.22) : "transparent"

                                ShellText {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: parent.modelData.replace("@", " @ ").replace("Hz", " Hz")
                                    color: parent.current ? Theme.primary : Theme.foreground
                                    font.pixelSize: 11
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.applyMonitor(card.modelData, parent.modelData.replace("Hz", ""), card.modelData.scale)
                                }
                            }
                        }
                    }
                }
            }
        }

        // night light
        Rectangle {
            width: content.width
            height: ncol.implicitHeight + 24
            radius: Theme.radiusCard
            antialiasing: true
            opacity: root.nlAvailable ? 1 : 0.4
            color: Theme.isLight ? Qt.darker(Theme.cardColor, 1.1) : Qt.rgba(1, 1, 1, 0.06)
            border.width: 1
            border.color: Theme.cardBorder

            Column {
                id: ncol

                x: 12
                y: 12
                width: parent.width - 24
                spacing: 10

                Row {
                    width: parent.width
                    spacing: 10

                    Rectangle {
                        width: 32
                        height: 32
                        radius: 16
                        antialiasing: true
                        color: root.nlOn ? Theme.primary : Qt.rgba(1, 1, 1, 0.12)

                        VIcon {
                            anchors.centerIn: parent
                            d: root.moonPath
                            col: root.nlOn ? Theme.bgDim : Theme.muted
                            px: 16
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 42 - 44
                        spacing: 1

                        ShellText {
                            text: "Night Light"
                            color: Theme.foreground
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                        }

                        ShellText {
                            text: ShellState.nightLightTemperature + " K"
                            color: Theme.muted
                            font.pixelSize: 11
                        }
                    }

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 40
                        height: 22
                        radius: 11
                        antialiasing: true
                        color: root.nlOn ? Theme.primary : (Theme.isLight ? Qt.darker(Theme.cardColor, 1.25) : Qt.rgba(1, 1, 1, 0.14))

                        Behavior on color {
                            ColorAnimation {
                                duration: Theme.animationFast
                            }
                        }

                        Rectangle {
                            y: 3
                            x: root.nlOn ? parent.width - width - 3 : 3
                            width: 16
                            height: 16
                            radius: 8
                            antialiasing: true
                            color: root.nlOn ? Theme.bgDim : Theme.foreground

                            Behavior on x {
                                NumberAnimation {
                                    duration: 140
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: root.nlAvailable
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Backend.toggleNightLight()
                        }
                    }
                }

                PillSlider {
                    width: parent.width
                    // warmer (lower K) fills further, like the reference
                    value: (6000 - ShellState.nightLightTemperature) / 3500
                    icon: root.moonPath
                    onMoved: (v) => Backend.setNightLightTemperature(6000 - v * 3500)
                }
            }
        }
    }
}
