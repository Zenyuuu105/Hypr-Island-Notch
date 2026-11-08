import QtQuick
import Quickshell.Widgets
import qs
import qs.components
import ".."

FocusScope {
    id: root

    // Keep this equal to ui in ThemePanel.qml so both panels are the same size
    readonly property real ui: 1.2

    readonly property string query: searchInput.text.trim().toLowerCase()
    readonly property var items: AppearanceState.wallpapers.filter(item => query === "" || root.fileLabel(item.path).toLowerCase().indexOf(query) >= 0)
    readonly property var selected: root.items.length > 0 && root.currentIndex < root.items.length ? root.items[root.currentIndex] : null

    readonly property real cardWidth: 133 * ui
    readonly property real cardHeight: 69 * ui
    readonly property real pitch: 138.5 * ui
    readonly property int applyDelay: 430
    // Only this many cards on each side of the selection load their image
    readonly property int loadRadius: 5

    property int currentIndex: 0
    property real wheelAccum: 0
    property bool applying: false

    function fileLabel(path) {
        return String(path).split("/").pop().replace(/\.[^.]+$/, "");
    }

    function selectCurrent() {
        const list = root.items;
        if (list.length === 0) {
            root.currentIndex = 0;
            return;
        }
        const path = AppearanceState.currentWallpaper;
        let index = list.findIndex(item => item.path === path);
        if (index < 0 && path)
            index = list.findIndex(item => item.name === path.split("/").pop());
        root.currentIndex = Math.max(0, index);
        scroll.snap(root.currentIndex * root.pitch);
    }

    function takeInitialFocus() {
        applying = false;
        searchInput.clear();
        root.selectCurrent();
        searchInput.forceActiveFocus(Qt.TabFocusReason);
    }

    function move(offset) {
        if (root.items.length === 0)
            return;
        root.currentIndex = Math.max(0, Math.min(root.items.length - 1, root.currentIndex + offset));
    }

    function activate(index) {
        if (root.applying)
            return;
        const item = root.items[index];
        if (!item)
            return;
        root.applying = true;
        AppearanceState.setWallpaper(item.path);
        closeTimer.restart();
    }

    function handleKey(event) {
        if (event.key === Qt.Key_Left || ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_H)) {
            root.move(-1);
            event.accepted = true;
        } else if (event.key === Qt.Key_Right || ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_L)) {
            root.move(1);
            event.accepted = true;
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.activate(root.currentIndex);
            event.accepted = true;
        }
    }

    implicitWidth: Math.round(572 * ui)
    implicitHeight: Math.round(158 * ui)

    Keys.onPressed: event => root.handleKey(event)

    onVisibleChanged: {
        if (visible)
            Qt.callLater(() => searchInput.forceActiveFocus(Qt.TabFocusReason));
    }

    // Handler, not a binding, so snap() can never break it
    onCurrentIndexChanged: scroll.target = root.currentIndex * root.pitch

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

    Connections {
        target: AppearanceState

        function onWallpapersChanged() {
            if (root.query === "")
                Qt.callLater(root.selectCurrent);
        }

        function onCurrentWallpaperChanged() {
            if (root.query === "" && !root.applying)
                Qt.callLater(root.selectCurrent);
        }
    }

    // Same critically damped spring as the theme switcher
    Spring {
        id: scroll
        omega: 20
        zeta: 1.0
    }

    Item {
        id: content
        anchors.fill: parent
        opacity: root.applying ? 0 : 1

        Behavior on opacity {
            NumberAnimation {
                duration: root.applying ? 200 : 140
                easing.type: Easing.OutCubic
            }
        }

        // Search pill
        Rectangle {
            x: 6 * root.ui
            y: 4 * root.ui
            width: parent.width - 12 * root.ui
            height: 32 * root.ui
            radius: 10 * root.ui
            color: "transparent"
            border.width: 1
            border.color: Qt.alpha(Theme.shellForeground, 0.07)
        }

        // Search row
        Item {
            id: searchRow
            x: 16 * root.ui
            y: 6 * root.ui
            width: parent.width - 32 * root.ui
            height: 28 * root.ui

            ShellText {
                id: searchIcon
                anchors.left: parent.left
                anchors.leftMargin: 2 * root.ui
                anchors.verticalCenter: parent.verticalCenter
                text: "\uDB80\uDF49"
                font.family: Theme.iconFontFamily
                font.pixelSize: Math.round(13 * root.ui)
                color: Theme.mutedDark
            }

            TextInput {
                id: searchInput
                anchors.left: searchIcon.right
                anchors.leftMargin: 8 * root.ui
                anchors.right: folderIcon.left
                anchors.rightMargin: 12 * root.ui
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                color: Theme.foreground
                font.family: Theme.fontFamily
                font.pixelSize: Math.round(13 * root.ui)
                verticalAlignment: TextInput.AlignVCenter
                clip: true
                onTextChanged: root.currentIndex = 0

                Keys.onPressed: event => root.handleKey(event)

                ShellText {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: !parent.text
                    text: "Search wallpapers..."
                    color: Theme.mutedDark
                    font.pixelSize: Math.round(13 * root.ui)
                }
            }

            // Opens the wallpaper folder (kept from the old panel)
            ShellText {
                id: folderIcon
                anchors.right: counter.left
                anchors.rightMargin: 12 * root.ui
                anchors.verticalCenter: parent.verticalCenter
                text: "\uDB80\uDE4B"
                font.family: Theme.iconFontFamily
                font.pixelSize: Math.round(13 * root.ui)
                color: folderPointer.containsMouse ? Theme.foreground : Theme.mutedDark

                MouseArea {
                    id: folderPointer
                    anchors.fill: parent
                    anchors.margins: -6
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: AppearanceState.openWallpaperFolder()
                }
            }

            ShellText {
                id: counter
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: root.items.length === 0 ? "0/0" : (root.currentIndex + 1) + "/" + root.items.length
                color: Theme.mutedDark
                font.pixelSize: Math.round(11 * root.ui)
            }
        }

        // Carousel, hard-clipped 10px (times ui) in from each side
        Item {
            id: carousel
            x: 10 * root.ui
            y: 42 * root.ui
            width: parent.width - 20 * root.ui
            height: root.cardHeight + 16 * root.ui
            clip: true

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

            Item {
                id: strip
                x: (carousel.width - root.cardWidth) / 2 - scroll.value
                width: Math.max(1, root.items.length) * root.pitch
                height: carousel.height

                Repeater {
                    model: root.items

                    delegate: Item {
                        id: card

                        required property int index
                        required property var modelData

                        readonly property bool isCurrent: modelData.path === AppearanceState.currentWallpaper
                        // 1 when centred, 0 one pitch away: ring and dimming follow
                        // the scroll position. No lift for wallpapers.
                        readonly property real p: Math.max(0, Math.min(1, 1 - Math.abs(x - scroll.value) / root.pitch))

                        x: index * root.pitch
                        width: root.cardWidth
                        height: carousel.height

                        ClippingRectangle {
                            id: surface
                            y: 6 * root.ui
                            width: root.cardWidth
                            height: root.cardHeight
                            radius: 12 * root.ui
                            color: Theme.bg1

                            Image {
                                anchors.fill: parent
                                source: Math.abs(card.index - root.currentIndex) <= root.loadRadius ? encodeURI("file://" + card.modelData.path) : ""
                                fillMode: Image.PreserveAspectCrop
                                sourceSize.width: 400
                                asynchronous: true
                                cache: true
                                mipmap: true
                                opacity: status === Image.Ready ? 1 : 0

                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: 200
                                    }
                                }
                            }

                            // Dims unselected cards
                            Rectangle {
                                anchors.fill: parent
                                color: Theme.shellBackground
                                opacity: 0.5 * (1 - card.p)
                            }

                            // Applied marker
                            Rectangle {
                                visible: card.isCurrent
                                anchors.top: parent.top
                                anchors.right: parent.right
                                anchors.topMargin: 5 * root.ui
                                anchors.rightMargin: 5 * root.ui
                                width: 6 * root.ui
                                height: 6 * root.ui
                                radius: width / 2
                                color: Theme.shellForeground
                                opacity: 0.6 + 0.4 * card.p
                            }
                        }

                        // Selection ring crossfades between cards while scrolling
                        Rectangle {
                            x: surface.x
                            y: surface.y
                            width: surface.width
                            height: surface.height
                            radius: surface.radius
                            color: "transparent"
                            border.width: 2
                            border.color: Theme.shellForeground
                            opacity: card.p
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (root.currentIndex === card.index)
                                    root.activate(card.index);
                                else
                                    root.currentIndex = card.index;
                            }
                        }
                    }
                }
            }

            // Edge fades so cards dissolve instead of being cut off
            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 40 * root.ui
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: Theme.shellBackground }
                    GradientStop { position: 1.0; color: Qt.alpha(Theme.shellBackground, 0) }
                }
            }

            Rectangle {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 40 * root.ui
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: Qt.alpha(Theme.shellBackground, 0) }
                    GradientStop { position: 1.0; color: Theme.shellBackground }
                }
            }

            ShellText {
                anchors.centerIn: parent
                width: parent.width - 40
                visible: root.items.length === 0
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                color: Theme.mutedDark
                font.pixelSize: Math.round(12 * root.ui)
                text: AppearanceState.wallpapers.length === 0 ? "No wallpapers in\n~/Pictures/Wallpapers/" + Theme.slug : "No wallpapers found"
            }
        }

        // Footer: file name on the left, hint on the right
        ShellText {
            anchors.left: parent.left
            anchors.leftMargin: 10 * root.ui
            anchors.right: footerRight.left
            anchors.rightMargin: 12 * root.ui
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 10 * root.ui
            elide: Text.ElideMiddle
            text: root.selected ? root.fileLabel(root.selected.path) : ""
            color: Theme.mutedDark
            font.pixelSize: Math.round(11 * root.ui)
        }

        Row {
            id: footerRight
            anchors.right: parent.right
            anchors.rightMargin: 10 * root.ui
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 9 * root.ui
            spacing: 14 * root.ui

            KeyHint { ui: root.ui; keys: "← →"; label: "Browse" }
            KeyHint { ui: root.ui; keys: "Enter"; label: "Apply" }
        }
    }
}
