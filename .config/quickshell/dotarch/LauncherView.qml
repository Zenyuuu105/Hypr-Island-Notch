import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io

Item {
    id: launcherRoot
    property bool active: false
    
    // Updated to Catppuccin Mocha colors
    property color bgSurface: "#11111b" // Crust
    property color surface0: "#313244"  // Surface0 for hover/borders
    property color textPrimary: "#cdd6f4"
    property color textMuted: "#a6adc8"
    property color accentColor: "#a6e3a1" // Green accent

    signal requestClose()

    readonly property string query: searchInput.text
    readonly property string mode: {
        if (query.startsWith("=")) return "calc";
        if (query.startsWith(":")) return "clip";
        return "app";
    }
    readonly property string cleanQuery: {
        if (mode === "calc" || mode === "clip")
            return query.slice(1).trim();
        return query.trim();
    }

    readonly property string calcResult: {
        if (mode !== "calc" || cleanQuery.length === 0) return "";
        try {
            const sanitized = cleanQuery.replace(/[^0-9+\-*/().%^ ]/g, "");
            if (!sanitized) return "";
            const val = Function("\"use strict\"; return (" + sanitized.replace(/\^/g, "**") + ")")();
            return (val !== undefined && !isNaN(val)) ? String(val) : "...";
        } catch (e) {
            return "...";
        }
    }

    ListModel { id: clipboardModel }

    Process {
        id: cliphistFetch
        command: ["sh", "-c", "cliphist list | head -n 40"]
        stdout: SplitParser {
            onRead: data => {
                if (data.trim().length > 0) {
                    const parts = data.split("\t");
                    clipboardModel.append({
                        rawLine: data,
                        clipId: parts[0] || "",
                        preview: parts.slice(1).join(" ") || data
                    });
                }
            }
        }
    }

    Process {
        id: wlCopyProc
        property string payload: ""
        command: ["wl-copy", payload]
    }

    Process {
        id: clipDecodeProc
        property string rawEntry: ""
        command: ["sh", "-c", "printf '%s' \"$1\" | cliphist decode | wl-copy", "--", rawEntry]
    }

    ListModel { id: resultsModel }

    function rebuildResults() {
        const q = cleanQuery.toLowerCase();

        if (mode === "calc") {
            resultsModel.clear();
            if (cleanQuery.length > 0) {
                resultsModel.append({
                    uid: "calc_res",
                    title: "= " + calcResult,
                    subtitle: "Press Enter to copy result to clipboard",
                    itemType: "calc",
                    payload: calcResult,
                    iconName: ""
                });
            }
            return;
        }

        if (mode === "clip") {
            resultsModel.clear();
            for (let i = 0; i < clipboardModel.count; i++) {
                const item = clipboardModel.get(i);
                if (q === "" || item.preview.toLowerCase().includes(q)) {
                    resultsModel.append({
                        uid: "clip_" + item.clipId,
                        title: item.preview,
                        subtitle: "Clipboard #" + item.clipId,
                        itemType: "clip",
                        payload: item.rawLine,
                        iconName: ""
                    });
                }
            }
            resultsList.currentIndex = resultsModel.count > 0 ? 0 : -1;
            return;
        }

        resultsModel.clear();
        const apps = DesktopEntries.applications.values;
        for (let i = 0; i < apps.length; i++) {
            const app = apps[i];
            const nameMatch = app.name && app.name.toLowerCase().includes(q);
            const commentMatch = app.comment && app.comment.toLowerCase().includes(q);
            if (q === "" || nameMatch || commentMatch) {
                resultsModel.append({
                    uid: app.id,
                    title: app.name,
                    subtitle: app.comment || app.execString || "Application",
                    itemType: "app",
                    appIndex: i,
                    iconName: app.icon || "" // Extract icon for the UI
                });
                if (resultsModel.count >= 8) break;
            }
        }
        resultsList.currentIndex = resultsModel.count > 0 ? 0 : -1;
    }

    function executeCurrent() {
        if (resultsList.currentIndex < 0 || resultsList.currentIndex >= resultsModel.count)
            return;

        const item = resultsModel.get(resultsList.currentIndex);
        if (item.itemType === "calc") {
            wlCopyProc.payload = item.payload;
            wlCopyProc.running = true;
        } else if (item.itemType === "clip") {
            clipDecodeProc.rawEntry = item.payload;
            clipDecodeProc.running = true;
        } else if (item.itemType === "app") {
            const app = DesktopEntries.applications.values[item.appIndex];
            if (app) app.execute();
        }
        requestClose();
    }

    onActiveChanged: {
        if (active) {
            searchInput.text = "";
            clipboardModel.clear();
            cliphistFetch.running = true;
            rebuildResults();
            searchInput.forceActiveFocus();
        }
    }

    onQueryChanged: rebuildResults()

    // Outer Container updated to dark theme
    Rectangle {
        anchors.fill: parent
        color: launcherRoot.bgSurface
        radius: 16
        border.color: launcherRoot.surface0
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            // Search Bar 
            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                
                Text {
                    text: launcherRoot.mode === "calc" ? "=" : (launcherRoot.mode === "clip" ? "clip" : "")
                    color: launcherRoot.textMuted
                    font.pixelSize: 14
                    font.family: "monospace" // Fallback if no icon font
                }

                TextInput {
                    id: searchInput
                    Layout.fillWidth: true
                    color: launcherRoot.textPrimary
                    font.pixelSize: 15
                    clip: true
                    selectionColor: launcherRoot.surface0

                    Keys.onDownPressed: {
                        if (resultsList.currentIndex < resultsModel.count - 1)
                            resultsList.currentIndex++;
                    }
                    Keys.onUpPressed: {
                        if (resultsList.currentIndex > 0)
                            resultsList.currentIndex--;
                    }
                    Keys.onReturnPressed: launcherRoot.executeCurrent()
                    Keys.onEnterPressed: launcherRoot.executeCurrent()
                    Keys.onEscapePressed: launcherRoot.requestClose()
                }
            }

            // Subtle separator line
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: launcherRoot.surface0
            }

            ListView {
                id: resultsList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: resultsModel
                spacing: 4

                add: Transition {
                    NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 150; easing.type: Easing.OutCubic }
                    NumberAnimation { property: "scale"; from: 0.96; to: 1.0; duration: 150; easing.type: Easing.OutCubic }
                }
                remove: Transition {
                    NumberAnimation { property: "opacity"; to: 0; duration: 120; easing.type: Easing.InCubic }
                }

                delegate: Rectangle {
                    id: delegateRoot
                    width: resultsList.width
                    height: 52
                    radius: 8
                    
                    color: ListView.isCurrentItem ? launcherRoot.surface0 : "transparent"

                    // Mouse interactions for the hover state
                    HoverHandler {
                        onHoveredChanged: {
                            if (hovered) resultsList.currentIndex = index
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: launcherRoot.executeCurrent()
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        anchors.leftMargin: 4
                        spacing: 12

                        // Left vertical accent indicator
                        Rectangle {
                            width: 3
                            height: 24
                            radius: 2
                            color: launcherRoot.accentColor
                            visible: ListView.isCurrentItem
                        }

                        // Icon handling (Apps vs Clip/Calc)
                        Image {
                            source: model.itemType === "app" && model.iconName ? Quickshell.iconPath(model.iconName, true) : ""
                            sourceSize: Qt.size(32, 32)
                            Layout.preferredWidth: 32
                            Layout.preferredHeight: 32
                            visible: model.itemType === "app"
                        }
                        
                        Rectangle {
                            Layout.preferredWidth: 32
                            Layout.preferredHeight: 32
                            radius: 6
                            color: launcherRoot.surface0
                            visible: model.itemType !== "app"
                            Text {
                                anchors.centerIn: parent
                                text: model.itemType === "calc" ? "=" : "📋"
                                color: launcherRoot.textMuted
                            }
                        }

                        // Text Column
                        ColumnLayout {
                            spacing: 2
                            Layout.fillWidth: true
                            
                            Text {
                                text: model.title
                                color: launcherRoot.textPrimary
                                font.bold: true
                                font.pixelSize: 13
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                            Text {
                                text: model.subtitle
                                color: launcherRoot.textMuted
                                font.pixelSize: 11
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                                visible: text.length > 0
                            }
                        }
                    }
                }
            }
        }
    }
}