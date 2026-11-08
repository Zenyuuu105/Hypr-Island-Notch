import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import qs

ShellRoot {
    id: root

    property string pendingCaptureMode: ""

    NotificationServer {
        id: notificationServer

        keepOnReload: true
        bodySupported: true
        bodyMarkupSupported: false
        actionsSupported: true
        imageSupported: true
        Component.onCompleted: ShellState.notificationModel = trackedNotifications
        onNotification: notification => {
            notification.tracked = true;
            if (ShellState.peaceMode)
                return ;
            ShellState.presentNotification(notification);
            
            // Create a native QML timer to close the notification after 5000ms
            var timer = Qt.createQmlObject('import QtQuick; Timer { interval: 5000; running: true; property var n; onTriggered: { if (n) n.close(); destroy(); } }', notificationServer, "autoCloseTimer");
            timer.n = notification;
        }
    }

    LowBatteryMonitor {}

    IpcHandler {
        function toggle() {
            ShellState.togglePeaceMode();
        }

        function status(): string {
            return ShellState.peaceMode ? "on" : "off";
        }

        target: "peace"
    }

    Variants {
        model: Quickshell.screens

        Notch {
            required property var modelData

            screen: modelData
        }

    }

    Variants {
        model: Quickshell.screens

        NotchSpacer {
            required property var modelData

            screen: modelData
        }

    }

    Variants {
        model: Quickshell.screens

        CaptureSelector {
            required property var modelData

            screen: modelData
        }

    }

    IpcHandler {
        function toggle(panel: string) {
            ShellState.show(panel);
        }

        function close() {
            ShellState.close();
        }

        function next() {
            ShellState.cycle(1);
        }

        function previous() {
            ShellState.cycle(-1);
        }

        function toggleStacking() {
            ShellState.notchAboveWindows = !ShellState.notchAboveWindows;
        }

        target: "notch"
    }

    IpcHandler {
        function reload() {
            Theme.reload();
            AppearanceState.refreshThemes();
            AppearanceState.refreshWallpapers();
        }

        target: "theme"
    }

    IpcHandler {
        function screenshot(mode: string) {
            if (!["full", "window", "region"].includes(mode))
                return;

            root.pendingCaptureMode = mode;
            if (mode !== "region")
                ShellState.close();
            captureShortcutDelay.restart();
        }

        function toggleRecording() {
            if (Backend.recording) {
                Backend.toggleRecording();
                return;
            }

            ShellState.close();
            recordingShortcutDelay.restart();
        }

        target: "capture"
    }

    Timer {
        id: captureShortcutDelay

        interval: Theme.animationNormal + 100
        onTriggered: {
            Backend.capture(root.pendingCaptureMode);
            root.pendingCaptureMode = "";
        }
    }

    Timer {
        id: recordingShortcutDelay

        interval: Theme.animationNormal + 100
        onTriggered: Backend.toggleRecording()
    }


    SettingsWindow { id: settingsWin }

    IpcHandler {
        target: "settings"
        function toggle(): void { settingsWin.visible = !settingsWin.visible }
        function open(): void   { settingsWin.visible = true }
        function close(): void  { settingsWin.visible = false }
    }
}