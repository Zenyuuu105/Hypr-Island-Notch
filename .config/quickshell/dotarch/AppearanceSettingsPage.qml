import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import "ui/Singletons"

Flickable {
    id: root

    Layout.fillWidth: true
    Layout.fillHeight: true
    clip: true
    contentWidth: width
    contentHeight: contentColumn.implicitHeight
    boundsBehavior: Flickable.StopAtBounds
    flickableDirection: Flickable.VerticalFlick

    property string themeSearch: ""
    property string wallpaperSearch: ""

    readonly property var activeTheme: {
        const found = AppearanceState.themes.find(item => item.slug === Theme.slug)
        return found || (AppearanceState.themes.length ? AppearanceState.themes[0] : null)
    }

    readonly property var filteredThemes: AppearanceState.themes.filter(
        item => item.name.toLowerCase().includes(themeSearch.toLowerCase())
    )

    readonly property var filteredWallpapers: AppearanceState.wallpapers.filter(
        item => item.name.toLowerCase().includes(wallpaperSearch.toLowerCase())
    )

    ColumnLayout {
        id: contentColumn
        width: root.width
        spacing: 23

        // CURRENT APPEARANCE
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 184
            radius: Tokens.radius
            color: root.activeTheme ? root.activeTheme.colors.bg0 : Tokens.paperLift
            border.width: 1
            border.color: root.activeTheme
                ? Qt.alpha(root.activeTheme.colors.foreground, 0.13)
                : Tokens.line
            clip: true

            RowLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 22

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 8

                    Text {
                        text: "// CURRENT THEME"
                        color: root.activeTheme
                            ? Qt.alpha(root.activeTheme.colors.foreground, 0.55)
                            : Tokens.inkMuted
                        font.family: Tokens.mono
                        font.pixelSize: Tokens.fTiny
                        font.weight: Font.DemiBold
                        font.letterSpacing: Tokens.trackLabel
                    }

                    Text {
                        text: root.activeTheme ? root.activeTheme.name : "Loading themes…"
                        color: root.activeTheme
                            ? root.activeTheme.colors.foreground
                            : Tokens.ink
                        font.family: Tokens.display
                        font.pixelSize: 25
                        font.weight: Font.Medium
                        elide: Text.ElideRight
                    }

                    Text {
                        text: root.activeTheme
                            ? root.activeTheme.appearance.toUpperCase() + " THEME  ·  DESKTOP COLOURS"
                            : "Your desktop colour scheme"
                        color: root.activeTheme
                            ? Qt.alpha(root.activeTheme.colors.foreground, 0.65)
                            : Tokens.inkMuted
                        font.family: Tokens.ui
                        font.pixelSize: Tokens.fTiny
                        font.letterSpacing: 0.6
                    }

                    Item { Layout.preferredHeight: 3 }

                    Row {
                        spacing: 6

                        Repeater {
                            model: root.activeTheme ? [
                                root.activeTheme.colors.red,
                                root.activeTheme.colors.orange,
                                root.activeTheme.colors.yellow,
                                root.activeTheme.colors.green,
                                root.activeTheme.colors.aqua,
                                root.activeTheme.colors.blue,
                                root.activeTheme.colors.purple
                            ] : []

                            delegate: Rectangle {
                                required property var modelData
                                width: 21
                                height: 21
                                radius: 5
                                color: modelData || "#888888"
                            }
                        }
                    }
                }

                // MINIATURE DESKTOP PREVIEW
                Rectangle {
                    Layout.preferredWidth: 245
                    Layout.preferredHeight: 137
                    Layout.alignment: Qt.AlignVCenter
                    radius: 7
                    color: root.activeTheme ? root.activeTheme.colors.bg_dim : Tokens.paper
                    border.width: 1
                    border.color: root.activeTheme
                        ? Qt.alpha(root.activeTheme.colors.foreground, 0.16)
                        : Tokens.line
                    clip: true

                    Column {
                        anchors.fill: parent
                        anchors.margins: 9
                        spacing: 7

                        Rectangle {
                            width: parent.width
                            height: 17
                            radius: 4
                            color: root.activeTheme ? root.activeTheme.colors.bg1 : Tokens.paperLift

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: 7
                                spacing: 4

                                Repeater {
                                    model: 3
                                    delegate: Rectangle {
                                        required property int index
                                        width: 5
                                        height: 5
                                        radius: 3
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: root.activeTheme
                                            ? [root.activeTheme.colors.red,
                                               root.activeTheme.colors.yellow,
                                               root.activeTheme.colors.green][index]
                                            : Tokens.ink
                                    }
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.right: parent.right
                                    anchors.rightMargin: 7
                                    text: "DESKTOP"
                                    color: root.activeTheme
                                        ? root.activeTheme.colors.muted
                                        : Tokens.inkMuted
                                    font.pixelSize: 6
                                    font.letterSpacing: 0.8
                                }
                            }
                        }

                        Row {
                            width: parent.width
                            height: 91
                            spacing: 7

                            Rectangle {
                                width: 39
                                height: parent.height
                                radius: 4
                                color: root.activeTheme ? root.activeTheme.colors.bg1 : Tokens.paperLift

                                Column {
                                    anchors.centerIn: parent
                                    spacing: 6

                                    Repeater {
                                        model: 4
                                        delegate: Rectangle {
                                            required property int index
                                            width: 19
                                            height: 4
                                            radius: 2
                                            color: root.activeTheme
                                                ? (index === 0
                                                    ? root.activeTheme.colors.primary
                                                    : root.activeTheme.colors.bg3)
                                                : Tokens.inkMuted
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                width: parent.width - 46
                                height: parent.height
                                radius: 4
                                color: root.activeTheme ? root.activeTheme.colors.bg1 : Tokens.paperLift

                                Column {
                                    anchors.fill: parent
                                    anchors.margins: 9
                                    spacing: 7

                                    Rectangle {
                                        width: parent.width * 0.58
                                        height: 7
                                        radius: 2
                                        color: root.activeTheme
                                            ? root.activeTheme.colors.foreground
                                            : Tokens.ink
                                        opacity: 0.8
                                    }

                                    Rectangle {
                                        width: parent.width * 0.82
                                        height: 4
                                        radius: 2
                                        color: root.activeTheme
                                            ? root.activeTheme.colors.muted
                                            : Tokens.inkMuted
                                    }

                                    Rectangle {
                                        width: parent.width * 0.68
                                        height: 4
                                        radius: 2
                                        color: root.activeTheme
                                            ? root.activeTheme.colors.muted
                                            : Tokens.inkMuted
                                        opacity: 0.65
                                    }

                                    Item { height: 2 }

                                    Rectangle {
                                        width: 48
                                        height: 13
                                        radius: 3
                                        color: root.activeTheme
                                            ? root.activeTheme.colors.primary
                                            : Tokens.ink
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // THEME BROWSER
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 13

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 3

                    Text {
                        text: "// EXPLORE THEMES"
                        color: Tokens.ink
                        font.family: Tokens.mono
                        font.pixelSize: Tokens.fMicro
                        font.weight: Font.DemiBold
                        font.letterSpacing: Tokens.trackLabel
                    }

                    Text {
                        text: "Choose a palette to change the look of your desktop"
                        color: Tokens.inkMuted
                        font.family: Tokens.ui
                        font.pixelSize: Tokens.fMicro
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 190
                    Layout.preferredHeight: 34
                    radius: Tokens.radius
                    color: Tokens.paperLift
                    border.width: 1
                    border.color: Tokens.line

                    TextInput {
                        id: themeInput
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 8
                        verticalAlignment: TextInput.AlignVCenter
                        color: Tokens.ink
                        font.family: Tokens.ui
                        font.pixelSize: Tokens.fMicro
                        clip: true
                        onTextChanged: root.themeSearch = text

                        Text {
                            anchors.fill: parent
                            verticalAlignment: Text.AlignVCenter
                            text: "Find a theme..."
                            color: Tokens.inkMuted
                            font.family: Tokens.ui
                            font.pixelSize: Tokens.fMicro
                            visible: !themeInput.text
                        }
                    }
                }
            }

            GridView {
                id: themeGrid
                Layout.fillWidth: true
                Layout.preferredHeight: Math.max(
                    110,
                    Math.ceil(count / Math.max(1, Math.floor(width / 190))) * 137
                )
                cellWidth: width / Math.max(1, Math.floor(width / 190))
                cellHeight: 137
                clip: true
                interactive: false
                model: root.filteredThemes

                delegate: Rectangle {
                    id: themeCard
                    required property var modelData

                    HoverHandler { id: themeHover }

                    width: themeGrid.cellWidth - 9
                    height: 126
                    radius: 6
                    color: modelData.colors.bg0
                    border.width: modelData.slug === Theme.slug ? 2 : 1
                    border.color: modelData.slug === Theme.slug
                        ? modelData.colors.primary
                        : Qt.alpha(modelData.colors.foreground, themeHover.hovered ? 0.4 : 0.13)
                    Behavior on border.color { ColorAnimation { duration: Tokens.snap; easing.type: Tokens.easeSnap } }

                    Column {
                        anchors.fill: parent
                        anchors.margins: 11
                        spacing: 9

                        Row {
                            width: parent.width
                            height: 25
                            spacing: 4

                            Repeater {
                                model: [
                                    themeCard.modelData.colors.bg1,
                                    themeCard.modelData.colors.bg2,
                                    themeCard.modelData.colors.primary,
                                    themeCard.modelData.colors.green,
                                    themeCard.modelData.colors.blue,
                                    themeCard.modelData.colors.purple
                                ]

                                delegate: Rectangle {
                                    required property var modelData
                                    width: (themeCard.width - 42) / 6
                                    height: 23
                                    radius: 3
                                    color: modelData || "#888888"
                                }
                            }
                        }

                        Text {
                            width: parent.width
                            text: themeCard.modelData.name
                            color: themeCard.modelData.colors.foreground
                            font.family: Tokens.ui
                            font.pixelSize: Tokens.fSmall
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }

                        Row {
                            width: parent.width
                            spacing: 5

                            Rectangle {
                                width: 6
                                height: 6
                                radius: 3
                                anchors.verticalCenter: parent.verticalCenter
                                color: themeCard.modelData.colors.primary
                            }

                            Text {
                                text: themeCard.modelData.slug === Theme.slug
                                    ? "Currently applied"
                                    : themeCard.modelData.appearance + " appearance"
                                color: Qt.alpha(themeCard.modelData.colors.foreground, 0.7)
                                font.family: Tokens.ui
                                font.pixelSize: Tokens.fTiny
                            }

                            Item { width: 1; height: 1 }

                            Text {
                                visible: themeCard.modelData.slug === Theme.slug
                                text: "✓"
                                color: themeCard.modelData.colors.primary
                                font.family: Tokens.ui
                                font.pixelSize: Tokens.fMicro
                                font.weight: Font.Bold
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: !AppearanceState.busy
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (themeCard.modelData.slug !== Theme.slug)
                                AppearanceState.applyTheme(themeCard.modelData.slug)
                        }
                    }
                }
            }

            Text {
                visible: root.filteredThemes.length === 0
                text: "No themes match your search."
                color: Tokens.inkMuted
                font.family: Tokens.ui
                font.pixelSize: Tokens.fMicro
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Tokens.lineSoft
        }

        // WALLPAPER GALLERY
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 13

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 3

                    Text {
                        text: "// WALLPAPERS"
                        color: Tokens.ink
                        font.family: Tokens.mono
                        font.pixelSize: Tokens.fMicro
                        font.weight: Font.DemiBold
                        font.letterSpacing: Tokens.trackLabel
                    }

                    Text {
                        text: "Set the atmosphere of your desktop"
                        color: Tokens.inkMuted
                        font.family: Tokens.ui
                        font.pixelSize: Tokens.fMicro
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 190
                    Layout.preferredHeight: 34
                    radius: Tokens.radius
                    color: Tokens.paperLift
                    border.width: 1
                    border.color: Tokens.line

                    TextInput {
                        id: wallpaperInput
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 8
                        verticalAlignment: TextInput.AlignVCenter
                        color: Tokens.ink
                        font.family: Tokens.ui
                        font.pixelSize: Tokens.fMicro
                        clip: true
                        onTextChanged: root.wallpaperSearch = text

                        Text {
                            anchors.fill: parent
                            verticalAlignment: Text.AlignVCenter
                            text: "Find a wallpaper..."
                            color: Tokens.inkMuted
                            font.family: Tokens.ui
                            font.pixelSize: Tokens.fMicro
                            visible: !wallpaperInput.text
                        }
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 34
                    Layout.preferredHeight: 34
                    radius: Tokens.radius
                    color: Tokens.paperLift
                    border.width: 1
                    border.color: Tokens.line

                    Text {
                        anchors.centerIn: parent
                        text: "↗"
                        color: Tokens.ink
                        font.family: Tokens.ui
                        font.pixelSize: Tokens.fBody
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: AppearanceState.openWallpaperFolder()
                    }
                }
            }

            GridView {
                id: wallpaperGrid
                Layout.fillWidth: true
                Layout.preferredHeight: Math.max(
                    120,
                    Math.ceil(count / Math.max(1, Math.floor(width / 190))) * 151
                )
                cellWidth: width / Math.max(1, Math.floor(width / 190))
                cellHeight: 151
                clip: true
                interactive: false
                model: root.filteredWallpapers

                delegate: Item {
                    id: wallpaperCard
                    required property var modelData

                    HoverHandler { id: wpHover }

                    width: wallpaperGrid.cellWidth - 9
                    height: 141

                    readonly property bool isCurrent:
                        modelData.path === AppearanceState.currentWallpaper

                    Rectangle {
                        anchors.fill: parent
                        radius: 6
                        color: Tokens.paperLift
                        border.width: wallpaperCard.isCurrent ? 2 : 1
                        border.color: wallpaperCard.isCurrent
                            ? Tokens.ink
                            : wpHover.hovered ? Tokens.lineStrong : Tokens.line
                        Behavior on border.color { ColorAnimation { duration: Tokens.snap; easing.type: Tokens.easeSnap } }
                        clip: true

                        Image {
                            anchors.fill: parent
                            anchors.margins: 2
                            source: encodeURI("file://" + wallpaperCard.modelData.path)
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: true
                            sourceSize.width: 420
                            sourceSize.height: 260
                            opacity: status === Image.Ready ? 1 : 0.65
                        }

                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: 34
                            color: Qt.alpha(Tokens.paper, 0.85)
                        }

                        Text {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.leftMargin: 9
                            anchors.rightMargin: 8
                            anchors.bottomMargin: 10
                            text: wallpaperCard.modelData.name
                            color: Tokens.ink
                            font.family: Tokens.ui
                            font.pixelSize: Tokens.fTiny
                            elide: Text.ElideRight
                        }

                        Rectangle {
                            visible: wallpaperCard.isCurrent
                            anchors.top: parent.top
                            anchors.right: parent.right
                            anchors.margins: 7
                            width: 21
                            height: 21
                            radius: 5
                            color: Tokens.bone

                            Text {
                                anchors.centerIn: parent
                                text: "✓"
                                color: Tokens.inkOnBone
                                font.family: Tokens.ui
                                font.pixelSize: Tokens.fSmall
                                font.weight: Font.Bold
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: !AppearanceState.busy
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (!wallpaperCard.isCurrent)
                                AppearanceState.setWallpaper(wallpaperCard.modelData.path)
                        }
                    }
                }
            }

            Text {
                visible: root.filteredWallpapers.length === 0
                text: "No wallpapers match your search."
                color: Tokens.inkMuted
                font.family: Tokens.ui
                font.pixelSize: Tokens.fMicro
            }
        }

        // STATUS
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Tokens.lineSoft
            }

            Text {
                Layout.fillWidth: true
                visible: AppearanceState.error !== ""
                text: AppearanceState.error
                color: Tokens.alert
                font.family: Tokens.ui
                font.pixelSize: Tokens.fMicro
                wrapMode: Text.WordWrap
            }

            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: AppearanceState.busy
                        ? "Applying changes…"
                        : "Changes apply to your desktop immediately"
                    color: Tokens.inkMuted
                    font.family: Tokens.ui
                    font.pixelSize: Tokens.fTiny
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: AppearanceState.themes.length + " themes  ·  " +
                          AppearanceState.wallpapers.length + " wallpapers"
                    color: Tokens.inkMuted
                    font.family: Tokens.ui
                    font.pixelSize: Tokens.fTiny
                }
            }
        }
    }

    Component.onCompleted: {
        AppearanceState.refreshThemes()
        AppearanceState.refreshWallpapers()
        AppearanceState.refreshCurrentWallpaper()
    }
}
