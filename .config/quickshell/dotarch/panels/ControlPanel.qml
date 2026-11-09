import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Networking
import Quickshell.Services.Mpris
import Quickshell.Services.Notifications
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower
import Quickshell.Widgets
import qs
import qs.components
import ".."

FocusScope {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property var player: {
        const list = Mpris.players.values;
        const playing = list.find((p) => p.isPlaying);
        return playing || (list.length > 0 ? list[0] : null);
    }
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var wifiDevice: Networking.devices.values.find((device) => {
        return device.type === DeviceType.Wifi;
    }) || null
    readonly property var wifiNetworks: wifiDevice ? wifiDevice.networks.values.slice().sort((left, right) => {
        if (left.connected !== right.connected)
            return left.connected ? -1 : 1;

        return right.signalStrength - left.signalStrength;
    }) : []
    readonly property var connectedWifi: wifiNetworks.find((network) => {
        return network.connected;
    }) || null
    readonly property var knownWifiNetworks: wifiNetworks.filter((network) => network.known)
    readonly property var availableWifiNetworks: wifiNetworks.filter((network) => !network.known)
    readonly property var audioSinks: Pipewire.nodes.values.filter((node) => {
        return node.isSink && !node.isStream && node.audio;
    }).slice().sort((left, right) => {
        if (sink && left.id === sink.id)
            return -1;

        if (sink && right.id === sink.id)
            return 1;

        return (left.description || left.nickname || left.name).localeCompare(right.description || right.nickname || right.name);
    })
    readonly property var audioSources: Pipewire.nodes.values.filter((node) => {
        return !node.isSink && !node.isStream && node.audio;
    }).slice().sort((left, right) => {
        if (source && left.id === source.id)
            return -1;

        if (source && right.id === source.id)
            return 1;

        return (left.description || left.nickname || left.name).localeCompare(right.description || right.nickname || right.name);
    })
    readonly property var bluetoothDevices: adapter ? adapter.devices.values.filter((device) => {
        return device.name || device.deviceName;
    }).slice().sort((left, right) => {
        if (left.connected !== right.connected)
            return left.connected ? -1 : 1;

        if (left.paired !== right.paired)
            return left.paired ? -1 : 1;

        return (left.name || left.deviceName).localeCompare(right.name || right.deviceName);
    }) : []
    readonly property var knownBluetoothDevices: bluetoothDevices.filter((device) => device.paired || device.bonded)
    readonly property var availableBluetoothDevices: bluetoothDevices.filter((device) => !device.paired && !device.bonded)
    readonly property var connectedDevices: adapter ? adapter.devices.values.filter((device) => {
        return device.connected;
    }) : []
    readonly property var notifItems: ShellState.notificationModel && ShellState.notificationModel.values ? ShellState.notificationModel.values.slice().reverse() : []

    property string expandedSection: ""
    property string displayedSection: ""
    property var pendingWifiNetwork: null
    property string wifiError: ""
    property bool wifiRefreshPending: false
    readonly property real detailScrollFactor: 2

    function clearAllNotifications() {
        const all = notifItems.slice();
        for (let i = 0; i < all.length; i++)
            all[i].dismiss();
    }

    function toggleSection(section) {
        const nextSection = expandedSection === section ? "" : section;
        if (expandedSection === "wifi" && nextSection !== "wifi")
            stopWifiScanner();

        if (expandedSection === "bluetooth" && nextSection !== "bluetooth")
            stopBluetoothDiscovery();

        expandedSection = nextSection;
        if (nextSection) {
            sectionCloseTimer.stop();
            displayedSection = nextSection;
        } else {
            sectionCloseTimer.restart();
        }
        pendingWifiNetwork = null;
        if (nextSection === "wifi")
            startWifiScanner();
        else if (nextSection === "bluetooth")
            startBluetoothDiscovery();
    }

    function closeDetails() {
        if (!expandedSection)
            return;

        toggleSection(expandedSection);
    }

    function toggleWifi() {
        Networking.wifiEnabled = !Networking.wifiEnabled;
    }

    function toggleAudio() {
        if (source && source.audio)
            source.audio.muted = !source.audio.muted;
    }

    function toggleOutputAudio() {
        if (sink && sink.audio)
            sink.audio.muted = !sink.audio.muted;
    }

    function toggleBluetooth() {
        if (adapter)
            adapter.enabled = !adapter.enabled;
    }

    function scrollDetailList(list, event) {
        const rawDelta = event.pixelDelta.y !== 0 ? event.pixelDelta.y : event.angleDelta.y * 0.6;
        const minimum = list.originY;
        const maximum = Math.max(minimum, minimum + list.contentHeight - list.height);
        list.contentY = Math.max(minimum, Math.min(maximum, list.contentY - rawDelta * detailScrollFactor));
        event.accepted = true;
    }

    function startWifiScanner() {
        wifiError = "";
        if (!wifiDevice || !Networking.wifiEnabled)
            return;

        wifiDevice.scannerEnabled = true;
        wifiRefreshPending = true;
        wifiRefreshTimer.restart();
    }

    function restartWifiScanner() {
        if (!wifiDevice || !Networking.wifiEnabled || wifiRefreshPending)
            return;

        wifiError = "";
        wifiRefreshPending = true;
        wifiDevice.scannerEnabled = false;
        Qt.callLater(() => {
            if (root.wifiDevice && root.expandedSection === "wifi" && Networking.wifiEnabled)
                root.wifiDevice.scannerEnabled = true;

            wifiRefreshTimer.restart();
        });
    }

    function stopWifiScanner() {
        wifiRefreshTimer.stop();
        wifiRefreshPending = false;
        if (wifiDevice && wifiDevice.scannerEnabled)
            wifiDevice.scannerEnabled = false;
    }

    function startBluetoothDiscovery() {
        if (!adapter || !adapter.enabled)
            return;

        adapter.discovering = true;
        bluetoothScanTimer.restart();
    }

    function stopBluetoothDiscovery() {
        bluetoothScanTimer.stop();
        if (adapter && adapter.discovering)
            adapter.discovering = false;
    }

    function selectWifi(network) {
        if (!network || network.stateChanging)
            return;

        if (network.connected) {
            network.disconnect();
            return;
        }
        wifiError = "";
        if (!network.known && wifiUsesPsk(network.security)) {
            pendingWifiNetwork = network;
            Qt.callLater(() => {
                return wifiPasswordInput.forceActiveFocus(Qt.TabFocusReason);
            });
            return;
        }
        network.connect();
    }

    function connectPendingWifi() {
        if (!pendingWifiNetwork || !wifiPasswordInput.text)
            return;

        wifiError = "";
        pendingWifiNetwork.connectWithPsk(wifiPasswordInput.text);
        wifiPasswordInput.clear();
        pendingWifiNetwork = null;
    }

    function wifiUsesPsk(security) {
        return security === WifiSecurityType.WpaPsk || security === WifiSecurityType.Wpa2Psk || security === WifiSecurityType.Sae;
    }

    function wifiSecurityLabel(security) {
        switch (security) {
        case WifiSecurityType.Open:
            return "Open network";
        case WifiSecurityType.Sae:
            return "WPA3";
        case WifiSecurityType.Wpa2Psk:
            return "WPA2";
        case WifiSecurityType.WpaPsk:
            return "WPA";
        case WifiSecurityType.Owe:
            return "Enhanced Open";
        case WifiSecurityType.Wpa2Eap:
            return "WPA2 Enterprise";
        case WifiSecurityType.WpaEap:
            return "WPA Enterprise";
        case WifiSecurityType.Wpa3SuiteB192:
            return "WPA3 Enterprise";
        case WifiSecurityType.StaticWep:
        case WifiSecurityType.DynamicWep:
            return "WEP";
        case WifiSecurityType.Leap:
            return "LEAP";
        default:
            return "Secured";
        }
    }

    function wifiConnectionFailed(network, reason) {
        if (reason === ConnectionFailReason.NoSecrets || reason === ConnectionFailReason.WifiAuthTimeout)
            wifiError = "Authentication failed for " + network.name;
        else if (reason === ConnectionFailReason.WifiNetworkLost)
            wifiError = "Network lost while connecting";
        else
            wifiError = "Could not connect to " + network.name;
    }

    property var pendingBtDevice: null

    Connections {
        target: root.pendingBtDevice
        ignoreUnknownSignals: true

        function onPairedChanged() { root.finishBluetoothPair(); }
        function onBondedChanged() { root.finishBluetoothPair(); }
    }

    Timer {
        id: btPairTimeout
        interval: 30000
        onTriggered: root.pendingBtDevice = null
    }

    function finishBluetoothPair() {
        const d = root.pendingBtDevice;
        if (d && (d.paired || d.bonded)) {
            root.pendingBtDevice = null;
            btPairTimeout.stop();
            d.trusted = true;
            d.connect();
        }
    }

    function activateBluetoothDevice(device) {
        // Scanning while connecting makes BlueZ connects flaky
        root.stopBluetoothDiscovery();
        if (device.connected) {
            device.disconnect();
        } else if (device.paired || device.bonded) {
            device.trusted = true;
            device.connect();
        } else {
            root.pendingBtDevice = device;
            btPairTimeout.restart();
            device.trusted = true;
            device.pair();
        }
    }

    function bluetoothIcon(device) {
        const iconName = (device.icon || "").toLowerCase();
        if (iconName.indexOf("head") >= 0 || iconName.indexOf("audio") >= 0)
            return "󰋋";

        if (iconName.indexOf("mouse") >= 0)
            return "󰍽";

        if (iconName.indexOf("keyboard") >= 0)
            return "󰌌";

        return "󰂯";
    }

    function wifiSignalPercent(signal) {
        const value = Number(signal);
        if (!Number.isFinite(value))
            return null;

        return Math.round(Math.max(0, Math.min(1, value)) * 100);
    }

    function wifiSignalIcon(signal) {
        const strength = Number(signal);
        if (!Number.isFinite(strength))
            return "󰤯";

        if (strength >= 0.7)
            return "󰤨";

        if (strength >= 0.4)
            return "󰤢";

        return "󰤟";
    }

    implicitWidth: 440
    // Strictly bind to layout height to force the Wayland surface to shrink properly
    implicitHeight: content.height 
    
    onWifiDeviceChanged: {
        if (root.wifiDevice && root.expandedSection === "wifi")
            root.startWifiScanner();
    }
    Component.onDestruction: root.stopWifiScanner()
    Keys.onEscapePressed: (event) => {
        if (root.expandedSection) {
            root.closeDetails();
            event.accepted = true;
        }
    }

    PwObjectTracker {
        objects: root.audioSinks
    }

    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }

    PwObjectTracker {
        objects: root.audioSources
    }

    Timer {
        id: wifiRefreshTimer
        interval: 1000
        onTriggered: root.wifiRefreshPending = false
    }

    Timer {
        id: bluetoothScanTimer
        interval: 12000
        onTriggered: root.stopBluetoothDiscovery()
    }

    Timer {
        id: sectionCloseTimer
        interval: Theme.animationNormal
        onTriggered: {
            if (!root.expandedSection)
                root.displayedSection = "";
        }
    }

    Connections {
        function onWifiEnabledChanged() {
            if (Networking.wifiEnabled && root.expandedSection === "wifi")
                Qt.callLater(() => root.startWifiScanner());
            else if (!Networking.wifiEnabled)
                root.stopWifiScanner();
        }
        target: Networking
    }

    Connections {
        function onEnabledChanged() {
            if (root.adapter && root.adapter.enabled && root.expandedSection === "bluetooth")
                root.startBluetoothDiscovery();
        }
        target: root.adapter
    }

    Connections {
        function onPanelChanged() {
            if (ShellState.panel === "control")
                Backend.refreshQuickControls();

            if (ShellState.panel !== "control") {
                root.closeDetails();
                root.stopBluetoothDiscovery();
            }
        }
        target: ShellState
    }

    Timer {
        interval: 1000
        running: !!(root.player && root.player.isPlaying)
        repeat: true
        onTriggered: root.player.positionChanged()
    }

    component InfoTile: Item {
        id: tile

        property string icon: ""
        property string title: ""
        property string subtitle: ""
        property bool active: false

        signal clicked()
        signal iconClicked()

        Rectangle {
            anchors.fill: parent
            radius: Theme.radiusCard
            color: Qt.darker(Theme.cardColor, 1.35)
            border.width: 1
            border.color: Theme.cardBorder
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: tile.clicked()
        }

        Rectangle {
            id: badge
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            width: 38
            height: 38
            radius: 19
            color: tile.active ? Theme.primary : Qt.rgba(1, 1, 1, 0.08)

            Behavior on color {
                ColorAnimation {
                    duration: Theme.animationFast
                }
            }

            ShellText {
                anchors.centerIn: parent
                text: tile.icon
                font.family: Theme.iconFontFamily
                color: tile.active ? Theme.bgDim : Theme.muted
                font.pixelSize: 17
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: tile.iconClicked()
            }
        }

        Column {
            anchors.left: badge.right
            anchors.leftMargin: 10
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1

            ShellText {
                width: parent.width
                elide: Text.ElideRight
                text: tile.title
                color: Theme.foreground
                font.pixelSize: 13
                font.weight: Font.DemiBold
            }

            ShellText {
                width: parent.width
                elide: Text.ElideRight
                text: tile.subtitle
                color: Theme.muted
                font.pixelSize: 11
            }
        }
    }

    component CircleButton: Item {
        id: btn

        property string icon: ""
        property bool active: false

        signal clicked()

        width: 56
        height: 56

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: btn.active ? Theme.primary : Qt.darker(Theme.cardColor, 1.35)
            border.width: btn.active ? 0 : 1
            border.color: Theme.cardBorder

            Behavior on color {
                ColorAnimation {
                    duration: Theme.animationFast
                }
            }
        }

        ShellText {
            anchors.centerIn: parent
            text: btn.icon
            font.family: Theme.iconFontFamily
            color: btn.active ? Theme.bgDim : Theme.foreground
            font.pixelSize: 19
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: btn.clicked()
        }
    }

    component SliderCard: Item {
        id: card

        property string label: ""
        property string icon: ""
        property string trailing: ""
        property real value: 0

        signal moved(real newValue)
        signal trailingClicked()

        height: 78

        Rectangle {
            anchors.fill: parent
            radius: Theme.radiusCard
            color: Qt.darker(Theme.cardColor, 1.35)
            border.width: 1
            border.color: Theme.cardBorder
        }

        ShellText {
            anchors.left: parent.left
            anchors.leftMargin: 14
            anchors.top: parent.top
            anchors.topMargin: 10
            text: card.label
            color: Theme.muted
            font.pixelSize: 11
            font.weight: Font.DemiBold
        }

        Item {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.rightMargin: 10
            anchors.topMargin: 6
            width: 24
            height: 20
            visible: card.trailing.length > 0

            ShellText {
                anchors.centerIn: parent
                text: card.trailing
                font.family: Theme.iconFontFamily
                color: Theme.muted
                font.pixelSize: 13
            }

            MouseArea {
                anchors.fill: parent
                anchors.margins: -4
                cursorShape: Qt.PointingHandCursor
                onClicked: card.trailingClicked()
            }
        }

        Rectangle {
            id: track
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            anchors.bottomMargin: 10
            height: 34
            radius: height / 2
            color: Qt.rgba(1, 1, 1, 0.07)
            clip: true

            Rectangle {
                width: Math.max(parent.height, parent.width * Math.max(0, Math.min(1, card.value)))
                height: parent.height
                radius: height / 2
                color: Theme.primary

                Behavior on width {
                    SpringAnim {}
                }
            }

            ShellText {
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                text: card.icon
                font.family: Theme.iconFontFamily
                color: Theme.bgDim
                font.pixelSize: 16
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                enabled: root.expandedSection === ""
                onPressed: (mouse) => card.moved(Math.max(0, Math.min(1, mouse.x / width)))
                onPositionChanged: (mouse) => {
                    if (pressed)
                        card.moved(Math.max(0, Math.min(1, mouse.x / width)));
                }
            }
        }
    }

    Column {
        id: content
        width: parent.width
        spacing: 10

        Item {
            id: topBlock

            readonly property real mediaWidth: 3 * 56 + 2 * 8
            width: parent.width
            height: 120

            Column {
                anchors.left: parent.left
                anchors.top: parent.top
                width: parent.width - topBlock.mediaWidth - 8
                spacing: 8

                InfoTile {
                    width: parent.width
                    height: 56
                    icon: "\uDB82\uDD28"
                    title: "Wi-Fi"
                    subtitle: root.connectedWifi ? root.connectedWifi.name : (Networking.wifiEnabled ? "Not connected" : "Off")
                    active: Networking.wifiEnabled
                    onClicked: root.toggleSection("wifi")
                    onIconClicked: root.toggleWifi()
                }

                InfoTile {
                    width: parent.width
                    height: 56
                    icon: "\uDB80\uDCAF"
                    title: "Bluetooth"
                    subtitle: root.connectedDevices.length > 0 ? root.connectedDevices[0].name : (root.adapter && root.adapter.enabled ? "On" : "Off")
                    active: !!(root.adapter && root.adapter.enabled)
                    onClicked: root.toggleSection("bluetooth")
                    onIconClicked: root.toggleBluetooth()
                }
            }

            ClippingRectangle {
                id: mediaTile
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: topBlock.mediaWidth
                radius: Theme.radiusCard
                color: Qt.darker(Theme.cardColor, 1.35)
                border.width: 1
                border.color: Theme.cardBorder

                Image {
                    id: mediaArt
                    anchors.fill: parent
                    source: root.player ? root.player.trackArtUrl : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    visible: status === Image.Ready
                    opacity: 0.4
                }

                Rectangle {
                    anchors.fill: parent
                    visible: mediaArt.status === Image.Ready
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.15) }
                        GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.75) }
                    }
                }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: 16
                    width: 40
                    height: 40
                    radius: 20
                    color: root.player && root.player.isPlaying ? Theme.primary : Qt.rgba(1, 1, 1, 0.08)

                    ShellText {
                        anchors.centerIn: parent
                        text: root.player ? (root.player.isPlaying ? "\uDB80\uDFE4" : "\uDB81\uDC0A") : "\uDB81\uDF5A"
                        font.family: Theme.iconFontFamily
                        color: root.player && root.player.isPlaying ? Theme.bgDim : Theme.muted
                        font.pixelSize: 18
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.player && root.player.canTogglePlaying)
                                root.player.togglePlaying();
                        }
                    }
                }

                Column {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: 10
                    spacing: 1

                    ShellText {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        text: root.player ? (root.player.trackTitle || "Unknown title") : "Not playing"
                        color: Theme.foreground
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                    }

                    ShellText {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        visible: text.length > 0
                        text: root.player ? (root.player.trackArtist || "") : ""
                        color: Theme.muted
                        font.pixelSize: 10
                    }
                }
            }
        }

        Row {
            width: parent.width
            height: 56
            spacing: 8

            InfoTile {
                width: parent.width - 3 * 56 - 3 * 8
                height: 56
                icon: "\uDB80\uDC9B"
                title: "Peace"
                subtitle: ShellState.peaceMode ? "On" : "Off"
                active: ShellState.peaceMode
                onClicked: ShellState.togglePeaceMode()
                onIconClicked: ShellState.togglePeaceMode()
            }

            CircleButton {
                icon: "\uDB81\uDD94"
                active: Backend.nightLightStatus === "on"
                opacity: Backend.nightLightStatus === "unavailable" ? 0.4 : 1
                onClicked: {
                    if (Backend.nightLightStatus !== "unavailable")
                        Backend.toggleNightLight();
                }
            }

            CircleButton {
                icon: root.source && root.source.audio && root.source.audio.muted ? "\uDB80\uDF6D" : "\uDB80\uDF6C"
                active: !!(root.source && root.source.audio && !root.source.audio.muted)
                onClicked: root.toggleAudio()
            }

            CircleButton {
                icon: "\uDB81\uDC25"
                active: false
                onClicked: ShellState.show("power")
            }
        }

        SliderCard {
            id: displayCard
            width: parent.width
            label: "Display"
            icon: "\uDB80\uDCE0"
            trailing: "\uDB80\uDD40"
            value: Backend.brightness / 100
            onMoved: (val) => Backend.setBrightness(val * 100)
            onTrailingClicked: root.toggleSection("nightlight")
        }

        SliderCard {
            width: parent.width
            label: "Sound"
            icon: root.sink && root.sink.audio && root.sink.audio.muted ? "\uDB81\uDF5F" : "\uDB81\uDD7E"
            trailing: "\uDB80\uDC54"
            value: root.sink && root.sink.audio ? (root.sink.audio.muted ? 0 : root.sink.audio.volume) : 0
            onMoved: (val) => {
                if (root.sink && root.sink.audio) {
                    root.sink.audio.volume = val;
                    root.sink.audio.muted = false;
                }
            }
            onTrailingClicked: root.toggleSection("output")
        }

        // ── Notifications Background Card ──
        Rectangle {
            width: parent.width
            height: root.notifItems.length > 0 ? (50 + Math.min(2, root.notifItems.length) * 74) : 140
            radius: Theme.radiusCard
            color: Qt.darker(Theme.cardColor, 1.35)
            border.width: 1
            border.color: Theme.cardBorder
            clip: true

            Column {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 12

                Item {
                    width: parent.width
                    height: 16

                    ShellText {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Notifications"
                        color: Theme.muted
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                    }

                    ShellText {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        visible: root.notifItems.length > 0
                        text: "Clear all"
                        color: Theme.muted
                        font.pixelSize: 11
                        font.weight: Font.DemiBold

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -4
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.clearAllNotifications()
                        }
                    }
                }

                Item {
                    width: parent.width
                    height: parent.height - 28

                    // Centered beautifully in the remaining space
                    ShellText {
                        anchors.centerIn: parent
                        visible: root.notifItems.length === 0
                        text: "No notifications"
                        color: Theme.muted
                        font.pixelSize: 12
                    }

                    ListView {
                        id: inlineNotifList
                        anchors.fill: parent
                        visible: root.notifItems.length > 0
                        clip: true
                        spacing: 6
                        model: root.notifItems

                        delegate: Rectangle {
                            id: notifRow
                            required property var modelData
                            readonly property bool critical: modelData.urgency === NotificationUrgency.Critical

                            width: inlineNotifList.width
                            height: 68
                            radius: Theme.radiusCard
                            color: Theme.bg1
                            border.width: 1
                            border.color: critical ? Theme.red : Theme.cardBorder

                            Rectangle {
                                id: notifAvatar
                                anchors.left: parent.left
                                anchors.leftMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                width: 34
                                height: 34
                                radius: 17
                                color: Qt.rgba(1, 1, 1, 0.07)

                                ShellText {
                                    anchors.centerIn: parent
                                    text: "󰂚"
                                    font.family: Theme.iconFontFamily
                                    color: notifRow.critical ? Theme.red : Theme.primary
                                    font.pixelSize: 15
                                }
                            }

                            Column {
                                anchors.left: notifAvatar.right
                                anchors.right: dismissBtn.left
                                anchors.leftMargin: 10
                                anchors.rightMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 1

                                ShellText {
                                    width: parent.width
                                    elide: Text.ElideRight
                                    text: notifRow.modelData.appName || "System"
                                    color: Theme.muted
                                    font.pixelSize: 10
                                }

                                ShellText {
                                    width: parent.width
                                    elide: Text.ElideRight
                                    text: notifRow.modelData.summary || "Notification"
                                    color: Theme.foreground
                                    font.pixelSize: 12
                                    font.weight: Font.Bold
                                }

                                ShellText {
                                    width: parent.width
                                    elide: Text.ElideRight
                                    visible: text.length > 0
                                    text: notifRow.modelData.body || ""
                                    textFormat: Text.StyledText
                                    color: Theme.muted
                                    font.pixelSize: 11
                                }
                            }

                            Item {
                                id: dismissBtn
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.rightMargin: 10
                                anchors.topMargin: 10
                                width: 20
                                height: 20

                                ShellText {
                                    anchors.centerIn: parent
                                    text: "×"
                                    color: Theme.muted
                                    font.pixelSize: 15
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    anchors.margins: -4
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: notifRow.modelData.dismiss()
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ── Detail overlay components ──




    // ── Expandable Detail Overlay (Wi-Fi, Bluetooth, Audio, Night Light) ──
    Rectangle {
        id: devicePicker

        parent: root
        readonly property bool wifiMode: root.displayedSection === "wifi"
        readonly property bool bluetoothMode: root.displayedSection === "bluetooth"
        readonly property bool audioMode: root.displayedSection === "audio" || root.displayedSection === "output"
        readonly property bool nightLightMode: root.displayedSection === "nightlight"
        readonly property bool radioMode: wifiMode || bluetoothMode
        readonly property bool radioOn: wifiMode ? Networking.wifiEnabled : !!(root.adapter && root.adapter.enabled)
        readonly property real availableHeight: root.height - y
        readonly property string titleText: wifiMode ? "Wi-Fi" : (bluetoothMode ? "Bluetooth" : (root.displayedSection === "audio" ? "Audio input" : (root.displayedSection === "output" ? "Audio output" : (nightLightMode ? "Night Light" : ""))))
        readonly property string subtitleText: {
            if (wifiMode) {
                if (root.wifiError !== "")
                    return root.wifiError;
                if (!Networking.wifiEnabled)
                    return "Off";
                if (root.connectedWifi)
                    return "Connected to " + root.connectedWifi.name;
                return root.wifiRefreshPending ? "Scanning…" : "Not connected";
            }
            if (bluetoothMode) {
                if (!radioOn)
                    return root.adapter ? "Off" : "No adapter";
                if (root.connectedDevices.length > 0)
                    return "Connected to " + root.connectedDevices[0].name;
                return root.adapter.discovering ? "Searching…" : "Not connected";
            }
            if (nightLightMode)
                return ShellState.nightLightTemperature + " K";
            if (audioMode)
                return "Choose a device";
            return "";
        }

        x: 0
        y: {
            displayCard.y; displayCard.height; content.y; content.height; root.height;
            if (!nightLightMode)
                return 0;
            return displayCard.mapToItem(root, 0, displayCard.height + 8).y;
        }
        z: 100
        width: Math.round(root.width)
        height: Math.round(nightLightMode ? Math.min(112 + screenSection.height, availableHeight) : availableHeight)
        radius: Theme.radiusCard
        color: Qt.darker(Theme.cardColor, 1.35)
        antialiasing: true
        clip: true
        enabled: root.expandedSection !== ""
        visible: opacity > 0
        opacity: root.expandedSection ? 1 : 0

        MouseArea {
            anchors.fill: parent
            z: -1
            hoverEnabled: true
        }

        // Fades the list out at the bottom instead of slicing a row
        Rectangle {
            id: pickerFade
            readonly property color base: Qt.darker(Theme.cardColor, 1.35)
            visible: !devicePicker.nightLightMode
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 1
            height: 22
            bottomLeftRadius: devicePicker.radius - 1
            bottomRightRadius: devicePicker.radius - 1
            z: 150
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.alpha(pickerFade.base, 0) }
                GradientStop { position: 1.0; color: pickerFade.base }
            }
        }

        // One uniform outline, always painted above every child
        Rectangle {
            anchors.fill: parent
            radius: devicePicker.radius
            color: "transparent"
            border.width: 1
            border.color: Theme.cardBorder
            antialiasing: true
            z: 200
        }

        Item {
            id: pickerHeader
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 10
            height: 40

            FocusScope {
                id: backButton
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: 30
                height: 30
                activeFocusOnTab: true
                Keys.onReturnPressed: root.closeDetails()
                Keys.onEnterPressed: root.closeDetails()
                Keys.onSpacePressed: root.closeDetails()

                Rectangle {
                    anchors.fill: parent
                    radius: 15
                    color: backPointer.containsMouse ? Theme.bg2 : Theme.bg1
                    border.width: 1
                    border.color: Theme.cardBorder
                }

                ShellText {
                    anchors.centerIn: parent
                    text: "\uDB80\uDD41"
                    font.family: Theme.iconFontFamily
                    color: Theme.foreground
                    font.pixelSize: 16
                }

                MouseArea {
                    id: backPointer
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.closeDetails()
                }
            }

            Column {
                anchors.left: backButton.right
                anchors.leftMargin: 10
                anchors.right: refreshButton.visible ? refreshButton.left : (toggleSwitch.visible ? toggleSwitch.left : parent.right)
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                spacing: 1

                ShellText {
                    width: parent.width
                    text: devicePicker.titleText
                    color: Theme.foreground
                    font.pixelSize: 15
                    font.weight: Font.Bold
                }

                ShellText {
                    width: parent.width
                    visible: text.length > 0
                    elide: Text.ElideRight
                    text: devicePicker.subtitleText
                    color: devicePicker.wifiMode && root.wifiError !== "" ? Theme.red : Theme.muted
                    font.pixelSize: 11
                }
            }

            Item {
                id: refreshButton
                readonly property bool scanning: devicePicker.wifiMode ? root.wifiRefreshPending : !!(root.adapter && root.adapter.discovering)
                property real angle: 0

                anchors.right: toggleSwitch.visible ? toggleSwitch.left : parent.right
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                width: 30
                height: 30
                visible: devicePicker.radioMode && devicePicker.radioOn

                NumberAnimation on angle {
                    from: 0
                    to: 360
                    duration: 1000
                    loops: Animation.Infinite
                    running: refreshButton.scanning
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 15
                    color: refreshPointer.containsMouse ? Theme.bg2 : Theme.bg1
                    border.width: 1
                    border.color: Theme.cardBorder
                }

                ShellText {
                    anchors.centerIn: parent
                    text: "\uDB81\uDC50"
                    font.family: Theme.iconFontFamily
                    color: refreshButton.scanning ? Theme.primary : Theme.foreground
                    font.pixelSize: 15
                    rotation: refreshButton.scanning ? refreshButton.angle : 0
                }

                MouseArea {
                    id: refreshPointer
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (devicePicker.wifiMode)
                            root.restartWifiScanner();
                        else
                            root.startBluetoothDiscovery();
                    }
                }
            }

            FocusScope {
                id: toggleSwitch
                readonly property bool checked: devicePicker.radioOn

                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 42
                height: 24
                visible: devicePicker.radioMode

                function flip() {
                    if (devicePicker.wifiMode)
                        root.toggleWifi();
                    else
                        root.toggleBluetooth();
                }

                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color: toggleSwitch.checked ? Theme.primary : Theme.bg2

                    Behavior on color {
                        ColorAnimation { duration: Theme.animationFast }
                    }
                }

                Rectangle {
                    y: 3
                    x: toggleSwitch.checked ? parent.width - width - 3 : 3
                    width: 18
                    height: 18
                    radius: 9
                    color: toggleSwitch.checked ? Theme.bgDim : Theme.muted

                    Behavior on x {
                        SpringAnim {}
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: toggleSwitch.flip()
                }
            }
        }

        Rectangle {
            id: headerDivider
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: pickerHeader.bottom
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            anchors.topMargin: 4
            height: 1
            color: Theme.cardBorder
            visible: !devicePicker.nightLightMode
        }

        StyledSlider {
            id: nightLightSlider
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: pickerHeader.bottom
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            anchors.topMargin: 10
            visible: devicePicker.nightLightMode
            enabled: visible
            filled: true
            icon: "\uDB81\uDD94"
            value: (ShellState.nightLightTemperature - 2500) / 3500
            onMoved: (value) => Backend.setNightLightTemperature(2500 + value * 3500)
        }

        Column {
            id: screenSection

            readonly property bool shown: devicePicker.nightLightMode

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: nightLightSlider.bottom
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            anchors.topMargin: 12
            spacing: 6
            visible: shown
            height: shown ? implicitHeight + 12 : 0

            SectionLabel {
                width: parent.width
                text: "Display"
            }

            Repeater {
                model: Quickshell.screens

                delegate: NetRow {
                    required property var modelData
                    readonly property bool isTarget: (ShellState.targetScreen || Quickshell.screens[0].name) === modelData.name

                    width: screenSection.width
                    icon: "\uDB80\uDCE0"
                    title: modelData.name
                    subtitle: modelData.model || "Display"
                    active: isTarget
                    actionText: isTarget ? "Selected" : "Select"
                    onClicked: ShellState.targetScreen = modelData.name
                }
            }
        }

        // Radio turned off (Wi-Fi / Bluetooth)
        Item {
            id: offState
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.top: headerDivider.bottom
            visible: devicePicker.radioMode && !devicePicker.radioOn

            Column {
                anchors.centerIn: parent
                spacing: 10

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 56
                    height: 56
                    radius: 28
                    color: Qt.rgba(1, 1, 1, 0.06)

                    ShellText {
                        anchors.centerIn: parent
                        text: devicePicker.wifiMode ? "\uDB82\uDD28" : "\uDB80\uDCAF"
                        font.family: Theme.iconFontFamily
                        color: Theme.muted
                        font.pixelSize: 24
                    }
                }

                ShellText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: devicePicker.wifiMode ? "Wi-Fi is turned off" : (root.adapter ? "Bluetooth is turned off" : "No Bluetooth adapter found")
                    color: Theme.muted
                    font.pixelSize: 13
                }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: devicePicker.wifiMode || !!root.adapter
                    width: 90
                    height: 30
                    radius: 15
                    color: Theme.primary

                    ShellText {
                        anchors.centerIn: parent
                        text: "Turn on"
                        color: Theme.bgDim
                        font.pixelSize: 12
                        font.weight: Font.Bold
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: toggleSwitch.flip()
                    }
                }
            }
        }

        // Empty / searching states
        ShellText {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: 20
            visible: (devicePicker.wifiMode && Networking.wifiEnabled && root.wifiNetworks.length === 0)
                     || (devicePicker.bluetoothMode && devicePicker.radioOn && root.bluetoothDevices.length === 0)
            text: devicePicker.wifiMode ? (root.wifiRefreshPending ? "Searching for networks…" : "No networks found")
                                        : (root.adapter && root.adapter.discovering ? "Searching for devices…" : "No devices found")
            color: Theme.muted
            font.pixelSize: 12
        }

        ListView {
            id: inputAudioList
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: pickerHeader.bottom
            anchors.bottom: parent.bottom
            anchors.margins: 10
            anchors.topMargin: 12
            visible: root.displayedSection === "audio"
            clip: true
            spacing: 6
            model: root.audioSources

            header: Item {
                width: inputAudioList.width
                height: micMuteRow.height + 6

                NetRow {
                    id: micMuteRow
                    readonly property bool micMuted: !!(root.source && root.source.audio && root.source.audio.muted)

                    width: parent.width
                    icon: micMuted ? "\uDB80\uDF6D" : "\uDB80\uDF6C"
                    title: "Microphone"
                    subtitle: micMuted ? "Muted" : "On"
                    active: !micMuted
                    actionText: micMuted ? "Unmute" : "Mute"
                    onClicked: root.toggleAudio()
                }
            }

            delegate: NetRow {
                required property var modelData
                readonly property bool isDefault: root.source && modelData.id === root.source.id

                width: inputAudioList.width
                icon: "\uDB80\uDF6C"
                title: modelData.description || modelData.nickname || modelData.name
                subtitle: modelData.nickname && modelData.nickname !== title ? modelData.nickname : "Audio input"
                active: isDefault
                actionText: isDefault ? "Selected" : "Select"
                onClicked: Pipewire.preferredDefaultAudioSource = modelData
            }
        }

        ListView {
            id: outputAudioList
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: pickerHeader.bottom
            anchors.bottom: parent.bottom
            anchors.margins: 10
            anchors.topMargin: 12
            visible: root.displayedSection === "output"
            clip: true
            spacing: 6
            model: root.audioSinks

            delegate: NetRow {
                required property var modelData
                readonly property bool isDefault: root.sink && modelData.id === root.sink.id

                width: outputAudioList.width
                icon: "\uDB81\uDD7E"
                title: modelData.description || modelData.nickname || modelData.name
                subtitle: modelData.nickname && modelData.nickname !== title ? modelData.nickname : "Audio output"
                active: isDefault
                actionText: isDefault ? "Selected" : "Select"
                onClicked: Pipewire.preferredDefaultAudioSink = modelData
            }
        }

        Flickable {
            id: wifiLists
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: pickerHeader.bottom
            anchors.bottom: wifiPasswordRow.top
            anchors.margins: 10
            anchors.topMargin: 12
            anchors.bottomMargin: root.pendingWifiNetwork ? 8 : 10
            visible: devicePicker.wifiMode && Networking.wifiEnabled
            clip: true
            contentWidth: width
            contentHeight: wifiColumn.implicitHeight
            boundsBehavior: Flickable.StopAtBounds

            WheelHandler {
                target: null
                onWheel: (event) => root.scrollDetailList(wifiLists, event)
            }

            component WifiDelegate: NetRow {
                required property var modelData
                readonly property var network: modelData

                width: wifiColumn.width
                icon: root.wifiSignalIcon(network.signalStrength)
                title: network.name
                subtitle: (network.connected ? "Connected" : (network.known ? "Saved" : root.wifiSecurityLabel(network.security)))
                          + (root.wifiSignalPercent(network.signalStrength) !== null ? "  ·  " + root.wifiSignalPercent(network.signalStrength) + "%" : "")
                active: network.connected
                busy: network.stateChanging
                actionText: network.connected ? "Disconnect" : (!network.known && root.wifiUsesPsk(network.security) ? "Password" : "Connect")
                secondaryActionVisible: network.known
                secondaryActionName: "Forget " + network.name
                onClicked: root.selectWifi(network)
                onSecondaryClicked: network.forget()
            }

            Column {
                id: wifiColumn
                width: wifiLists.width
                spacing: 6

                SectionLabel {
                    width: parent.width
                    text: "Saved networks"
                    visible: root.knownWifiNetworks.length > 0
                }

                Repeater {
                    model: root.knownWifiNetworks
                    delegate: WifiDelegate {}
                }

                SectionLabel {
                    width: parent.width
                    text: "Available networks"
                    visible: root.availableWifiNetworks.length > 0
                }

                Repeater {
                    model: root.availableWifiNetworks
                    delegate: WifiDelegate {}
                }
            }
        }

        Rectangle {
            id: wifiPasswordRow
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            anchors.bottomMargin: root.pendingWifiNetwork ? 10 : 0
            height: root.pendingWifiNetwork ? 82 : 0
            visible: !!root.pendingWifiNetwork && devicePicker.wifiMode
            radius: 14
            color: Theme.bg1
            border.width: 1
            border.color: Theme.cardBorder

            ShellText {
                id: pwTitle
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                anchors.topMargin: 10
                elide: Text.ElideRight
                text: root.pendingWifiNetwork ? "Password for " + root.pendingWifiNetwork.name : ""
                color: Theme.muted
                font.pixelSize: 11
                font.weight: Font.DemiBold
            }

            Rectangle {
                id: pwField
                anchors.left: parent.left
                anchors.right: wifiConnectButton.left
                anchors.top: pwTitle.bottom
                anchors.leftMargin: 10
                anchors.rightMargin: 8
                anchors.topMargin: 8
                height: 32
                radius: 10
                color: Qt.rgba(1, 1, 1, 0.06)

                TextInput {
                    id: wifiPasswordInput
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    color: Theme.foreground
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    verticalAlignment: TextInput.AlignVCenter
                    echoMode: TextInput.Password
                    passwordCharacter: "•"
                    clip: true
                    Keys.onReturnPressed: root.connectPendingWifi()
                    Keys.onEnterPressed: root.connectPendingWifi()
                    Keys.onEscapePressed: (event) => {
                        wifiPasswordInput.clear();
                        root.pendingWifiNetwork = null;
                        event.accepted = true;
                    }
                }

                ShellText {
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    visible: wifiPasswordInput.text.length === 0
                    text: "Enter password"
                    color: Theme.muted
                    font.pixelSize: 12
                }
            }

            Rectangle {
                id: wifiConnectButton
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: pwField.verticalCenter
                width: 76
                height: 32
                radius: 16
                color: Theme.primary
                opacity: wifiPasswordInput.text.length > 0 ? 1 : 0.5

                ShellText {
                    anchors.centerIn: parent
                    text: "Connect"
                    color: Theme.bgDim
                    font.pixelSize: 12
                    font.weight: Font.Bold
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.connectPendingWifi()
                }
            }
        }

        Flickable {
            id: bluetoothLists
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: pickerHeader.bottom
            anchors.bottom: parent.bottom
            anchors.margins: 10
            anchors.topMargin: 12
            visible: devicePicker.bluetoothMode && devicePicker.radioOn
            clip: true
            contentWidth: width
            contentHeight: bluetoothColumn.implicitHeight
            boundsBehavior: Flickable.StopAtBounds

            WheelHandler {
                target: null
                onWheel: (event) => root.scrollDetailList(bluetoothLists, event)
            }

            component BluetoothDelegate: NetRow {
                required property var modelData
                readonly property var device: modelData

                width: bluetoothColumn.width
                icon: root.bluetoothIcon(device)
                title: device.name || device.deviceName || device.address
                subtitle: device.connected ? (device.batteryAvailable ? "Connected  ·  " + Math.round(device.battery * 100) + "%" : "Connected")
                                           : (device.paired || device.bonded ? "Paired" : "Not paired")
                active: device.connected
                busy: device.pairing || device.state === BluetoothDeviceState.Connecting || device.state === BluetoothDeviceState.Disconnecting
                actionText: device.connected ? "Disconnect" : (device.paired || device.bonded ? "Connect" : "Pair")
                secondaryActionVisible: device.paired || device.bonded
                secondaryActionName: "Remove " + (device.name || device.deviceName || device.address)
                onClicked: root.activateBluetoothDevice(device)
                onSecondaryClicked: device.forget()
            }

            Column {
                id: bluetoothColumn
                width: bluetoothLists.width
                spacing: 6

                SectionLabel {
                    width: parent.width
                    text: "Paired devices"
                    visible: root.knownBluetoothDevices.length > 0
                }

                Repeater {
                    model: root.knownBluetoothDevices
                    delegate: BluetoothDelegate {}
                }

                SectionLabel {
                    width: parent.width
                    text: "Nearby devices"
                    visible: root.availableBluetoothDevices.length > 0
                }

                Repeater {
                    model: root.availableBluetoothDevices
                    delegate: BluetoothDelegate {}
                }
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.animationNormal
                easing.type: Easing.OutCubic
            }
        }
    }
}
