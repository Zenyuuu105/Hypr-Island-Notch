import QtQuick
import QtQuick.Shapes
import QtQuick.Effects
import Quickshell
import Quickshell.Networking
import Quickshell.Services.UPower
import Quickshell.Widgets
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Services.Notifications
import Quickshell.Services.Pipewire
import qs.components
import qs.panels

PanelWindow {

    property bool focusedFloating: false
    WlrLayershell.layer: focusedFloating ? WlrLayer.Bottom : WlrLayer.Top
    function updateFloating() {
        const t = Hyprland.activeToplevel
        focusedFloating = (t && t.lastIpcObject) ? t.lastIpcObject.floating === true : false
    }
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "changefloatingmode" || event.name === "activewindowv2") {
                Hyprland.refreshToplevels()
                floatRefresh.restart()
            }
        }
    }
    Timer {
        id: floatRefresh
        interval: 60
        onTriggered: window.updateFloating()
    }
    Timer {
        id: floatInit
        interval: 300
        running: true
        onTriggered: { Hyprland.refreshToplevels(); window.updateFloating() }
    }

    id: window

    property real springOmega: 23
    property real springZeta: 0.78
    property real springOmegaUp: 21
    property real springZetaUp: 0.8
    property real springOmegaDown: 24
    property real springZetaDown: 0.95

    readonly property int contentPadding: 14
    readonly property bool attached: NotchSettings.cfg.shape === "notch"
    readonly property string clockFormat: NotchSettings.cfg.clock24h ? (NotchSettings.cfg.showSeconds ? "HH:mm:ss" : "HH:mm") : (NotchSettings.cfg.showSeconds ? "h:mm:ss AP" : "h:mm AP")
    readonly property int collapsedHeight: NotchSettings.cfg.collapsedHeight
    readonly property int islandMargin: attached ? 0 : NotchSettings.cfg.islandTopMargin
    readonly property int cornerWing: attached ? NotchSettings.cfg.notchFlare : 0
    readonly property int hoverHeight: NotchSettings.cfg.expandedHeight
    readonly property int osdHeight: 46
    readonly property bool morphOpening: (ShellState.expanded || ShellState.hovered || ShellState.osdActive || ShellState.notifActive || ShellState.authActive)
    readonly property int morphDuration: NotchSettings.cfg.animationsEnabled ? NotchSettings.cfg.animationDuration : 1
    readonly property real morphOvershoot: (morphOpening && NotchSettings.cfg.animationsEnabled) ? 1.6 : 0
    readonly property real openFrac: (openH - compactHeight) < 24 ? (ShellState.expanded ? 1 : 0) : Math.max(0, Math.min(1, (hSpring.value - compactHeight) / (openH - compactHeight)))
    readonly property real bodyBottomRadius: Math.min(NotchSettings.cfg.cornerRadius + (NotchSettings.cfg.panelRadius - NotchSettings.cfg.cornerRadius) * openFrac, notchBody.height / 2)
    readonly property var wifiDevice: Networking.devices.values.find((d) => d.type === DeviceType.Wifi)
    readonly property var wifiNet: wifiDevice ? wifiDevice.networks.values.find((x) => x.connected) : null
    readonly property bool wifiConnected: wifiNet !== null && wifiNet !== undefined
    readonly property real wifiSignal: wifiConnected ? wifiNet.signalStrength : 0
    readonly property real batteryLevel: UPower.displayDevice ? UPower.displayDevice.percentage : 0
    readonly property bool batteryCharging: UPower.displayDevice && (!UPower.onBattery || UPower.displayDevice.state === UPowerDeviceState.Charging || UPower.displayDevice.state === UPowerDeviceState.PendingCharge)
    readonly property int notifHeight: 66
    readonly property int authHeight: authColumn.implicitHeight + 32
    readonly property int compactHeight: ShellState.authActive ? authHeight : (ShellState.osdActive ? osdHeight : (ShellState.notifActive ? notifHeight : (ShellState.hovered ? hoverHeight : collapsedHeight)))
    readonly property int notifTimeout: 5000
    readonly property var hoverPlayer: {
        const list = Mpris.players.values;
        const playing = list.find((p) => p.isPlaying);
        return playing || (list.length > 0 ? list[0] : null);
    }
    readonly property real canvasWidth: Math.max(640, themePanel.implicitWidth + cornerWing * 2 + 24, wallpaperPanel.implicitWidth + cornerWing * 2 + 24, NotchSettings.cfg.panelWidth + cornerWing * 2 + 24, NotchSettings.cfg.expandedWidth + cornerWing * 2 + 24, NotchSettings.cfg.collapsedWidth + cornerWing * 2 + 24)
    readonly property real canvasHeight: Math.max(740, NotchSettings.cfg.panelHeight + requestedTopPadding + requestedBottomPadding + islandMargin + 24, NotchSettings.cfg.expandedHeight + islandMargin + 24, Math.max(controlPanel.implicitHeight, themePanel.implicitHeight, wallpaperPanel.implicitHeight) + requestedTopPadding + requestedBottomPadding + islandMargin + 24)
    readonly property int requestedTopPadding: (ShellState.panel === "theme" || ShellState.panel === "wallpaper") ? 0 : (ShellState.panel === "launcher" ? 10 : (ShellState.panel === "control" ? contentPadding : contentPadding))
    readonly property int requestedBottomPadding: (ShellState.panel === "theme" || ShellState.panel === "wallpaper") ? 0 : (ShellState.panel === "launcher" ? 4 : ((ShellState.panel === "control" || ShellState.panel === "display") ? 12 : contentPadding))
    readonly property int displayedTopPadding: (displayedPanel === "theme" || displayedPanel === "wallpaper") ? 0 : (displayedPanel === "launcher" ? 10 : (displayedPanel === "control" ? contentPadding : contentPadding))
    readonly property int displayedBottomPadding: (displayedPanel === "theme" || displayedPanel === "wallpaper") ? 0 : (displayedPanel === "launcher" ? 4 : ((displayedPanel === "control" || displayedPanel === "display") ? 12 : contentPadding))
    readonly property real restGap: 14
    readonly property real restLeftW: NotchSettings.cfg.showWorkspaces ? restDots.implicitWidth : 0
    readonly property real restClockW: NotchSettings.cfg.showClock ? restClock.implicitWidth : 0
    readonly property real restExtrasW: restExtras.implicitWidth > 0 ? restExtras.implicitWidth + 8 : 0
    readonly property real restRightW: restStatus.implicitWidth
    readonly property real restClockGroupW: restClockW + restExtrasW
    readonly property real restClockX: {
        if (restLeftW > 0 && restRightW > 0)
            return Math.max(restLeftW + restGap, restRightW + restGap + restExtrasW)
        if (restLeftW > 0)
            return restLeftW + restGap
        if (restRightW > 0)
            return 0
        return 0
    }
    readonly property real collapsedContentWidth: {
        let inner
        if (restClockGroupW === 0) {
            inner = restLeftW + restRightW + (restLeftW > 0 && restRightW > 0 ? restGap : 0)
        } else if (restLeftW > 0 && restRightW > 0) {
            inner = 2 * Math.max(restLeftW + restGap, restRightW + restGap + restExtrasW) + restClockW
        } else if (restLeftW > 0) {
            inner = restLeftW + restGap + restClockGroupW
        } else if (restRightW > 0) {
            inner = restClockGroupW + restGap + restRightW
        } else {
            inner = restClockGroupW
        }
        return Math.max(100, inner + 52)
    }
    readonly property real baseWidth: {
        if (ShellState.expanded)
            return ShellState.panel === "theme" ? themePanel.implicitWidth : ShellState.panel === "wallpaper" ? wallpaperPanel.implicitWidth : (NotchSettings.cfg.panelWidth > 0 ? NotchSettings.cfg.panelWidth : ShellState.targetWidth);
        if (ShellState.authActive || ShellState.osdActive || ShellState.notifActive)
            return ShellState.targetWidth;
        if (ShellState.hovered)
            return NotchSettings.cfg.expandedWidth > 0 ? NotchSettings.cfg.expandedWidth : ShellState.targetWidth;
        return NotchSettings.cfg.collapsedWidth > 0 ? NotchSettings.cfg.collapsedWidth : collapsedContentWidth;
    }
    readonly property real targetVisualWidth: baseWidth + cornerWing * 2
    readonly property real restWidth: NotchSettings.cfg.collapsedWidth > 0 ? NotchSettings.cfg.collapsedWidth : collapsedContentWidth
    readonly property real hoverFinalW: NotchSettings.cfg.expandedWidth > 0 ? NotchSettings.cfg.expandedWidth : ShellState.targetWidth
    readonly property real hoverContentW: Math.max(120, hoverFinalW - 36)
    readonly property real restVisualW: restWidth + cornerWing * 2
    readonly property real hoverVisualW: hoverFinalW + cornerWing * 2
    readonly property bool hoverPhase: !closing && !panelWidthSettling && !ShellState.expanded && !ShellState.osdActive && !ShellState.notifActive && !ShellState.authActive
    readonly property real hoverProg: hoverPhase && hoverProgressReady ? Math.max(0, Math.min(1, (wSpring.value - restVisualW) / Math.max(1, hoverVisualW - restVisualW))) : 0
    readonly property real hoverReveal: 1
    readonly property real pillReveal: 1
    readonly property real targetVisualHeight: ShellState.expanded ? panelContentHeight + requestedTopPadding + requestedBottomPadding : compactHeight
    readonly property real panelContentHeight: ShellState.expanded ? (ShellState.panel === "theme" ? themePanel.implicitHeight : ShellState.panel === "wallpaper" ? wallpaperPanel.implicitHeight : (ShellState.panel === "control" || ShellState.panel === "display") ? controlPanel.implicitHeight : (NotchSettings.cfg.panelHeight > 0 ? NotchSettings.cfg.panelHeight : Math.max(ShellState.panelHeights[ShellState.panel] || 0, requestedPanel ? requestedPanel.implicitHeight : 0))) : 0
    property bool contentRevealed: false
    property real openH: 0
    property real openW: 0
    onTargetVisualHeightChanged: { if (ShellState.expanded) { openH = targetVisualHeight; updateLock() } }
    onTargetVisualWidthChanged: { if (ShellState.expanded) { openW = targetVisualWidth; updateLock() } }
    property bool closing: false
    property bool panelWidthSettling: false
    property bool hoverProgressReady: false
    property real settle: 1
    function stag(d) { return Math.max(0, (settle - d) / (1 - d)) }
    readonly property bool settleTrigger: closing && remainMax < 0.5
    onClosingChanged: {
        if (closing) {
            settle = 0;
            panelWidthSettling = true;
        } else if (!settleAnim.running) {
            settle = 1;
        }
    }
    onSettleTriggerChanged: { if (settleTrigger) settleAnim.restart() }
    NumberAnimation {
        id: settleAnim
        target: window
        property: "settle"
        from: 0
        to: 1
        duration: 520
        easing.type: Easing.OutBack
        easing.overshoot: 1.1
    }
    property bool hoverBlock: false
    property bool panelHoverRearm: false
    Timer { id: hoverBlockTimer; interval: 420; onTriggered: window.hoverBlock = false }

    Timer {
        id: panelHoverRearmTimer
        interval: 200
        onTriggered: {
            if (!notchHoverHandler.hovered)
                window.panelHoverRearm = false;
        }
    }
    Timer { id: closeEndTimer; interval: 700; onTriggered: window.closing = false }

    // Wait for panel-close springs to reach the collapsed dimensions.
    Timer {
        id: panelSettleTimer
        interval: 50
        repeat: true
        running: window.panelWidthSettling && !window.closing && !ShellState.expanded
        property int stableTicks: 0

        onRunningChanged: {
            if (running)
                stableTicks = 0;
        }

        onTriggered: {
            const widthDone = Math.abs(wSpring.value - window.restVisualW) < 1.0;
            const heightDone = Math.abs(hSpring.value - window.compactHeight) < 1.0;

            stableTicks = widthDone && heightDone ? stableTicks + 1 : 0;

            if (stableTicks >= 3)
                window.panelWidthSettling = false;
        }
    }
    Connections {
        target: ShellState
        function onExpandedChanged() {
            if (ShellState.expanded) window.updateLock();
            window.closing = !ShellState.expanded;
            if (window.closing) {
                closeEndTimer.restart();
                window.hoverBlock = true;
                window.panelHoverRearm = true;
                panelHoverRearmTimer.restart();
                hoverBlockTimer.restart();
                hoverEnterTimer.stop();
                hoverExitTimer.stop();
                ShellState.hovered = false;
            }
        }
    }
    function frac(v, t, o) {
        var d = o - t;
        return d < 20 ? -1 : Math.max(0, Math.min(1, (v - t) / d));
    }
    readonly property real remainH: frac(hSpring.value, compactHeight, openH)
    readonly property real remainW: frac(wSpring.value, targetVisualWidth, openW)
    readonly property real remainMin: remainH < 0 ? Math.max(0, remainW) : (remainW < 0 ? remainH : Math.min(remainH, remainW))
    readonly property real remainMax: Math.max(0, remainH, remainW)
    readonly property real closeFade: {
        if (ShellState.expanded || !closing) return 0;
        var f = Math.max(0, Math.min(1, (remainMax - 0.40) / 0.40));
        return f;
    }
    readonly property real openFade: Math.max(0, Math.min(1, (remainMax - 0.10) / 0.40))
    readonly property real pillIn: closing ? 1 - Math.max(0, Math.min(1, (remainMax - 0.15) / 0.40)) : 1

    Timer { id: revealTimer; interval: 12; onTriggered: window.contentRevealed = ShellState.expanded }
    Timer {
        id: swapTimer
        interval: 70
        onTriggered: {
            window.displayedPanel = ShellState.panel;
            window.contentRevealed = ShellState.expanded;
        }
    }
    property var visualizerBars: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    property bool clockRevealed: true
    property real lockW: 0
    property real lockH: 0
    property string displayedPanel: "control"

    function updateLock() {
        if (!ShellState.expanded) return;
        lockW = baseWidth - 2 * ((displayedPanel === "theme" || displayedPanel === "wallpaper" || displayedPanel === "launcher") ? 0 : contentPadding);
        lockH = targetVisualHeight - displayedTopPadding - displayedBottomPadding;
    }
    onDisplayedPanelChanged: updateLock()
    readonly property Item activePanel: {
        const panels = {
            "control": controlPanel,
            "launcher": launcherPanel,
            "clipboard": clipboardPanel,
            "todo": todoPanel,
            "notes": quickNotesPanel,
            "theme": themePanel,
            "wallpaper": wallpaperPanel,
            "capture": capturePanel,
            "power": powerPanel,
            "display": displayPanel,
            "notifications": notificationsPanel,
            "calendar": calendarPanel
        };
        return panels[displayedPanel] || null;
    }
    readonly property Item requestedPanel: {
        const panels = {
            "control": controlPanel,
            "launcher": launcherPanel,
            "clipboard": clipboardPanel,
            "todo": todoPanel,
            "notes": quickNotesPanel,
            "theme": themePanel,
            "wallpaper": wallpaperPanel,
            "capture": capturePanel,
            "power": powerPanel,
            "display": displayPanel,
            "notifications": notificationsPanel,
            "calendar": calendarPanel
        };
        return panels[ShellState.panel] || null;
    }

    function showOsd(kind, value, muted) {
        if (!osdArmed || ShellState.expanded)
            return;

        ShellState.osdKind = kind;
        ShellState.osdValue = value;
        ShellState.osdMuted = muted;
        ShellState.osdActive = true;
        osdTimer.restart();
    }

    function focusInitialControl() {
        if (!ShellState.expanded || !activePanel)
            return;

        if (typeof activePanel.takeInitialFocus === "function") {
            activePanel.takeInitialFocus();
            return;
        }
        activePanel.forceActiveFocus(Qt.TabFocusReason);
        const firstControl = activePanel.nextItemInFocusChain(true);
        if (firstControl && firstControl !== activePanel)
            firstControl.forceActiveFocus(Qt.TabFocusReason);
    }

    function moveFocus(forward) {
        const current = window.activeFocusItem;
        if (!current) {
            focusInitialControl();
            return;
        }
        const target = current.nextItemInFocusChain(forward);
        if (target)
            target.forceActiveFocus(forward ? Qt.TabFocusReason : Qt.BacktabFocusReason);
    }

    margins.left: Math.round((screen.width - canvasWidth) / 2)
    implicitWidth: canvasWidth
    implicitHeight: canvasHeight
    color: "transparent"
    aboveWindows: ShellState.notchAboveWindows
    focusable: ShellState.expanded || ShellState.authActive
    exclusionMode: ExclusionMode.Ignore

    anchors {
        top: true
        left: true
    }

    Connections {
        function onPanelChanged() {
            if (ShellState.expanded) {
                ShellState.osdActive = false;
                ShellState.hovered = false;
                clockRevealTimer.stop();
                window.clockRevealed = false;
                focusTimer.restart();
                if (window.contentRevealed && window.displayedPanel !== ShellState.panel) {
                    // panel -> panel: fade out, swap while invisible, fade in
                    window.contentRevealed = false;
                    swapTimer.restart();
                } else if (!window.contentRevealed) {
                    // pill -> panel: let the body open first
                    window.displayedPanel = ShellState.panel;
                    revealTimer.restart();
                }
            } else {
                revealTimer.stop();
                swapTimer.stop();
                window.contentRevealed = false;
                hoverEnterTimer.stop();
                hoverExitTimer.stop();
                ShellState.hovered = false;
                window.clockRevealed = true;
            }
        }

        target: ShellState
    }

    FocusScope {
        id: notchSurface

        anchors.top: parent.top
        anchors.topMargin: window.islandMargin
        anchors.horizontalCenter: parent.horizontalCenter
        width: wSpring.value
        height: hSpring.value
        focus: true
        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Escape) {
                ShellState.close();
                event.accepted = true;
                return;
            }
            if (event.key === Qt.Key_Down || event.key === Qt.Key_Right) {
                window.moveFocus(true);
                event.accepted = true;
                return;
            }
            if (event.key === Qt.Key_Up || event.key === Qt.Key_Left) {
                window.moveFocus(false);
                event.accepted = true;
                return;
            }
        }

        Rectangle {
            id: notchBody

            x: window.cornerWing
            y: 0
            width: parent.width - window.cornerWing * 2
            height: parent.height
            topLeftRadius: window.attached ? 0 : window.bodyBottomRadius
            topRightRadius: window.attached ? 0 : window.bodyBottomRadius
            bottomLeftRadius: window.bodyBottomRadius
            bottomRightRadius: window.bodyBottomRadius
            color: Theme.shellBackground
            layer.enabled: false
        }

        Shape {
            visible: window.attached
            x: 0
            width: window.cornerWing
            height: window.cornerWing
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                id: leftShoulderPath

                readonly property real size: window.cornerWing

                strokeWidth: 0
                fillColor: Theme.shellBackground
                startX: 0
                startY: 0

                PathLine {
                    x: leftShoulderPath.size
                    y: 0
                }

                PathLine {
                    x: leftShoulderPath.size
                    y: leftShoulderPath.size
                }

                PathCubic {
                    control1X: leftShoulderPath.size
                    control1Y: leftShoulderPath.size * 0.448
                    control2X: leftShoulderPath.size * 0.552
                    control2Y: 0
                    x: 0
                    y: 0
                }
            }
        }

        Shape {
            visible: window.attached
            x: parent.width - width
            width: window.cornerWing
            height: window.cornerWing
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                id: rightShoulderPath

                readonly property real size: window.cornerWing

                strokeWidth: 0
                fillColor: Theme.shellBackground
                startX: rightShoulderPath.size
                startY: 0

                PathLine {
                    x: 0
                    y: 0
                }

                PathLine {
                    x: 0
                    y: rightShoulderPath.size
                }

                PathCubic {
                    control1X: 0
                    control1Y: rightShoulderPath.size * 0.448
                    control2X: rightShoulderPath.size * 0.448
                    control2Y: 0
                    x: rightShoulderPath.size
                    y: 0
                }
            }
        }

        Item {
            id: compactStatus

            Row {
                id: restExtras
                anchors.left: restClock.right
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6

                ShellText {
                    visible: NotchSettings.cfg.showDate
                    anchors.verticalCenter: parent.verticalCenter
                    text: Qt.formatDate(clock.date, "MMM d")
                    color: Theme.muted
                    font.pixelSize: 12
                }
                ShellText {
                    visible: NotchSettings.cfg.showMedia && !!window.hoverPlayer
                    anchors.verticalCenter: parent.verticalCenter
                    text: "\uDB81\uDF5A"
                    font.family: Theme.iconFontFamily
                    color: Theme.muted
                    font.pixelSize: 14
                }
                ShellText {
                    visible: NotchSettings.cfg.showVolume
                    anchors.verticalCenter: parent.verticalCenter
                    text: "\uDB81\uDD7E"
                    font.family: Theme.iconFontFamily
                    color: Theme.muted
                    font.pixelSize: 14
                }
                ShellText {
                    visible: NotchSettings.cfg.showBluetooth
                    anchors.verticalCenter: parent.verticalCenter
                    text: "\uDB80\uDCAF"
                    font.family: Theme.iconFontFamily
                    color: Theme.muted
                    font.pixelSize: 14
                }
                NotchBell {
                    visible: NotchSettings.cfg.showBell
                    anchors.verticalCenter: parent.verticalCenter
                    tint: Theme.muted
                }
            }


            anchors.horizontalCenter: notchBody.horizontalCenter
            anchors.top: parent.top
            width: window.restWidth - 52
            height: window.collapsedHeight
            visible: opacity > 0
            property real gate: window.clockRevealed && !ShellState.hovered && !ShellState.osdActive && !ShellState.notifActive && !ShellState.authActive ? 1 : 0
            opacity: gate * window.pillReveal
            Behavior on gate {
                enabled: !window.closing
                NumberAnimation { duration: 80; easing.type: Easing.OutCubic }
            }

            WorkspaceDots {
                id: restDots
                visible: NotchSettings.cfg.showWorkspaces
                opacity: visible ? Math.min(1, window.stag(0)) : 0
                Behavior on opacity { enabled: window.settle >= 1; NumberAnimation { duration: 120 } }
                scale: 0.82 + 0.18 * window.stag(0)
                transform: Translate { x: (1 - window.stag(0)) * 8; y: (1 - window.stag(0)) * 4 }
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
            }

            RollingClock {
                id: restClock
                visible: NotchSettings.cfg.showClock
                opacity: visible ? Math.min(1, window.stag(0.12)) * (clockBridge.bridgeContext ? 0 : 1) : 0
                scale: 0.82 + 0.18 * window.stag(0.12)
                transform: Translate { y: (1 - window.stag(0.12)) * 5 }
                x: window.restClockX
                anchors.verticalCenter: parent.verticalCenter
                Behavior on x {
                    SpringAnim {}
                }
                timeText: Qt.formatDateTime(clock.date, window.clockFormat)
                textColor: Theme.shellForeground
                textSize: 16
            }

            Row {
                id: restStatus
                opacity: Math.min(1, window.stag(0.24))
                scale: 0.82 + 0.18 * window.stag(0.24)
                transform: Translate { x: -(1 - window.stag(0.24)) * 8; y: (1 - window.stag(0.24)) * 4 }
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 5

                WifiGlyph {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: NotchSettings.cfg.showWifi
                    connected: window.wifiConnected
                    level: window.wifiSignal
                }

                BatteryGlyph {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: NotchSettings.cfg.showBattery
                    level: window.batteryLevel
                    charging: window.batteryCharging
                }
            }

        }

        Item {
            id: statusHeader

            onVisibleChanged: {
                if (visible && restDots.visible) {
                    const p = restDots.mapToItem(hoverLayout.contentItem, 0, 0)
                    hoverLayout.restDotsRect = Qt.rect(p.x, p.y, restDots.width, restDots.height)
                } else {
                    hoverLayout.restDotsRect = Qt.rect(0, 0, 0, 0)
                }
            }

            readonly property var player: window.hoverPlayer
            readonly property bool playing: !!player && player.isPlaying

            z: 2
            anchors.left: notchBody.left
            anchors.right: notchBody.right
            anchors.top: parent.top
            height: window.hoverHeight
            anchors.leftMargin: 18
            anchors.rightMargin: 18
            clip: true
            property real gate: ShellState.hovered && !ShellState.osdActive && !ShellState.notifActive && !ShellState.authActive && !ShellState.expanded ? window.pillIn : 0
            visible: gate > 0
            opacity: gate * window.hoverReveal

            Behavior on gate {
                NumberAnimation {
                    duration: ShellState.hovered ? 0 : 55
                    easing.type: Easing.OutCubic
                }
            }

            component MediaButton: Item {
                id: mediaButton

                property string glyph: ""
                property bool dim: false

                signal clicked()

                width: 22
                height: 22

                ShellText {
                    anchors.centerIn: parent
                    text: mediaButton.glyph
                    font.family: Theme.iconFontFamily
                    color: mediaButton.dim ? Theme.mutedDark : Theme.shellForeground
                    font.pixelSize: 18
                }

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -4
                    cursorShape: Qt.PointingHandCursor
                    onClicked: mediaButton.clicked()
                }
            }

            HoverLayout {
                id: hoverLayout
                externalClock: true
                clockMix: clockBridge.mixOut
                anchors.fill: parent
                player: window.hoverPlayer
                date: clock.date
                timeFormat: window.clockFormat
                showClock: NotchSettings.cfg.showHoverClock
                showDate: NotchSettings.cfg.showHoverDate
                showMedia: NotchSettings.cfg.showHoverMedia
                showWorkspaces: NotchSettings.cfg.showHoverWorkspaces
                onClockClicked: ShellState.show("calendar")
            }
        }

        Item {
            id: clockBridge
            // clockTravelV2 clockFinalV3
            z: 6
            anchors.fill: parent

            readonly property bool ctx: !ShellState.osdActive && !ShellState.notifActive && !ShellState.authActive && !ShellState.expanded && !window.closing && !window.panelWidthSettling
            readonly property bool hoverOn: ShellState.hovered && ctx

            // Progress follows the actual notch width spring.
            readonly property real prog: window.hoverProg

            readonly property real c: {
                const p = Math.max(0, Math.min(1, prog))
                return hoverOn ? Math.min(1, p / 0.85) : 1 - Math.pow(1 - p, 2)
            }

            // Keep one clock instance throughout the collapsed-to-hover transition.
            readonly property bool bridgeContext: ctx && (!ShellState.hovered || NotchSettings.cfg.showHoverClock)
            visible: NotchSettings.cfg.showClock && bridgeContext

            function mix(a, b, t) {
                return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, 1)
            }

            // Smoothly crossfade into and out of the hover clock
            readonly property real mixOut: {
                const t = Math.max(0, Math.min(1, (c - 0.88) / 0.12))
                return t * t * (3 - 2 * t)
            }

            RollingClock {
                id: bridgeClock
                transformOrigin: Item.TopLeft
                opacity: 1 - clockBridge.mixOut

                timeText: Qt.formatDateTime(clock.date, window.clockFormat)
                clockFont: restClock.clockFont
                textSize: 16
                textColor: clockBridge.mix(Theme.shellForeground, hoverLayout.clockColor, clockBridge.c)

                readonly property real hoverScale: 22 * hoverLayout.u / textSize
                scale: 1 + (hoverScale - 1) * clockBridge.c

                x: {
                    const a = restClock.mapToItem(clockBridge, 0, 0)
                    const b = hoverLayout.clockItem.mapToItem(clockBridge, 0, 0)
                    return notchSurface.width >= 0 ? a.x + (b.x - a.x) * clockBridge.c : 0
                }

                y: {
                    const a = restClock.mapToItem(clockBridge, 0, 0)
                    const b = hoverLayout.clockItem.mapToItem(clockBridge, 0, 0)
                    return notchSurface.height >= 0 ? a.y + (b.y - a.y) * clockBridge.c : 0
                }
            }
        }

        Item {
            anchors.left: notchBody.left
            anchors.right: notchBody.right
            anchors.top: parent.top
            height: window.osdHeight
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            visible: opacity > 0
            opacity: ShellState.osdActive && !ShellState.authActive && !ShellState.expanded ? 1 : 0

                        VectorIcon {
                id: osdIcon

                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter

                name: ShellState.osdKind === "brightness"
                      ? "sun"
                      : (ShellState.osdMuted ? "mute" : "volume")

                value: ShellState.osdValue
                color: Theme.shellForeground
                size: 22
            }

            Rectangle {
                anchors.left: osdIcon.right
                anchors.leftMargin: 10
                anchors.right: osdPercent.left
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                height: 6
                radius: 3
                color: Qt.alpha(Theme.shellForeground, 0.16)

                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    radius: 3
                    color: Theme.primary
                    width: parent.width * (ShellState.osdMuted ? 0 : Math.max(0, Math.min(1, ShellState.osdValue)))

                    Behavior on width {
                        SpringAnim {}
                    }
                }
            }

            ShellText {
                id: osdPercent

                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                horizontalAlignment: Text.AlignRight
                width: 50
                text: ShellState.osdMuted ? "Muted" : Math.round(Math.max(0, Math.min(1, ShellState.osdValue)) * 100) + "%"
                color: Theme.muted
                font.pixelSize: 16
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: 100
                    easing.type: Easing.OutCubic
                }
            }
        }

        Item {
            id: notifItem

            anchors.left: notchBody.left
            anchors.right: notchBody.right
            anchors.top: parent.top
            height: window.notifHeight
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            visible: opacity > 0
            opacity: ShellState.notifActive && !ShellState.osdActive && !ShellState.authActive && !ShellState.expanded ? 1 : 0

            readonly property var notif: ShellState.activeNotification
            readonly property bool critical: notif !== null && notif.urgency === NotificationUrgency.Critical
            readonly property color notifAccent: critical ? Theme.red : Theme.primary

            MouseArea {
                id: notifHover

                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                hoverEnabled: true
            }

            Rectangle {
                id: notifAvatar

                width: 34
                height: 34
                radius: 11
                color: Qt.rgba(notifItem.notifAccent.r, notifItem.notifAccent.g, notifItem.notifAccent.b, 0.13)
                anchors.verticalCenter: parent.verticalCenter

                ShellText {
                    anchors.centerIn: parent
                    text: "\udb80\udd5a"
                    color: notifItem.notifAccent
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 21
                }
            }

            Column {
                anchors.left: notifAvatar.right
                anchors.leftMargin: 10
                anchors.right: notifClose.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                ShellText {
                    width: parent.width
                    text: notifItem.notif && notifItem.notif.appName ? notifItem.notif.appName : "Notification"
                    color: notifItem.notifAccent
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }

                ShellText {
                    width: parent.width
                    text: notifItem.notif ? String(notifItem.notif.summary).replace(/\s*\n+\s*/g, " ") : ""
                    font.pixelSize: 15
                    font.weight: Font.Bold
                    wrapMode: Text.NoWrap
                    elide: Text.ElideRight
                }

                ShellText {
                    width: parent.width
                    visible: notifItem.notif && notifItem.notif.body.length > 0
                    text: notifItem.notif ? String(notifItem.notif.body).replace(/\s*\n+\s*/g, " ") : ""
                    color: Theme.muted
                    font.pixelSize: 13
                    wrapMode: Text.NoWrap
                    elide: Text.ElideRight
                }
            }

            ShellText {
                id: notifClose

                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 20
                horizontalAlignment: Text.AlignHCenter
                text: "\u00d7"
                color: Theme.muted
                font.pixelSize: 19

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -4
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        const n = notifItem.notif;
                        if (n)
                            n.dismiss();

                        ShellState.clearNotification(n);
                    }
                }
            }

            Timer {
                id: notifTimer

                interval: window.notifTimeout
                running: ShellState.notifActive && interval > 0 && !notifHover.containsMouse && !ShellState.expanded
                onTriggered: {
                    const n = ShellState.activeNotification;
                    ShellState.clearNotification(n);
                }
            }

            Connections {
                target: ShellState.activeNotification
                ignoreUnknownSignals: true

                function onExpired() {
                    ShellState.clearNotification(target);
                }

                function onDismissed() {
                    ShellState.clearNotification(target);
                }

                function onTrackedChanged() {
                    if (target && !target.tracked)
                        ShellState.clearNotification(target);
                }
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: 120
                    easing.type: Easing.OutCubic
                }
            }
        }

        Timer {
            id: hoverExitTimer

            interval: 250
            onTriggered: ShellState.hovered = false
        }

        Item {
            id: authItem

            readonly property var flow: ShellState.authFlow

            // Keep the last text so the prompt doesn't blank out while it fades away.
            property string shownMessage: ""
            property string shownAction: ""

            // Fade follows the island's height spring: content appears as the island grows,
            // and disappears quickly when it closes.
            property real shown: ShellState.authActive ? 1 : 0
            readonly property real grow: Math.max(0, Math.min(1, (hSpring.value - window.collapsedHeight) / Math.max(1, window.authHeight - window.collapsedHeight)))
            readonly property real reveal: shown * Math.max(0, Math.min(1, (grow - 0.35) / 0.5))

            Behavior on shown {
                NumberAnimation {
                    duration: 110
                    easing.type: Easing.OutCubic
                }
            }

            Binding {
                target: authItem
                property: "shownMessage"
                value: authItem.flow ? authItem.flow.message : ""
                when: authItem.flow !== null && authItem.flow !== undefined
                restoreMode: Binding.RestoreNone
            }

            Binding {
                target: authItem
                property: "shownAction"
                value: authItem.flow ? authItem.flow.actionId : ""
                when: authItem.flow !== null && authItem.flow !== undefined
                restoreMode: Binding.RestoreNone
            }

            anchors.left: notchBody.left
            anchors.right: notchBody.right
            anchors.top: parent.top
            height: parent.height
            clip: true
            visible: ShellState.authActive || shown > 0
            opacity: reveal
            z: 50
            onVisibleChanged: {
                if (visible && ShellState.authActive) {
                    passwordField.text = "";
                    passwordField.forceActiveFocus();
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.AllButtons
            }

            Connections {
                function onIsResponseRequiredChanged() {
                    if (authItem.flow && authItem.flow.isResponseRequired) {
                        passwordField.text = "";
                        passwordField.forceActiveFocus();
                    }
                }

                target: authItem.flow
                ignoreUnknownSignals: true
            }

            Column {
                id: authColumn

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 18
                anchors.topMargin: 16
                spacing: 10
                transform: Translate { y: (1 - authItem.reveal) * -8 }

                Row {
                    width: parent.width
                    spacing: 10

                    ShellText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "\uDB80\uDF3E"
                        font.family: Theme.iconFontFamily
                        color: Theme.primary
                        font.pixelSize: 26
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 42
                        spacing: 1

                        ShellText {
                            width: parent.width
                            elide: Text.ElideRight
                            text: authItem.shownMessage
                            color: Theme.shellForeground
                            font.pixelSize: 15
                            font.weight: Font.DemiBold
                        }

                        ShellText {
                            width: parent.width
                            elide: Text.ElideRight
                            text: authItem.shownAction
                            color: Theme.muted
                            font.pixelSize: 11
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 42
                    radius: 10
                    color: (Theme.isLight ? Qt.darker(Theme.cardColor, 1.1) : "#0f0f0f")
                    border.width: authItem.flow && authItem.flow.failed ? 1 : 0
                    border.color: Theme.red

                    TextInput {
                        id: passwordField

                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        verticalAlignment: TextInput.AlignVCenter
                        clip: true
                        selectByMouse: true
                        color: Theme.shellForeground
                        font.pixelSize: 16
                        echoMode: authItem.flow && authItem.flow.responseVisible ? TextInput.Normal : TextInput.Password
                        onAccepted: {
                            if (authItem.flow)
                                authItem.flow.submit(text);
                        }
                        Keys.onEscapePressed: {
                            if (authItem.flow)
                                authItem.flow.cancel();
                        }

                        ShellText {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: passwordField.text.length === 0
                            text: authItem.flow && authItem.flow.inputPrompt ? authItem.flow.inputPrompt : "Password"
                            color: Theme.muted
                            font.pixelSize: 15
                        }
                    }
                }

                ShellText {
                    width: parent.width
                    elide: Text.ElideRight
                    visible: text.length > 0
                    text: authItem.flow ? (authItem.flow.failed ? "Authentication failed. Try again." : authItem.flow.supplementaryMessage) : ""
                    color: authItem.flow && (authItem.flow.failed || authItem.flow.supplementaryIsError) ? Theme.red : Theme.muted
                    font.pixelSize: 13
                }

                Row {
                    width: parent.width
                    layoutDirection: Qt.RightToLeft
                    spacing: 8

                    Rectangle {
                        width: 140
                        height: 40
                        radius: Theme.radiusSmall
                        color: Theme.primary

                        ShellText {
                            anchors.centerIn: parent
                            text: "Authenticate"
                            color: Theme.bgDim
                            font.pixelSize: 15
                            font.weight: Font.DemiBold
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (authItem.flow)
                                    authItem.flow.submit(passwordField.text);
                            }
                        }
                    }

                    Rectangle {
                        width: 96
                        height: 40
                        radius: Theme.radiusSmall
                        color: Theme.bg1

                        ShellText {
                            anchors.centerIn: parent
                            text: "Cancel"
                            color: Theme.shellForeground
                            font.pixelSize: 15
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (authItem.flow)
                                    authItem.flow.cancel();
                            }
                        }
                    }
                }
            }
        }

        HyprlandFocusGrab {
            windows: [window]
            active: ShellState.authActive
        }

        HoverHandler {
            id: notchHoverHandler
            enabled: !ShellState.expanded
            cursorShape: Qt.PointingHandCursor
            onHoveredChanged: {
                if (hovered) {
                    hoverExitTimer.stop();
                    if (window.hoverBlock || window.closing || window.panelWidthSettling || window.panelHoverRearm)
                        return;
                    if (!NotchSettings.cfg.expandOnHover)
                        return;
                    if (NotchSettings.cfg.hoverDelay > 0) {
                        hoverEnterTimer.restart();
                        return;
                    }
                    ShellState.hovered = true;
                } else {
                    hoverEnterTimer.stop();
                    window.panelHoverRearm = false;
                    panelHoverRearmTimer.stop();
                    hoverExitTimer.restart();
                }
            }
        }

        MouseArea {
            id: notchHoverArea
            z: -1
            anchors.fill: parent
            enabled: !ShellState.expanded
            onClicked: ShellState.show("control")
        }

        ClippingRectangle {
            id: panelHost

            // rounded clip, concentric with the shell, so the content's corners follow it
            color: "transparent"
            topLeftRadius: window.attached ? 0 : Math.max(0, window.bodyBottomRadius - window.displayedTopPadding)
            topRightRadius: window.attached ? 0 : Math.max(0, window.bodyBottomRadius - window.displayedTopPadding)
            bottomLeftRadius: Math.max(0, window.bodyBottomRadius - window.displayedBottomPadding)
            bottomRightRadius: Math.max(0, window.bodyBottomRadius - window.displayedBottomPadding)

            anchors.left: notchBody.left
            anchors.right: notchBody.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.leftMargin: (window.displayedPanel === "theme" || window.displayedPanel === "wallpaper" || window.displayedPanel === "launcher") ? 0 : window.contentPadding
            anchors.rightMargin: (window.displayedPanel === "theme" || window.displayedPanel === "wallpaper" || window.displayedPanel === "launcher") ? 0 : window.contentPadding
            anchors.topMargin: window.displayedTopPadding
            anchors.bottomMargin: window.displayedBottomPadding
            visible: opacity > 0
            opacity: window.contentRevealed ? window.openFade : (ShellState.expanded ? 0 : window.closeFade)

            Item {
                id: panelContent
                anchors.top: parent.top
                anchors.left: parent.left
                width: window.lockW
                height: window.lockH
                transformOrigin: Item.Top
                scale: 1
                Behavior on scale {
                    enabled: ShellState.expanded
                    NumberAnimation {
                        duration: window.contentRevealed ? 260 : 120
                        easing.type: Easing.OutCubic
                    }
                }

            ControlPanel {
                id: controlPanel

                width: parent.width
                height: parent.height
                visible: window.displayedPanel === "control"
            }

            LauncherPanel {
                id: launcherPanel

                width: parent.width
                visible: window.displayedPanel === "launcher"
            }

            ClipboardPanel {
                id: clipboardPanel

                width: parent.width
                visible: window.displayedPanel === "clipboard"
            }

            TodoPanel {
                id: todoPanel

                width: parent.width
                visible: window.displayedPanel === "todo"
            }

            QuickNotesPanel {
                id: quickNotesPanel

                width: parent.width
                height: parent.height
                visible: window.displayedPanel === "notes"
            }

            ThemePanel {
                id: themePanel

                width: parent.width
                anchors.verticalCenter: parent.verticalCenter
                visible: window.displayedPanel === "theme"
            }

            WallpaperPanel {
                id: wallpaperPanel

                width: parent.width
                height: parent.height
                visible: window.displayedPanel === "wallpaper"
            }

            CapturePanel {
                id: capturePanel

                width: parent.width
                visible: window.displayedPanel === "capture"
            }

            NotificationsPanel {
                id: notificationsPanel

                width: parent.width
                height: parent.height
                visible: window.displayedPanel === "notifications"
            }

            CalendarPanel {
                id: calendarPanel

                width: parent.width
                height: parent.height
                visible: window.displayedPanel === "calendar"
            }

            DisplayPanel {
                id: displayPanel

                width: parent.width
                visible: window.displayedPanel === "display"
            }

            PowerPanel {
                id: powerPanel

                width: parent.width
                visible: window.displayedPanel === "power"
            }
            }

            Behavior on opacity {
                enabled: ShellState.expanded && window.remainMax > 0.9
                NumberAnimation {
                    duration: window.contentRevealed ? 100 : 60
                    easing.type: Easing.OutCubic
                }
            }
        }

        Spring {
            id: wSpring
            target: window.targetVisualWidth
            animated: NotchSettings.cfg.animationsEnabled
            omegaUp: window.springOmegaUp; zetaUp: window.springZetaUp; omegaDown: window.springOmegaDown; zetaDown: window.springZetaDown
            Component.onCompleted: {
                snapToTarget();
                window.hoverProgressReady = true;
            }
        }

        Spring {
            id: hSpring
            target: window.targetVisualHeight
            animated: NotchSettings.cfg.animationsEnabled && !clipboardPanel.previewTransitionActive
            omegaUp: window.springOmegaUp; zetaUp: window.springZetaUp; omegaDown: window.springOmegaDown; zetaDown: window.springZetaDown
            Component.onCompleted: snapToTarget()
        }
    }

    PanelWindow {
        id: islandReserve
        visible: true
        screen: window.screen
        anchors { top: true; left: true; right: true }
        implicitHeight: 1
        color: "transparent"
        mask: Region {}
        exclusionMode: ExclusionMode.Normal
        exclusiveZone: Math.max(0, window.islandMargin + window.collapsedHeight + (window.attached ? NotchSettings.cfg.notchWindowGap : NotchSettings.cfg.islandWindowGap) - window.hyprGapsOut)
        WlrLayershell.layer: WlrLayer.Bottom
        WlrLayershell.namespace: "dotarch-island-reserve"
    }

    property int hyprGapsOut: 0

    Process {
        id: gapsProc
        command: ["hyprctl", "getoption", "general:gaps_out", "-j"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const o = JSON.parse(text);
                    const v = parseInt(String(o.css || o.custom || "").trim().split(/\s+/)[0]);
                    if (!isNaN(v)) window.hyprGapsOut = v;
                    else if (o.int !== undefined) window.hyprGapsOut = o.int;
                } catch (e) {}
            }
        }
    }

    property bool osdArmed: false
    property int lastBrightness: -1
    property int maxBrightness: 0

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    Connections {
        function onVolumeChanged() {
            const a = Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null;
            if (a)
                window.showOsd("volume", a.volume, a.muted);
        }

        function onMutedChanged() {
            const a = Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null;
            if (a)
                window.showOsd("volume", a.volume, a.muted);
        }

        target: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null
        ignoreUnknownSignals: true
    }

    FileView {
        id: maxBrightnessFile

        path: "/sys/class/backlight/intel_backlight/max_brightness"
        preload: true
        onLoaded: window.maxBrightness = parseInt(text())
    }

    FileView {
        id: brightnessFile

        path: "/sys/class/backlight/intel_backlight/brightness"
        onLoaded: {
            const v = parseInt(text());

            // Keep the Control Centre brightness slider in sync with hardware.
            if (Number.isFinite(v) && window.maxBrightness > 0) {
                const percent = Math.round(
                    Math.max(0, Math.min(1, v / window.maxBrightness)) * 100
                );
                if (Backend.brightness !== percent)
                    Backend.brightness = percent;
            }

            if (window.lastBrightness >= 0 && v !== window.lastBrightness && window.maxBrightness > 0)
                window.showOsd("brightness", v / window.maxBrightness, false);

            window.lastBrightness = v;
        }
    }

    Timer {
        interval: 150
        running: true
        repeat: true
        onTriggered: brightnessFile.reload()
    }

    Timer {
        interval: 2000
        running: true
        onTriggered: window.osdArmed = true
    }

    Timer {
        id: osdTimer

        interval: 1500
        onTriggered: ShellState.osdActive = false
    }

    Process {
        id: cavaProcess
        command: ["cava", "-p", Quickshell.env("HOME") + "/.config/cava/notch"]
        running: statusHeader.visible && statusHeader.playing

        stdout: SplitParser {
            splitMarker: "\n"

            onRead: data => {
                const values = data.trim().split(";")
                .map(v => Number(v))
                .filter(v => Number.isFinite(v));

                if (values.length >= 12)
                    window.visualizerBars = values.slice(0, 12);
            }
        }
    }

    Timer {
        id: hoverEnterTimer
        interval: NotchSettings.cfg.hoverDelay
        onTriggered: {
            if (!window.hoverBlock && !window.closing
                    && !window.panelWidthSettling && !window.panelHoverRearm)
                ShellState.hovered = true;
        }
    }

    SystemClock {
        id: clock

        precision: NotchSettings.cfg.showSeconds ? SystemClock.Seconds : SystemClock.Minutes
    }

    HyprlandFocusGrab {
        windows: [window]
        active: ShellState.expanded && Backend.captureSelectionMode !== "region"
        onCleared: {
            if (ShellState.expanded && Backend.captureSelectionMode !== "region")
                ShellState.close();
        }
    }

    Timer {
        id: focusTimer

        interval: 35
        onTriggered: window.focusInitialControl()
    }

    Timer {
        id: clockRevealTimer

        interval: 150
        onTriggered: {
            if (!ShellState.expanded)
                window.clockRevealed = true;
        }
    }

    Shortcut {
        sequence: "Escape"
        enabled: ShellState.expanded
        onActivated: ShellState.close()
    }

    mask: Region {
        item: notchBody
        topLeftRadius: 0
        topRightRadius: 0
        bottomLeftRadius: window.bodyBottomRadius
        bottomRightRadius: window.bodyBottomRadius
    }
}
