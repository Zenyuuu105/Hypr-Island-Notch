pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string dir: Quickshell.env("HOME") + "/.config/quickshell/dotarch"
    readonly property string settingsPath: dir + "/settings.json"
    readonly property string backupPath: dir + "/settings.backup.json"

    property alias cfg: adapter

    readonly property var defaults: ({
        shape: "notch", collapsedWidth: 0, collapsedHeight: 32, expandedWidth: 0, expandedHeight: 82,
        cornerRadius: 20, notchFlare: 16, islandTopMargin: 10, notchWindowGap: 10, islandWindowGap: 10, bottomEdgeGap: 0, offsetX: 0, backgroundOpacity: 100,
        panelWidth: 0, panelHeight: 0, panelRadius: 24,
        showWorkspaces: true, showClock: true, showDate: false, showWifi: true, showBattery: true,
        showBluetooth: false, showVolume: false, showMedia: false, showBell: false,
        showHoverClock: true, showHoverDate: true, showHoverWorkspaces: true, showHoverStatus: true, showHoverMedia: true,
        workspaceCount: 5, workspaceStyle: "dots",
        clock24h: false, showSeconds: false, dateFormat: "ddd, MMM d", clockSize: 16, hoverClockSize: 17,
        expandOnHover: true, hoverDelay: 0, hoverExitDelay: 250, animationsEnabled: true, animationDuration: 270,
        osdVolume: true, osdBrightness: true, osdDuration: 1500,
        uiAccent: "#0a84ff"
    })

    function apply(values) { for (const k in values) adapter[k] = values[k] }
    function reset() { apply(defaults) }
    function resetKeys(keys) { for (const k of keys) if (defaults[k] !== undefined) adapter[k] = defaults[k] }
    function backup() { Quickshell.execDetached(["cp", "-f", settingsPath, backupPath]) }
    function restore() { restoreProc.running = true }

    Process {
        id: restoreProc
        command: ["cp", "-f", root.backupPath, root.settingsPath]
        onExited: file.reload()
    }

    FileView {
        id: file
        path: root.settingsPath
        blockLoading: true
        onAdapterUpdated: writeAdapter()
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) writeAdapter()
        }

        adapter: JsonAdapter {
            id: adapter
            property string shape: "notch"
            property int collapsedWidth: 0
            property int collapsedHeight: 32
            property int expandedWidth: 0
            property int expandedHeight: 82
            property int cornerRadius: 20
            property int notchFlare: 16
            property int islandTopMargin: 10
            property int notchWindowGap: 10
            property int islandWindowGap: 10
            property int bottomEdgeGap: 0
            property int offsetX: 0
            property int backgroundOpacity: 100
            property int panelWidth: 0
            property int panelHeight: 0
            property int panelRadius: 24
            property bool showWorkspaces: true
            property bool showClock: true
            property bool showDate: false
            property bool showWifi: true
            property bool showBattery: true
            property bool showBluetooth: false
            property bool showVolume: false
            property bool showMedia: false
            property bool showBell: false
            property bool showHoverClock: true
            property bool showHoverDate: true
            property bool showHoverWorkspaces: true
            property bool showHoverStatus: true
            property bool showHoverMedia: true
            property int workspaceCount: 5
            property string workspaceStyle: "dots"
            property bool clock24h: false
            property bool showSeconds: false
            property string dateFormat: "ddd, MMM d"
            property int clockSize: 16
            property int hoverClockSize: 17
            property bool expandOnHover: true
            property int hoverDelay: 0
            property int hoverExitDelay: 250
            property bool animationsEnabled: true
            property int animationDuration: 270
            property bool osdVolume: true
            property bool osdBrightness: true
            property int osdDuration: 1500
            property string uiAccent: "#0a84ff"
        }
    }
}
