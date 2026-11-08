
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

Item {
    id: root

    property bool alerted: false

    readonly property var device: UPower.displayDevice
    readonly property real level: device ? device.percentage : 0
    readonly property bool discharging: UPower.onBattery

    function checkBattery() {
        // Wait until UPower has supplied valid device information.
        if (!device || !device.ready || !device.isLaptopBattery)
            return;

        // Do not alert while charging or connected to AC power.
        if (!discharging) {
            alerted = false;
            return;
        }

        // A genuine low reading must still trigger a warning.
        if (level < 0.10 && !alerted) {
            alerted = true;

            lowBatteryNotification.command = [
                "gdbus", "call", "--session",
                "--dest", "org.freedesktop.Notifications",
                "--object-path", "/org/freedesktop/Notifications",
                "--method", "org.freedesktop.Notifications.Notify",
                "Power", "0", "battery-caution",
                "Battery level is critical",
                Math.round(level * 100) +
                    "% remaining · connect a charger soon.",
                "[]", "{'urgency': <byte 2>}", "0"
            ];

            lowBatteryNotification.running = true;
        } else if (level >= 0.12) {
            alerted = false;
        }
    }

    // Check after startup and then every five minutes.
    Timer {
        interval: 300000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.checkBattery()
    }

    // Recheck when UPower finishes initializing.
    Connections {
        target: root.device

        function onReadyChanged() {
            if (root.device && root.device.ready)
                root.checkBattery();
        }

        function onPercentageChanged() {
            if (root.device && root.device.ready)
                root.checkBattery();
        }
    }

    Connections {
        target: UPower

        function onOnBatteryChanged() {
            root.checkBattery();
        }
    }

    Process {
        id: lowBatteryNotification
    }
}
