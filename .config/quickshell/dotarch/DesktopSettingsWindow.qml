import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import "ui/Singletons"
import "ui" as RUI

FloatingWindow {
    id: win

    title: "Desktop Settings"
    visible: false
    color: Tokens.paper

    implicitWidth: 1280
    implicitHeight: 800

    property int page: 0

    readonly property string uiFont: "Geist"

    readonly property var pages: [
        { name: "Overview", jp: "概要", group: "HOME", icon: "⌂", description: "Your desktop at a glance" },
        { name: "Appearance", jp: "外観", group: "LOOK & FEEL", icon: "◈", description: "Themes, wallpapers and fonts" },
        { name: "Windows", jp: "窓", group: "LOOK & FEEL", icon: "▣", description: "Window appearance and behaviour" },
        { name: "Animations", jp: "動き", group: "LOOK & FEEL", icon: "✧", description: "Motion and animation settings" },
        { name: "Displays", jp: "画面", group: "HARDWARE", icon: "▤", description: "Monitor and screen configuration" },
        { name: "Input", jp: "入力", group: "HARDWARE", icon: "⌨", description: "Keyboard, touchpad and shortcuts" },
        { name: "Lock Screen", jp: "施錠", group: "SYSTEM", icon: "▢", description: "Session lock and login screen" },
        { name: "Startup", jp: "起動", group: "SYSTEM", icon: "↗", description: "Applications and startup behaviour" },
        { name: "Cursors & Fonts", jp: "矢印", group: "SYSTEM", icon: "⌁", description: "Cursor themes and application fonts" }
    ]

    readonly property var activePage: pages[page]

    // Ryoku-style page exchange: keep the layout synchronous, fade the
    // already-selected page in without timers or layout reflow.
    onPageChanged: {
        pageFade.stop()
        pageContent.opacity = 0
        pageFade.start()
    }

    readonly property var quickLinks: [
        { title: "Appearance", detail: "Themes and wallpapers", icon: "◈", target: 1 },
        { title: "Windows", detail: "Gaps, blur and rounding", icon: "▣", target: 2 },
        { title: "Animations", detail: "Motion and transitions", icon: "✧", target: 3 },
        { title: "Lock Screen", detail: "Login and lock themes", icon: "▢", target: 6 }
    ]

    onVisibleChanged: {
        if (visible) {
            openFade.restart()
            Qt.callLater(() => {
                var p = win.page
                win.page = -1
                win.page = p
            })
        }
    }

    NumberAnimation {
        id: openFade
        target: shell
        property: "opacity"
        from: 0
        to: 1
        duration: Tokens.swap
        easing.type: Tokens.ease
    }

    Shortcut {
        sequence: "Ctrl+W"
        onActivated: win.visible = false
    }

    Rectangle {
        anchors.fill: parent
        color: Tokens.paper
    }

    RowLayout {
        id: shell
        anchors.fill: parent
        spacing: 0

        // RYOKU-STYLE NAVIGATION RAIL
        Rectangle {
            Layout.preferredWidth: Tokens.railW
            Layout.fillHeight: true
            color: Tokens.paper

            Rectangle {
                anchors.right: parent.right
                width: 1
                height: parent.height
                color: Tokens.lineSoft
            }

            Rectangle {
            id: navPlate
            property bool ready: false
            readonly property var cur: navRepeater.itemAt(win.page)
            x: 22
            width: parent.width - 44
            height: 42
            radius: Tokens.radius
            color: Tokens.bone
            y: cur ? navCol.y + cur.y + cur.rowY : 0
            onYChanged: if (y > 0) ready = true
            Behavior on y {
                enabled: navPlate.ready
                NumberAnimation { duration: Tokens.move; easing.type: Tokens.ease }
            }
        }

            ColumnLayout {
                id: navCol
                anchors.fill: parent
                anchors.leftMargin: 22
                anchors.rightMargin: 22
                anchors.topMargin: 28
                anchors.bottomMargin: 24
                spacing: 0

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 11

                    Rectangle {
                        Layout.preferredWidth: 34
                        Layout.preferredHeight: 34
                        radius: Tokens.radius
                        color: Tokens.bone

                        Text {
                            anchors.centerIn: parent
                            text: "//"
                            color: Tokens.inkOnBone
                            font.family: Tokens.ui
                            font.pixelSize: Tokens.fRow
                            font.weight: Font.Bold
                        }
                    }

                    ColumnLayout {
                        spacing: 2

                        Text {
                            text: "dotarch"
                            color: Tokens.ink
                            font.family: Tokens.display
                            font.pixelSize: 19
                            font.weight: Font.DemiBold
                        }

                        Text {
                            text: "SETTINGS HUB"
                            color: Tokens.inkFaint
                            font.family: Tokens.ui
                            font.pixelSize: Tokens.fTiny
                            font.letterSpacing: Tokens.trackLabel
                        }
                    }
                }

                Item { Layout.preferredHeight: 32 }

                Repeater {
                    id: navRepeater
                    model: win.pages

                    delegate: ColumnLayout {
                        id: navItem
                        readonly property real rowY: navRow.y
                        required property var modelData
                        required property int index

                        readonly property bool selected: win.page === index
                        readonly property bool newGroup: index === 0
                            || win.pages[index - 1].group !== modelData.group

                        readonly property bool groupLive:
                            win.pages[win.page].group === modelData.group
                        readonly property int groupNo: {
                            var n = 1
                            for (var i = 1; i <= index; i++)
                                if (win.pages[i].group !== win.pages[i - 1].group) n++
                            return n
                        }

                        Layout.fillWidth: true
                        spacing: 0

                        Text {
                            visible: navItem.newGroup
                            Layout.leftMargin: 10
                            Layout.topMargin: navItem.index === 0 ? 0 : 21
                            Layout.bottomMargin: 9
                            text: String(navItem.groupNo).padStart(2, "0") + "  " + navItem.modelData.group
                            color: navItem.groupLive ? Tokens.inkDim : Tokens.inkFaint
                            font.family: Tokens.mono
                            font.pixelSize: Tokens.fTiny
                            font.weight: Font.DemiBold
                            font.letterSpacing: Tokens.trackLabel
                        }

                        Rectangle {
                            id: navRow
                            Layout.fillWidth: true
                            Layout.preferredHeight: 42
                            Layout.bottomMargin: 3
                            radius: Tokens.radius

                            color: navMouse.containsMouse && !navItem.selected ? Tokens.tint5 : "transparent"

                            Behavior on color {
                                ColorAnimation {
                                    duration: Tokens.flap
                                    easing.type: Tokens.easeSnap
                                }
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 11

                                Text {
                                    text: "//"
                                    color: navItem.selected ? Tokens.inkOnBoneDim : "transparent"
                                    font.family: Tokens.mono
                                    font.pixelSize: Tokens.fMicro
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: navItem.modelData.name
                                    color: navItem.selected ? Tokens.inkOnBone : Tokens.inkDim
                                    font.family: Tokens.ui
                                    font.pixelSize: Tokens.fSmall
                                    font.weight: navItem.selected ? Font.DemiBold : Font.Medium
                                }

                                Text {
                                    text: navItem.modelData.jp
                                    color: navItem.selected ? Tokens.inkOnBoneDim : Tokens.inkFaint
                                    font.family: Tokens.jp
                                    font.pixelSize: Tokens.fMicro
                                }
                            }

                            MouseArea {
                                id: navMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: win.page = navItem.index
                            }
                        }
                    }
                }

                Item { Layout.fillHeight: true }


            }
        }

        // MAIN WORKSPACE
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            // PAGE HEADER
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 42
                Layout.rightMargin: 36
                Layout.topMargin: 27
                Layout.bottomMargin: 23
                spacing: 16

                ColumnLayout {
                    spacing: 5

                    Text {
                        text: (win.activePage.jp || "") + "  " + (win.activePage.group || "HOME")
                        color: Tokens.inkFaint
                        font.family: Tokens.ui
                        font.pixelSize: Tokens.fTiny
                        font.weight: Font.DemiBold
                        font.letterSpacing: Tokens.trackLabel
                    }

                    Text {
                        text: win.activePage.name
                        color: Tokens.ink
                        font.family: Tokens.display
                        font.pixelSize: Tokens.fTitle
                        font.weight: Font.Medium
                    }

                    Text {
                        text: win.activePage.description
                        color: Tokens.inkMuted
                        font.family: Tokens.ui
                        font.pixelSize: Tokens.fSmall
                    }
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    Layout.preferredWidth: 34
                    Layout.preferredHeight: 34
                    radius: Tokens.radius
                    color: closeMouse.containsMouse ? Tokens.tint10 : "transparent"
                    border.width: 1
                    border.color: closeMouse.containsMouse
                        ? Tokens.line : "transparent"

                    Behavior on color {
                        ColorAnimation { duration: Tokens.snap; easing.type: Tokens.easeSnap }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "×"
                        color: Tokens.inkMuted
                        font.family: Tokens.ui
                        font.pixelSize: 21
                    }

                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: win.visible = false
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Tokens.lineSoft
            }

            // PAGE CONTENT
            Item {
                id: pageArea
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                ColumnLayout {
                    id: pageContent
                    anchors.fill: parent
                    anchors.leftMargin: 40
                    anchors.rightMargin: 40
                    anchors.topMargin: 30
                    anchors.bottomMargin: 26
                    spacing: 0

                    // OVERVIEW
                    Flickable {
                        id: overviewPage
                        visible: win.page === 0
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        contentWidth: width
                        contentHeight: overviewContent.implicitHeight
                        boundsBehavior: Flickable.StopAtBounds

                        ColumnLayout {
                            id: overviewContent
                            width: overviewPage.width
                            spacing: 36

                            // CURRENT APPEARANCE
                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: appearanceRow.implicitHeight + 52
                                color: "transparent"
                                border.width: 1
                                border.color: Tokens.line

                                RowLayout {
                                    id: appearanceRow
                                    anchors.fill: parent
                                    anchors.margins: 26
                                    spacing: 28

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 8

                                        Text {
                                            text: "// CURRENT THEME"
                                            color: Tokens.inkFaint
                                            font.family: Tokens.mono
                                            font.pixelSize: 10
                                            font.letterSpacing: 1.2
                                        }

                                        Text {
                                            text: Theme.name
                                            color: Tokens.ink
                                            font.family: Tokens.display
                                            font.pixelSize: 28
                                        }

                                        Text {
                                            text: "Active colour scheme"
                                            color: Tokens.inkMuted
                                            font.family: Tokens.ui
                                            font.pixelSize: 12
                                        }
                                    }

                                    ColumnLayout {
                                        Layout.alignment: Qt.AlignVCenter
                                        spacing: 16

                                        RowLayout {
                                            Layout.alignment: Qt.AlignRight
                                            spacing: 6

                                            Repeater {
                                                model: [
                                                    Theme.red, Theme.orange,
                                                    Theme.yellow, Theme.green,
                                                    Theme.aqua, Theme.blue,
                                                    Theme.purple
                                                ]

                                                delegate: Rectangle {
                                                    required property color modelData
                                                    width: 22
                                                    height: 22
                                                    radius: 3
                                                    color: modelData
                                                }
                                            }
                                        }

                                        Rectangle {
                                            Layout.alignment: Qt.AlignRight
                                            implicitWidth: exploreRow.implicitWidth + 32
                                            implicitHeight: 34
                                            color: exploreMouse.containsMouse ? Tokens.tint5 : "transparent"
                    Behavior on color { ColorAnimation { duration: Tokens.snap; easing.type: Tokens.easeSnap } }
                                            border.width: 1
                                            border.color: Tokens.line

                                            RowLayout {
                                                id: exploreRow
                                                anchors.centerIn: parent
                                                spacing: 10

                                                Text {
                                                    text: "Explore themes"
                                                    color: Tokens.ink
                                                    font.family: Tokens.ui
                                                    font.pixelSize: 12
                                                }

                                                Text {
                                                    text: "→"
                                                    color: Tokens.inkMuted
                                                    font.pixelSize: Tokens.fBody
                                                }
                                            }

                                            MouseArea {
                                                id: exploreMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: win.page = 1
                                            }
                                        }
                                    }
                                }
                            }

                            // SETTINGS DIRECTORY
                            Repeater {
                                model: [
                                    {
                                        title: "Look & feel",
                                        items: [
                                            { name: "Appearance", detail: "Themes, wallpapers and visual style", target: 1 },
                                            { name: "Animations", detail: "Motion, transitions and timing", target: 3 },
                                            { name: "Lock Screen", detail: "Lock screen and visual settings", target: 6 },
                                            { name: "Cursors & Fonts", detail: "Pointer themes and typography", target: 8 }
                                        ]
                                    },
                                    {
                                        title: "Desktop & devices",
                                        items: [
                                            { name: "Windows", detail: "Gaps, borders, blur and behaviour", target: 2 },
                                            { name: "Displays", detail: "Monitors, resolution and scaling", target: 4 },
                                            { name: "Input", detail: "Keyboard, touchpad and devices", target: 5 },
                                            { name: "Startup", detail: "Applications launched at login", target: 7 }
                                        ]
                                    }
                                ]

                                delegate: ColumnLayout {
                                    required property var modelData

                                    Layout.fillWidth: true
                                    spacing: 14

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 14

                                        Text {
                                            text: "// " + modelData.title.toUpperCase()
                                            color: Tokens.ink
                                            font.family: Tokens.mono
                                            font.pixelSize: Tokens.fMicro
                                            font.weight: Font.DemiBold
                                            font.letterSpacing: 1.2
                                        }

                                        Rectangle {
                                            Layout.fillWidth: true
                                            height: 1
                                            color: Tokens.lineSoft
                                        }

                                        Text {
                                            text: String(modelData.items.length).padStart(2, "0")
                                            color: Tokens.inkFaint
                                            font.family: Tokens.mono
                                            font.pixelSize: 10
                                        }
                                    }

                                    GridLayout {
                                        Layout.fillWidth: true
                                        columns: 2
                                        columnSpacing: 32
                                        rowSpacing: 0

                                        Repeater {
                                            model: modelData.items

                                            delegate: Rectangle {
                                                id: row
                                                required property var modelData

                                                Layout.fillWidth: true
                                                Layout.preferredHeight: 72
                                                color: rowMouse.containsMouse ? Tokens.tint5 : "transparent"
                    Behavior on color { ColorAnimation { duration: Tokens.snap; easing.type: Tokens.easeSnap } }

                                                Rectangle {
                                                    anchors.bottom: parent.bottom
                                                    width: parent.width
                                                    height: 1
                                                    color: Tokens.lineSoft
                                                }

                                                RowLayout {
                                                    anchors.fill: parent
                                                    anchors.leftMargin: 14
                                                    anchors.rightMargin: 14
                                                    spacing: 16

                                                    Text {
                                                        text: String(row.modelData.target).padStart(2, "0")
                                                        color: Tokens.inkFaint
                                                        font.family: Tokens.mono
                                                        font.pixelSize: Tokens.fMicro
                                                    }

                                                    ColumnLayout {
                                                        Layout.fillWidth: true
                                                        spacing: 5

                                                        Text {
                                                            text: row.modelData.name
                                                            color: Tokens.ink
                                                            font.family: Tokens.ui
                                                            font.pixelSize: Tokens.fRow
                                                            font.weight: Font.Medium
                                                        }

                                                        Text {
                                                            text: row.modelData.detail
                                                            color: Tokens.inkMuted
                                                            font.family: Tokens.ui
                                                            font.pixelSize: 12
                                                            elide: Text.ElideRight
                                                            Layout.fillWidth: true
                                                        }
                                                    }

                                                    Text {
                                                        text: "→"
                                                        color: rowMouse.containsMouse ? Tokens.ink : Tokens.inkFaint
                                                        Behavior on color { ColorAnimation { duration: Tokens.snap; easing.type: Tokens.easeSnap } }
                                                        font.pixelSize: Tokens.fRow
                                                        Layout.rightMargin: rowMouse.containsMouse ? 0 : 4
                                                        Behavior on Layout.rightMargin { NumberAnimation { duration: Tokens.snap; easing.type: Tokens.easeSnap } }
                                                    }
                                                }

                                                MouseArea {
                                                    id: rowMouse
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: win.page = row.modelData.target
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            Item { Layout.preferredHeight: 8 }
                        }
                    }

                    AppearanceSettingsPage {
                        visible: win.page === 1
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                    }

                    WindowsSettingsPage {
                        visible: win.page === 2
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                    }

                    AnimationsSettingsPage {
                        visible: win.page === 3
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                    }

                    DisplaysSettingsPage {
                        visible: win.page === 4
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                    }

                    InputSettingsPage {
                        visible: win.page === 5
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                    }

                    LockSettingsPage {
                        visible: win.page === 6
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                    }

                    StartupSettingsPage {
                        visible: win.page === 7
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                    }

                    CursorFontSettings {
                        visible: win.page === 8
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                    }
                }

                NumberAnimation {
                    id: pageFade
                    target: pageContent
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: Tokens.swap
                    easing.type: Tokens.ease
                }
            }

            // FOOTER
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Tokens.lineSoft
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 27
                Layout.rightMargin: 27
                Layout.topMargin: 9
                Layout.bottomMargin: 9
                spacing: 8

                Text {
                    text: "DOTARCH"
                    color: Tokens.inkFaint
                    font.family: Tokens.ui
                    font.pixelSize: 8
                    font.weight: Font.DemiBold
                    font.letterSpacing: 1.2
                }

                Text {
                    text: "·"
                    color: Tokens.inkFaint
                    font.pixelSize: 10
                }

                Text {
                    text: Theme.name
                    color: Tokens.inkMuted
                    font.family: Tokens.ui
                    font.pixelSize: Tokens.fTiny
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: (win.page + 1) + "  /  " + win.pages.length
                    color: Tokens.inkMuted
                    font.family: Tokens.ui
                    font.pixelSize: Tokens.fTiny
                }
            }
        }
    }
}