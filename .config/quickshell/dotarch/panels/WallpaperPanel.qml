import QtQuick
import Quickshell
import Quickshell.Widgets
import qs
import qs.components
import ".."

FocusScope {
    id: root

    // One knob for the whole panel. 1.0 = size measured from the recording (705 x 189).
    readonly property real ui: 1.0
    // Tile size multiplier: grows tiles and panel height, keeps the width
    readonly property real tileK: 1.25
    readonly property real extra: Math.round((tileK - 1) * 120 * ui)

    readonly property string query: searchInput.text.trim().toLowerCase()
    readonly property var items: AppearanceState.wallpapers.filter(item => query === "" || root.fileLabel(item.path).toLowerCase().indexOf(query) >= 0)

    property int currentIndex: 0
    property real wheelAccum: 0
    property bool autoClose: false
    readonly property int applyDelay: 430

    // Fractional selected index, one critically damped spring (~270ms settle, no bounce)
    readonly property real sel: selSpring.value

    // Tile curves, indexed by distance from the selection (measured, ui = 1)
    readonly property var wTab: [158, 109, 96, 88, 80]
    readonly property var offTab: [0, 145, 254, 353, 443]
    readonly property var aTab: [1, 0.9, 0.55, 0.22, 0]

    function px(v) { return Math.round(v * ui); }

    function curve(arr, d) {
        const i = Math.max(0, Math.min(arr.length - 2, Math.floor(d)));
        const f = Math.max(0, Math.min(1, d - i));
        return arr[i] + (arr[i + 1] - arr[i]) * f;
    }

    function fileLabel(path) {
        const p = String(path || "");
        return p.substring(p.lastIndexOf("/") + 1);
    }

    function fileUrl(path) {
        const p = String(path || "");
        if (p === "")
            return "";
        return p.indexOf("/") === 0 ? "file://" + p : p;
    }

    function takeInitialFocus() {
        searchInput.clear();
        const index = root.items.findIndex(item => item.path === AppearanceState.currentWallpaper);
        root.currentIndex = Math.max(0, index);
        selSpring.snap(root.currentIndex);
        searchInput.forceActiveFocus(Qt.TabFocusReason);
    }

    function move(offset) {
        if (root.items.length === 0)
            return;
        root.currentIndex = Math.max(0, Math.min(root.items.length - 1, root.currentIndex + offset));
    }

    function activate(index) {
        const item = root.items[index];
        if (!item)
            return;
        AppearanceState.setWallpaper(item.path);
        if (root.autoClose)
            closeTimer.restart();
    }

    function handleKey(event) {
        const ctrl = (event.modifiers & Qt.ControlModifier);
        const plain = searchInput.text === "";
        const back = event.key === Qt.Key_Up || (plain && event.key === Qt.Key_Left)
            || (ctrl && (event.key === Qt.Key_H || event.key === Qt.Key_K || event.key === Qt.Key_P));
        const fwd = event.key === Qt.Key_Down || (plain && event.key === Qt.Key_Right)
            || (ctrl && (event.key === Qt.Key_L || event.key === Qt.Key_J || event.key === Qt.Key_N));
        if (back) {
            root.move(-1);
            event.accepted = true;
        } else if (fwd) {
            root.move(1);
            event.accepted = true;
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.activate(root.currentIndex);
            event.accepted = true;
        }
    }

    implicitWidth: Math.round(705 * ui)
    implicitHeight: Math.round(189 * ui) + extra

    Keys.onPressed: event => root.handleKey(event)

    onVisibleChanged: {
        if (visible)
            Qt.callLater(() => searchInput.forceActiveFocus(Qt.TabFocusReason));
    }

    // Handler, not a binding, so snap() can never break it
    onCurrentIndexChanged: selSpring.target = root.currentIndex

    onItemsChanged: {
        if (root.currentIndex > root.items.length - 1)
            root.currentIndex = Math.max(0, root.items.length - 1);
    }

    Timer {
        id: closeTimer
        interval: root.applyDelay
        onTriggered: ShellState.close()
    }

    Connections {
        target: ShellState

        function onPanelChanged() {
            if (ShellState.panel === "wallpaper") {
                AppearanceState.refreshWallpapers();
                AppearanceState.refreshCurrentWallpaper();
            }
        }
    }

    Spring {
        id: selSpring
        omega: 22
        zeta: 1.0
    }

    Item {
        id: content
        anchors.fill: parent

        WheelHandler {
            target: null
            onWheel: event => {
                root.wheelAccum += event.angleDelta.y !== 0 ? event.angleDelta.y : event.angleDelta.x;
                if (Math.abs(root.wheelAccum) >= 90) {
                    root.move(root.wheelAccum > 0 ? -1 : 1);
                    root.wheelAccum = 0;
                }
                event.accepted = true;
            }
        }

        // Search row
        Item {
            id: searchRow
            x: root.px(12)
            y: root.px(8)
            width: parent.width - 2 * root.px(12)
            height: root.px(24)

            ShellText {
                id: searchIcon
                x: root.px(8) - width / 2
                anchors.verticalCenter: parent.verticalCenter
                text: "\uDB80\uDF49"
                font.family: Theme.iconFontFamily
                font.pixelSize: Math.round(15 * root.ui)
                color: Qt.alpha(Theme.shellForeground, 0.6)
            }

            TextInput {
                id: searchInput
                anchors.left: parent.left
                anchors.leftMargin: root.px(26)
                anchors.right: folderLabel.left
                anchors.rightMargin: root.px(12)
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                color: Theme.foreground
                font.family: Theme.fontFamily
                font.pixelSize: Math.round(13.5 * root.ui)
                verticalAlignment: TextInput.AlignVCenter
                clip: true
                onTextChanged: {
                    root.currentIndex = 0;
                    selSpring.snap(0);
                }

                Keys.onPressed: event => root.handleKey(event)

                ShellText {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: !parent.text
                    text: "Search wallpapers..."
                    color: Qt.alpha(Theme.shellForeground, 0.4)
                    font.pixelSize: Math.round(13.5 * root.ui)
                }
            }

            // Theme folder name; click opens the wallpaper folder
            ShellText {
                id: folderLabel
                anchors.right: parent.right
                anchors.rightMargin: root.px(3)
                anchors.verticalCenter: parent.verticalCenter
                text: Theme.slug
                color: Qt.alpha(Theme.shellForeground, folderMouse.containsMouse ? 0.7 : 0.45)
                font.pixelSize: Math.round(11 * root.ui)

                MouseArea {
                    id: folderMouse
                    anchors.fill: parent
                    anchors.margins: -4
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: AppearanceState.openWallpaperFolder()
                }
            }
        }

        // Divider
        Rectangle {
            x: root.px(12)
            y: root.px(40)
            width: parent.width - 2 * root.px(12)
            height: 1
            color: Qt.alpha(Theme.shellForeground, 0.08)
        }

        // Carousel track: clipped to the panel margins so far tiles are cut off
        Item {
            id: track
            x: root.px(12)
            y: root.px(41)
            width: parent.width - 2 * root.px(12)
            height: root.px(120) + root.extra
            clip: true

            Repeater {
                model: root.items

                delegate: Item {
                    id: tile

                    required property int index
                    required property var modelData

                    readonly property real t: index - root.sel
                    readonly property real d: Math.abs(t)
                    readonly property bool isCurrent: modelData.path === AppearanceState.currentWallpaper
                    readonly property real tw: Math.round(root.curve(root.wTab, d) * root.ui * root.tileK)
                    readonly property real th: Math.round(tw / 1.64)
                    readonly property real off: root.curve(root.offTab, d) * root.ui * root.tileK * (t < 0 ? -1 : 1)

                    x: Math.round(track.width / 2 + off - tw / 2)
                    y: Math.round(track.height / 2 - th / 2)
                    width: tw
                    height: th
                    opacity: root.curve(root.aTab, d)
                    visible: d < 4.05
                    z: -d

                    ClippingRectangle {
                        anchors.fill: parent
                        radius: Math.round(tile.th * 0.15)
                        color: Qt.alpha(Theme.shellForeground, 0.06)

                        Image {
                            anchors.fill: parent
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: true
                            sourceSize.width: 380
                            // only tiles near the selection decode an image
                            source: tile.d < 4.5 ? root.fileUrl(tile.modelData.path) : ""
                            opacity: status === Image.Ready ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: 160 } }
                        }
                    }

                    // Marker on the wallpaper that is currently applied
                    Rectangle {
                        visible: tile.isCurrent
                        width: root.px(5)
                        height: root.px(5)
                        radius: width / 2
                        x: parent.width - width - root.px(7)
                        y: root.px(7)
                        color: Qt.alpha(Theme.shellForeground, 0.9)
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.currentIndex === tile.index)
                                root.activate(tile.index);
                            else
                                root.currentIndex = tile.index;
                        }
                    }
                }
            }
        }

        // Footer: file name left, position right
        ShellText {
            x: root.px(15)
            y: root.px(173) + root.extra - height / 2
            width: parent.width - 2 * root.px(15) - root.px(60)
            elide: Text.ElideMiddle
            text: root.items.length > 0 ? root.fileLabel(root.items[root.currentIndex].path) : ""
            color: Qt.alpha(Theme.shellForeground, 0.5)
            font.pixelSize: Math.round(11 * root.ui)
        }

        ShellText {
            anchors.right: parent.right
            anchors.rightMargin: root.px(15)
            y: root.px(173) + root.extra - height / 2
            text: root.items.length === 0 ? "0/0" : (root.currentIndex + 1) + "/" + root.items.length
            color: Qt.alpha(Theme.shellForeground, 0.4)
            font.pixelSize: Math.round(11 * root.ui)
        }

        ShellText {
            anchors.centerIn: track
            visible: root.items.length === 0
            horizontalAlignment: Text.AlignHCenter
            text: AppearanceState.wallpapers.length === 0 ? "No wallpapers in\n~/Pictures/Wallpapers/" + Theme.slug : "No wallpapers found"
            color: Qt.alpha(Theme.shellForeground, 0.45)
            font.pixelSize: Math.round(13.5 * root.ui)
        }
    }
}
