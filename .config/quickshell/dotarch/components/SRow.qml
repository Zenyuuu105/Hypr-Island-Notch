import ".."
import QtQuick
import QtQuick.Controls

Item {
    id: root

    property string type: "toggle"   // toggle | slider | stepper | choice | swatch | button
    property string label: ""
    property string hint: ""
    property var value: null
    property real from: 0
    property real to: 100
    property real step: 1
    property string unit: ""
    property string zeroLabel: ""
    property var options: []
    property var swatches: []
    property string buttonText: ""
    property bool danger: false
    property bool divider: false
    property color accent: Theme.primary

    signal edited(var v)
    signal activated()

    readonly property color textColor: Theme.foreground
    readonly property color dimColor: Theme.muted
    readonly property color lineColor: Theme.cardBorder
    readonly property color trackColor: Theme.bg3

    readonly property real ctrlW: {
        switch (type) {
        case "toggle": return 40
        case "slider": return 290
        case "stepper": return 120
        case "choice": return seg.width
        case "font": return 246
        case "swatch": return swatchRow.width
        case "button": return btn.width
        default: return 160
        }
    }

    implicitWidth: 520
    implicitHeight: hint !== "" ? 56 : 46

    Rectangle {
        visible: root.divider
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 16
        height: 1
        color: root.lineColor
    }

    Column {
        anchors.left: parent.left
        anchors.leftMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        width: Math.max(80, root.width - root.ctrlW - 48)
        spacing: 2
        Text { width: parent.width; text: root.label; color: root.textColor; font.pixelSize: 13; elide: Text.ElideRight }
        Text { visible: root.hint !== ""; width: parent.width; text: root.hint; color: root.dimColor; font.pixelSize: 11; elide: Text.ElideRight }
    }

    // ---- toggle ----
    Rectangle {
        visible: root.type === "toggle"
        width: 40; height: 24; radius: 12
        anchors.right: parent.right
        anchors.rightMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        color: root.value ? root.accent : root.trackColor
        Behavior on color { ColorAnimation { duration: 120 } }
        Rectangle {
            width: 20; height: 20; radius: 10; y: 2
            x: root.value ? 18 : 2
            color: "white"
            Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
        }
        MouseArea { anchors.fill: parent; onClicked: root.edited(!root.value) }
    }

    // ---- slider ----
    Item {
        id: sl
        visible: root.type === "slider"
        width: 290; height: 28
        anchors.right: parent.right
        anchors.rightMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        readonly property real frac: root.to > root.from
            ? Math.max(0, Math.min(1, (Number(root.value) - root.from) / (root.to - root.from))) : 0

        Text {
            id: valText
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: 64
            horizontalAlignment: Text.AlignRight
            color: root.dimColor
            font.pixelSize: 12
            text: (root.zeroLabel !== "" && Number(root.value) === 0)
                ? root.zeroLabel
                : (Math.round(Number(root.value)) + (root.unit !== "" ? " " + root.unit : ""))
        }

        Rectangle {
            id: track
            anchors.left: parent.left
            anchors.right: valText.left
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            height: 4; radius: 2
            color: root.trackColor
            Rectangle { width: parent.width * sl.frac; height: parent.height; radius: 2; color: root.accent }
            Rectangle {
                width: 16; height: 16; radius: 8
                color: "white"
                border.width: 1
                border.color: "#40000000"
                anchors.verticalCenter: parent.verticalCenter
                x: (track.width - width) * sl.frac
            }
        }

        MouseArea {
            anchors.fill: track
            anchors.topMargin: -12
            anchors.bottomMargin: -12
            anchors.leftMargin: -8
            anchors.rightMargin: -8
            preventStealing: true
            function pick(mouse) {
                const x = mapToItem(track, mouse.x, mouse.y).x
                const f = Math.max(0, Math.min(1, x / track.width))
                let v = root.from + f * (root.to - root.from)
                v = Math.round(v / root.step) * root.step
                root.edited(Math.round(Math.max(root.from, Math.min(root.to, v))))
            }
            onPressed: mouse => pick(mouse)
            onPositionChanged: mouse => { if (pressed) pick(mouse) }
        }
    }

    // ---- stepper ----
    Row {
        visible: root.type === "stepper"
        anchors.right: parent.right
        anchors.rightMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6
        Rectangle {
            width: 28; height: 26; radius: 7; color: Qt.rgba(1, 1, 1, 0.07)
            Text { anchors.centerIn: parent; text: "−"; color: root.textColor; font.pixelSize: 15 }
            MouseArea { anchors.fill: parent; onClicked: root.edited(Math.max(root.from, Number(root.value) - root.step)) }
        }
        Text {
            width: 40; height: 26
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: Math.round(Number(root.value)) + (root.unit !== "" ? " " + root.unit : "")
            color: root.textColor; font.pixelSize: 13
        }
        Rectangle {
            width: 28; height: 26; radius: 7; color: Qt.rgba(1, 1, 1, 0.07)
            Text { anchors.centerIn: parent; text: "+"; color: root.textColor; font.pixelSize: 15 }
            MouseArea { anchors.fill: parent; onClicked: root.edited(Math.min(root.to, Number(root.value) + root.step)) }
        }
    }

    // ---- segmented choice ----
    Rectangle {
        id: seg
        visible: root.type === "choice"
        height: 28; radius: 8
        width: segRow.width + 4
        color: Theme.bg2
        anchors.right: parent.right
        anchors.rightMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        Row {
            id: segRow
            x: 2; y: 2
            spacing: 0
            Repeater {
                model: root.options
                delegate: Rectangle {
                    required property var modelData
                    height: 24; radius: 6
                    width: segLabel.implicitWidth + 24
                    color: root.value === modelData.key ? root.accent : "transparent"
                    Text {
                        id: segLabel
                        anchors.centerIn: parent
                        text: modelData.text
                        color: "white"
                        font.pixelSize: 12
                    }
                    MouseArea { anchors.fill: parent; onClicked: root.edited(modelData.key) }
                }
            }
        }
    }

    // ---- colour swatches ----
    Row {
        id: swatchRow
        visible: root.type === "swatch"
        spacing: 8
        anchors.right: parent.right
        anchors.rightMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        Repeater {
            model: root.swatches
            delegate: Rectangle {
                required property var modelData
                width: 22; height: 22; radius: 11
                color: modelData
                border.width: root.value === modelData ? 2 : 0
                border.color: "white"
                MouseArea { anchors.fill: parent; onClicked: root.edited(modelData) }
            }
        }
    }


    // ---- stable searchable font dropdown ----
    ComboBox {
        id: fontCombo

        visible: root.type === "font"
        width: 230
        height: 34

        anchors.right: parent.right
        anchors.rightMargin: 16
        anchors.verticalCenter: parent.verticalCenter

        model: root.options
        currentIndex: Math.max(0, root.options.indexOf(root.value))
        displayText: root.value || "Select font"

        contentItem: Text {
            text: fontCombo.displayText
            color: root.textColor
            font.family: Theme.fontFamily
            font.pixelSize: 12
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            leftPadding: 10
            rightPadding: 26
        }

        background: Rectangle {
            radius: 7
            color: Theme.bg2
            border.width: 1
            border.color: fontCombo.activeFocus
                ? Theme.primary
                : Theme.cardBorder
        }

        delegate: ItemDelegate {
            width: fontCombo.width
            highlighted: fontCombo.highlightedIndex === index

            contentItem: Text {
                text: modelData
                color: Theme.foreground
                font.family: Theme.fontFamily
                font.pixelSize: 12
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
            }

            background: Rectangle {
                radius: 5
                color: parent.highlighted
                    ? Qt.rgba(
                        Theme.primary.r,
                        Theme.primary.g,
                        Theme.primary.b,
                        0.2
                    )
                    : "transparent"
            }

            onClicked: {
                root.edited(modelData)
                fontCombo.popup.close()
            }
        }

        popup: Popup {
            id: fontPopup

            y: fontCombo.height + 4
            width: fontCombo.width
            padding: 6

            implicitHeight: Math.min(
                fontSearch.height + fontListArea.height + 12,
                250
            )

            onOpened: {
                fontSearch.text = ""
                fontSearch.forceActiveFocus()
            }

            contentItem: Column {
                spacing: 6

                TextField {
                    id: fontSearch

                    width: parent.width
                    height: 34

                    placeholderText: "Search installed fonts..."
                    placeholderTextColor: Theme.muted
                    color: Theme.foreground
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    selectByMouse: true

                    background: Rectangle {
                        radius: 6
                        color: Theme.bg2
                        border.width: 1
                        border.color: fontSearch.activeFocus
                            ? Theme.primary
                            : Theme.cardBorder
                    }
                }

                Item {
                    id: fontListArea

                    width: parent.width
                    height: Math.min(
                        Math.max(fontList.contentHeight, 42),
                        190
                    )

                    ListView {
                        id: fontList

                        anchors.fill: parent
                        clip: true
                        spacing: 2

                        model: {
                            const query = fontSearch.text
                                .trim()
                                .toLowerCase()

                            if (query.length === 0)
                                return root.options

                            return root.options.filter(function(name) {
                                return String(name)
                                    .toLowerCase()
                                    .indexOf(query) !== -1
                            })
                        }

                        delegate: ItemDelegate {
                            required property var modelData

                            width: fontList.width
                            height: 32

                            contentItem: Text {
                                text: modelData
                                color: Theme.foreground
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                                elide: Text.ElideRight
                                verticalAlignment: Text.AlignVCenter
                            }

                            background: Rectangle {
                                radius: 5
                                color: parent.highlighted
                                    ? Qt.rgba(
                                        Theme.primary.r,
                                        Theme.primary.g,
                                        Theme.primary.b,
                                        0.2
                                    )
                                    : "transparent"
                            }

                            onClicked: {
                                root.edited(modelData)
                                fontCombo.popup.close()
                            }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: fontList.count === 0
                        text: "No matching fonts"
                        color: Theme.muted
                        font.pixelSize: 12
                    }
                }
            }

            background: Rectangle {
                color: Theme.bg1
                radius: 9
                border.width: 1
                border.color: Theme.cardBorder
            }
        }
    }

    // ---- button ----
    Rectangle {
        id: btn
        visible: root.type === "button"
        height: 28; radius: 7
        width: btnText.implicitWidth + 28
        color: root.danger ? Qt.rgba(Theme.red.r, Theme.red.g, Theme.red.b, 0.2) : Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.16)
        anchors.right: parent.right
        anchors.rightMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        Text {
            id: btnText
            anchors.centerIn: parent
            text: root.buttonText
            color: root.danger ? Theme.red : root.accent
            font.pixelSize: 12
        }
        MouseArea { anchors.fill: parent; onClicked: root.activated() }
    }
}
