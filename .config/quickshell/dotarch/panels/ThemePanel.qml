import QtQuick
import Quickshell
import qs
import qs.components
import ".."

FocusScope {
    id: root

    // One knob for the whole panel. 1.0 = exactly the size in the recording.
    readonly property real ui: 1.2

    readonly property string query: searchInput.text.trim().toLowerCase()
    readonly property var liveThemes: AppearanceState.themes.filter(theme => query === "" || theme.name.toLowerCase().indexOf(query) >= 0)
    property var frozenThemes: []
    readonly property var themes: root.applying ? root.frozenThemes : root.liveThemes

    // Measured from the recording, times ui
    readonly property real cardWidth: 133 * ui
    readonly property real cardHeight: 69 * ui
    readonly property real pitch: 138.5 * ui
    readonly property real lift: 6 * ui
    readonly property int applyDelay: 430

    property int currentIndex: 0
    property real wheelAccum: 0
    property bool applying: false
    property bool autoClose: false
    property color dimColor: "#101010"

    function takeInitialFocus() {
        applying = false;
        root.dimColor = Theme.shellBackground;
        searchInput.clear();
        const index = root.themes.findIndex(theme => theme.slug === Theme.slug);
        root.currentIndex = Math.max(0, index);
        scroll.snap(root.currentIndex * root.pitch);
        searchInput.forceActiveFocus(Qt.TabFocusReason);
    }

    function move(offset) {
        if (root.themes.length === 0)
            return;
        root.currentIndex = Math.max(0, Math.min(root.themes.length - 1, root.currentIndex + offset));
    }

    function activate(index) {
        if (root.applying)
            return;
        const theme = root.themes[index];
        if (!theme)
            return;
        root.frozenThemes = root.liveThemes;
        root.applying = true;
        AppearanceState.applyTheme(theme.slug);
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
        onTriggered: {
            if (root.autoClose)
                ShellState.close();
            else
                root.applying = false;
        }
    }

    Connections {
        target: ShellState

        function onPanelChanged() {
            if (ShellState.panel === "theme")
                AppearanceState.refreshThemes();
        }
    }

    // Critically damped spring measured from the video, no overshoot
    Spring {
        id: scroll
        omega: 20
        zeta: 1.0
    }

    Item {
        id: content
        anchors.fill: parent
        opacity: 1

        Behavior on opacity {
            NumberAnimation {
                duration: root.applying ? 120 : 140
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
                anchors.right: counter.left
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
                    text: "Search themes..."
                    color: Theme.mutedDark
                    font.pixelSize: Math.round(13 * root.ui)
                }
            }

            ShellText {
                id: counter
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: root.themes.length === 0 ? "0/0" : (root.currentIndex + 1) + "/" + root.themes.length
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
                width: Math.max(1, root.themes.length) * root.pitch
                height: carousel.height

                Repeater {
                    model: root.themes

                    delegate: Item {
                        id: card

                        required property int index
                        required property var modelData

                        readonly property var c: modelData.colors
                        readonly property bool isCurrent: modelData.slug === Theme.slug
                        // 1 when centred, 0 one pitch away: lift, ring, dimming and
                        // label brightness all follow the scroll position
                        readonly property real p: Math.max(0, Math.min(1, 1 - Math.abs(x - scroll.value) / root.pitch))

                        x: index * root.pitch
                        width: root.cardWidth
                        height: carousel.height

                        Rectangle {
                            id: surface
                            y: 6 * root.ui - root.lift * card.p
                            width: root.cardWidth
                            height: root.cardHeight
                            radius: 12 * root.ui
                            color: card.c.bg0
                            border.width: 1
                            border.color: Qt.alpha(card.c.foreground, 0.10)

                            Row {
                                anchors.horizontalCenter: parent.horizontalCenter
                                y: 24 * root.ui
                                spacing: 2.7 * root.ui

                                Repeater {
                                    model: [card.c.red, card.c.green, card.c.yellow, card.c.blue, card.c.purple, card.c.aqua]

                                    Rectangle {
                                        required property var modelData
                                        width: 10 * root.ui
                                        height: 10 * root.ui
                                        radius: width / 2
                                        color: modelData || "#888888"
                                    }
                                }
                            }

                            ShellText {
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: 6 * root.ui
                                width: parent.width - 20 * root.ui
                                horizontalAlignment: Text.AlignHCenter
                                text: card.modelData.name
                                color: card.c.foreground
                                elide: Text.ElideRight
                                font.pixelSize: Math.round(11 * root.ui)
                                font.weight: Font.DemiBold
                            }

                            // Dims dots, label and background of unselected cards
                            Rectangle {
                                anchors.fill: parent
                                radius: parent.radius
                                color: root.dimColor
                                opacity: 0.6 * (1 - card.p)
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
                                color: card.c.primary
                                opacity: 0.6 + 0.4 * card.p
                            }
                        }

                        // Selection ring: white, turns the theme accent while applying
                        Rectangle {
                            x: surface.x
                            y: surface.y
                            width: surface.width
                            height: surface.height
                            radius: surface.radius
                            color: "transparent"
                            border.width: 2
                            border.color: root.applying ? card.c.primary : Theme.shellForeground
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
                visible: root.themes.length === 0
                text: "No themes found"
                color: Theme.mutedDark
                font.pixelSize: Math.round(13 * root.ui)
            }
        }

        // Footer
        Row {
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
