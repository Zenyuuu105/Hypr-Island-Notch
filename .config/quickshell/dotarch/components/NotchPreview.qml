import QtQuick
import QtQuick.Shapes

Rectangle {
    id: root

    property var cfg
    property color accent: "#0a84ff"
    property color shellBg: "#000000"
    property color fg: "#ffffff"
    property color muted: "#9a9a9a"
    property string iconFont: ""
    // used when a size is set to "Auto" (the real value comes from ShellState.targetWidth)
    property int autoRestWidth: 200
    property int autoHoverWidth: 480
    property bool expanded: false
    property date now: new Date()

    readonly property real k: 0.62
    readonly property bool attached: cfg.shape === "notch"
    readonly property int wing: attached ? cfg.notchFlare : 0
    readonly property int islandMargin: attached ? 0 : cfg.islandTopMargin
    readonly property real baseW: expanded
        ? (cfg.expandedWidth > 0 ? cfg.expandedWidth : autoHoverWidth)
        : (cfg.collapsedWidth > 0 ? cfg.collapsedWidth : autoRestWidth)
    readonly property real bodyH: expanded ? cfg.expandedHeight : cfg.collapsedHeight
    readonly property string clockFormat: cfg.clock24h
        ? (cfg.showSeconds ? "HH:mm:ss" : "HH:mm")
        : (cfg.showSeconds ? "h:mm:ss AP" : "h:mm AP")

    radius: 12
    clip: true
    implicitHeight: 190
    gradient: Gradient {
        GradientStop { position: 0.0; color: "#4b3a69" }
        GradientStop { position: 1.0; color: "#1d3447" }
    }

    Timer { interval: 1000; repeat: true; running: root.visible; onTriggered: root.now = new Date() }

    // everything inside the stage is drawn at real size, then scaled down
    Item {
        id: stage
        width: root.width / root.k
        height: root.height / root.k
        scale: root.k
        transformOrigin: Item.TopLeft

        Item {
            id: surface
            anchors.horizontalCenter: parent.horizontalCenter
            y: root.islandMargin
            width: root.baseW + root.wing * 2
            height: root.bodyH

            Behavior on width {
                enabled: root.cfg.animationsEnabled
                NumberAnimation { duration: root.cfg.animationDuration; easing.type: Easing.OutBack; easing.overshoot: root.expanded ? 1.6 : 0 }
            }
            Behavior on height {
                enabled: root.cfg.animationsEnabled
                NumberAnimation { duration: root.cfg.animationDuration; easing.type: Easing.OutBack; easing.overshoot: root.expanded ? 1.6 : 0 }
            }

            Rectangle {
                id: body
                x: root.wing
                y: 0
                width: parent.width - root.wing * 2
                height: parent.height
                readonly property real r: Math.min(root.cfg.cornerRadius, height / 2)
                topLeftRadius: root.attached ? 0 : r
                topRightRadius: root.attached ? 0 : r
                bottomLeftRadius: r
                bottomRightRadius: r
                color: root.shellBg
            }

            Shape {
                visible: root.attached
                x: 0
                width: root.wing
                height: root.wing
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    id: lp
                    readonly property real size: root.wing
                    strokeWidth: 0
                    fillColor: root.shellBg
                    startX: 0; startY: 0
                    PathLine { x: lp.size; y: 0 }
                    PathLine { x: lp.size; y: lp.size }
                    PathCubic {
                        control1X: lp.size; control1Y: lp.size * 0.448
                        control2X: lp.size * 0.552; control2Y: 0
                        x: 0; y: 0
                    }
                }
            }

            Shape {
                visible: root.attached
                x: parent.width - width
                width: root.wing
                height: root.wing
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    id: rp
                    readonly property real size: root.wing
                    strokeWidth: 0
                    fillColor: root.shellBg
                    startX: rp.size; startY: 0
                    PathLine { x: 0; y: 0 }
                    PathLine { x: 0; y: rp.size }
                    PathCubic {
                        control1X: 0; control1Y: rp.size * 0.448
                        control2X: rp.size * 0.448; control2Y: 0
                        x: rp.size; y: 0
                    }
                }
            }

            // ---------------- resting pill ----------------
            Item {
                id: compact
                anchors.left: body.left
                anchors.right: body.right
                anchors.top: parent.top
                anchors.leftMargin: 26
                anchors.rightMargin: 26
                height: root.cfg.collapsedHeight
                opacity: root.expanded ? 0 : 1
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 90 } }

                WorkspaceDots {
                    visible: root.cfg.showWorkspaces
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                }

                RollingClock {
                    id: restClock
                    visible: root.cfg.showClock
                    anchors.centerIn: parent
                    timeText: Qt.formatDateTime(root.now, root.clockFormat)
                    textColor: root.fg
                    textSize: 16
                }

                Row {
                    anchors.left: restClock.right
                    anchors.leftMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6
                    ShellText {
                        visible: root.cfg.showDate
                        anchors.verticalCenter: parent.verticalCenter
                        text: Qt.formatDate(root.now, "MMM d")
                        color: root.muted
                        font.pixelSize: 12
                    }
                    ShellText {
                        visible: root.cfg.showMedia
                        anchors.verticalCenter: parent.verticalCenter
                        text: "\uDB81\uDF5A"
                        font.family: root.iconFont
                        color: root.muted
                        font.pixelSize: 14
                    }
                    ShellText {
                        visible: root.cfg.showVolume
                        anchors.verticalCenter: parent.verticalCenter
                        text: "\uDB81\uDD7E"
                        font.family: root.iconFont
                        color: root.muted
                        font.pixelSize: 14
                    }
                    ShellText {
                        visible: root.cfg.showBluetooth
                        anchors.verticalCenter: parent.verticalCenter
                        text: "\uDB80\uDCAF"
                        font.family: root.iconFont
                        color: root.muted
                        font.pixelSize: 14
                    }
                    NotchBell {
                        visible: root.cfg.showBell
                        anchors.verticalCenter: parent.verticalCenter
                        tint: root.muted
                    }
                }

                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 5
                    WifiGlyph {
                        visible: root.cfg.showWifi
                        anchors.verticalCenter: parent.verticalCenter
                        connected: true
                        level: 0.8
                    }
                    BatteryGlyph {
                        visible: root.cfg.showBattery
                        anchors.verticalCenter: parent.verticalCenter
                        level: 87
                        charging: false
                    }
                }
            }

            // ---------------- hover view ----------------
            Item {
                id: hover
                anchors.left: body.left
                anchors.right: body.right
                anchors.top: parent.top
                anchors.leftMargin: 26
                anchors.rightMargin: 26
                height: root.cfg.expandedHeight
                opacity: root.expanded ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 90 } }

                Row {
                    id: clockGroup
                    anchors.top: parent.top
                    anchors.topMargin: 6
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 8
                    ShellText {
                        id: hoverTime
                        visible: root.cfg.showHoverClock
                        anchors.bottom: parent.bottom
                        text: Qt.formatDateTime(root.now, root.clockFormat)
                        color: root.fg
                        font.pixelSize: 17
                        font.weight: Font.Bold
                    }
                    ShellText {
                        visible: root.cfg.showHoverDate
                        anchors.verticalCenter: hoverTime.verticalCenter
                        text: Qt.formatDate(root.now, "ddd, MMM d")
                        color: root.muted
                        font.pixelSize: 11
                    }
                }

                Item {
                    id: columns
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.topMargin: 32
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 8

                    Column {
                        id: leftGroup
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 5
                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 6
                            Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 6; height: 2; radius: 1; color: root.muted }
                            ShellText {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Desktop"
                                color: root.fg
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                            }
                        }
                        WorkspaceDots {
                            anchors.horizontalCenter: parent.horizontalCenter
                            visible: root.cfg.showHoverWorkspaces
                        }
                    }

                    Rectangle {
                        visible: root.cfg.showHoverMedia
                        anchors.centerIn: parent
                        width: Math.max(150, parent.width - 2 * (Math.max(leftGroup.implicitWidth, rightGroup.implicitWidth) + 14))
                        height: 40
                        radius: 16
                        color: Qt.rgba(1, 1, 1, 0.04)
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.08)
                        ShellText {
                            anchors.centerIn: parent
                            text: "Not playing"
                            color: root.muted
                            font.pixelSize: 12
                        }
                    }

                    Column {
                        id: rightGroup
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6
                        Row {
                            anchors.right: parent.right
                            spacing: 6
                            ShellText {
                                visible: root.cfg.showHoverStatus
                                anchors.verticalCenter: parent.verticalCenter
                                text: "All caught up"
                                color: root.fg
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                            }
                            NotchBell {
                                visible: root.cfg.showHoverStatus
                                anchors.verticalCenter: parent.verticalCenter
                                tint: root.muted
                            }
                        }
                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 5
                            WifiGlyph {
                                visible: root.cfg.showHoverStatus
                                anchors.verticalCenter: parent.verticalCenter
                                connected: true
                                level: 0.8
                            }
                            BatteryGlyph {
                                visible: root.cfg.showHoverStatus
                                anchors.verticalCenter: parent.verticalCenter
                                level: 87
                                charging: false
                            }
                        }
                    }
                }
            }
        }
    }

    Text {
        text: "Live preview"
        color: "#99ffffff"
        font.pixelSize: 11
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: 12
    }

    Row {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 10
        spacing: 4
        Repeater {
            model: [{ e: false, t: "Resting" }, { e: true, t: "Hover" }]
            delegate: Rectangle {
                required property var modelData
                width: 64; height: 24; radius: 12
                color: root.expanded === modelData.e ? root.accent : "#33ffffff"
                Text { anchors.centerIn: parent; text: modelData.t; color: "white"; font.pixelSize: 11 }
                MouseArea { anchors.fill: parent; onClicked: root.expanded = modelData.e }
            }
        }
    }
}
