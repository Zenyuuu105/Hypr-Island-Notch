import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io

Item {
    id: launcherRoot
    property bool active: false
    property color bgSurface: "#1e1e2e"
    property color textPrimary: "#cdd6f4"
    property color textMuted: "#a6adc8"
    property color accentColor: "#89b4fa"

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
                    payload: calcResult
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
                        payload: item.rawLine
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
                    appIndex: i
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

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 10

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            radius: 12
            color: Qt.lighter(launcherRoot.bgSurface, 1.15)
            border.width: 1
            border.color: launcherRoot.accentColor

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 8

                Text {
                    text: launcherRoot.mode === "calc" ? "CALC" : (launcherRoot.mode === "clip" ? "CLIP" : ">|")
                    color: launcherRoot.accentColor
                    font.pixelSize: 13
                    font.bold: true
                }

                TextInput {
                    id: searchInput
                    Layout.fillWidth: true
                    color: launcherRoot.textPrimary
                    font.pixelSize: 15
                    clip: true

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
        }

        ListView {
            id: resultsList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: resultsModel
            spacing: 6

            add: Transition {
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 150; easing.type: Easing.OutCubic }
                NumberAnimation { property: "scale"; from: 0.94; to: 1.0; duration: 150; easing.type: Easing.OutCubic }
            }
            remove: Transition {
                NumberAnimation { property: "opacity"; to: 0; duration: 120; easing.type: Easing.InCubic }
            }
            displaced: Transition {
                SpringAnimation { property: "y"; spring: 4.5; damping: 1.0; mass: 1.0 }
            }

            delegate: Rectangle {
                width: resultsList.width
                height: 44
                radius: 10
                color: ListView.isCurrentItem
                       ? Qt.rgba(launcherRoot.accentColor.r, launcherRoot.accentColor.g, launcherRoot.accentColor.b, 0.22)
                       : "transparent"
                border.width: ListView.isCurrentItem ? 1 : 0
                border.color: launcherRoot.accentColor

                ColumnLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 2

                    Text {
                        text: model.title
                        color: launcherRoot.textPrimary
                        font.pixelSize: 14
                        font.bold: ListView.isCurrentItem
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                    Text {
                        text: model.subtitle
                        color: launcherRoot.textMuted
                        font.pixelSize: 11
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }
            }
        }
    }
}
