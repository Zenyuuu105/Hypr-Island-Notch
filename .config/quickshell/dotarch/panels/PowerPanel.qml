import QtQuick
import QtQuick.Shapes
import Quickshell.Io
import qs
import qs.components

// Island-style power menu: uptime caption, five round buttons, label of the
// selected one underneath. Reboot / Power off are hold-to-confirm (red ring).
// Icons are drawn as vector strokes (no font glyphs) and the selected button
// grows by real size, not by scale, so nothing is ever bitmap-stretched.
FocusScope {
    id: root

    property real ui: 1.0
    property int holdMs: 900
    property int current: 2          // starts on Lock
    property string uptimeText: ""

    readonly property real btn: 44 * ui
    readonly property real grow: 1.14
    readonly property real slot: btn * grow
    readonly property real gap: 12 * ui
    readonly property real stroke: 1.7 * ui

    readonly property var actions: [{
        "key": "suspend",
        "title": "Sleep",
        "hold": false,
        "hint": "",
        "path": "M12 3a6 6 0 0 0 9 9 9 9 0 1 1-9-9Z"
    }, {
        "key": "logout",
        "title": "Log out",
        "hold": false,
        "hint": "",
        "path": "M10 4H6.5A2.5 2.5 0 0 0 4 6.5v11A2.5 2.5 0 0 0 6.5 20H10 M15 8l4 4-4 4 M19 12H9.5"
    }, {
        "key": "lock",
        "title": "Lock",
        "hold": false,
        "hint": "",
        "path": "M6.5 11h11A1.5 1.5 0 0 1 19 12.5v6a1.5 1.5 0 0 1-1.5 1.5h-11A1.5 1.5 0 0 1 5 18.5v-6A1.5 1.5 0 0 1 6.5 11Z M8 11V8a4 4 0 0 1 8 0v3"
    }, {
        "key": "reboot",
        "title": "Reboot",
        "hold": true,
        "hint": "Keep holding to reboot",
        "path": "M19.5 12a7.5 7.5 0 1 1-2.2-5.3 M19.5 4.5v4h-4"
    }, {
        "key": "shutdown",
        "title": "Power off",
        "hold": true,
        "hint": "Keep holding to power off",
        "path": "M12 3.5v8 M16.9 6.7a7.5 7.5 0 1 1-9.8 0"
    }]

    readonly property var currentItem: actionRepeater.itemAt(current)

    function activate(action) {
        Backend.power(action);
        ShellState.close();
    }

    function takeInitialFocus() {
        current = 2;
        refreshUptime();
        forceActiveFocus(Qt.TabFocusReason);
    }

    function refreshUptime() {
        uptimeProc.running = true;
    }

    implicitWidth: 352
    implicitHeight: caption.height + 10 * ui + slot + 6 * ui + label.height
    focus: true
    onVisibleChanged: {
        if (visible) {
            current = 2;
            refreshUptime();
        }
    }
    Keys.onLeftPressed: current = (current + actions.length - 1) % actions.length
    Keys.onUpPressed: current = (current + actions.length - 1) % actions.length
    Keys.onRightPressed: current = (current + 1) % actions.length
    Keys.onDownPressed: current = (current + 1) % actions.length
    Keys.onEscapePressed: ShellState.close()
    Keys.onPressed: (event) => {
        const confirm = event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space;
        if (!confirm || event.isAutoRepeat)
            return ;

        event.accepted = true;
        if (actions[current].hold) {
            if (currentItem)
                currentItem.startHold();
        } else {
            activate(actions[current].key);
        }
    }
    Keys.onReleased: (event) => {
        const confirm = event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space;
        if (!confirm || event.isAutoRepeat)
            return ;

        event.accepted = true;
        if (currentItem)
            currentItem.cancelHold();
    }

    Process {
        id: uptimeProc

        command: ["cat", "/proc/uptime"]

        stdout: StdioCollector {
            onStreamFinished: {
                const secs = parseInt(text.split(" ")[0]);
                const d = Math.floor(secs / 86400);
                const h = Math.floor((secs % 86400) / 3600);
                const m = Math.floor((secs % 3600) / 60);
                let s = "Up ";
                if (d > 0)
                    s += d + " d ";

                if (d > 0 || h > 0)
                    s += h + " h ";

                s += m + " min";
                root.uptimeText = s;
            }
        }
    }

    ShellText {
        id: caption

        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        text: root.uptimeText
        color: Theme.muted
        opacity: 0.7
        font.pixelSize: 11 * root.ui
    }

    Row {
        id: row

        anchors.top: caption.bottom
        anchors.topMargin: 10 * root.ui
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: root.gap

        Repeater {
            id: actionRepeater

            model: root.actions

            delegate: Item {
                id: button

                required property int index
                required property var modelData
                readonly property bool selected: root.current === index
                readonly property bool destructive: modelData.hold
                property real discSize: selected ? root.slot : root.btn
                readonly property color iconColor: selected ? (destructive ? Theme.red : Theme.bgDim) : Theme.foreground
                property real progress: 0
                property bool holding: false

                function startHold() {
                    holding = true;
                    fillAnim.from = progress;
                    fillAnim.to = 1;
                    fillAnim.duration = root.holdMs * (1 - progress);
                    fillAnim.restart();
                }

                function cancelHold() {
                    if (!holding)
                        return ;

                    holding = false;
                    fillAnim.stop();
                    drainAnim.from = progress;
                    drainAnim.to = 0;
                    drainAnim.restart();
                }

                width: root.slot
                height: root.slot

                Behavior on discSize {
                    NumberAnimation {
                        duration: 170
                        easing.type: Easing.OutBack
                        easing.overshoot: 1.4
                    }
                }

                NumberAnimation {
                    id: fillAnim

                    target: button
                    property: "progress"
                    easing.type: Easing.Linear
                    onFinished: {
                        if (button.holding && button.progress >= 1) {
                            button.holding = false;
                            root.activate(button.modelData.key);
                        }
                    }
                }

                NumberAnimation {
                    id: drainAnim

                    target: button
                    property: "progress"
                    duration: 220
                    easing.type: Easing.OutCubic
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: button.discSize
                    height: width
                    radius: width / 2
                    antialiasing: true
                    color: button.selected ? (button.destructive ? Qt.alpha(Theme.red, 0.22) : Theme.primary) : (Theme.isLight ? Qt.darker(Theme.cardColor, 1.1) : Qt.rgba(1, 1, 1, 0.06))
                    border.width: button.selected ? 0 : 1
                    border.color: Theme.cardBorder

                    Behavior on color {
                        ColorAnimation {
                            duration: Theme.animationFast
                        }
                    }
                }

                // vector icon: path is scaled inside the Shape, so it is re-tessellated
                // at the real size instead of being stretched as a texture
                Shape {
                    id: icon

                    readonly property real px: button.discSize * 0.44

                    anchors.centerIn: parent
                    width: px
                    height: px
                    preferredRendererType: Shape.CurveRenderer
                    antialiasing: true

                    ShapePath {
                        strokeWidth: root.stroke
                        strokeColor: button.iconColor
                        fillColor: "transparent"
                        capStyle: ShapePath.RoundCap
                        joinStyle: ShapePath.RoundJoin
                        scale: Qt.size(icon.px / 24, icon.px / 24)

                        PathSvg {
                            path: button.modelData.path
                        }
                    }
                }

                Canvas {
                    id: ring

                    anchors.centerIn: parent
                    width: root.slot + 6 * root.ui
                    height: width
                    visible: button.progress > 0
                    onVisibleChanged: requestPaint()
                    onPaint: {
                        const ctx = getContext("2d");
                        ctx.reset();
                        ctx.lineWidth = 2.2 * root.ui;
                        ctx.lineCap = "round";
                        ctx.strokeStyle = Theme.red;
                        ctx.beginPath();
                        const start = -Math.PI / 2;
                        ctx.arc(width / 2, height / 2, width / 2 - ctx.lineWidth, start, start + Math.PI * 2 * button.progress, false);
                        ctx.stroke();
                    }

                    Connections {
                        function onProgressChanged() {
                            ring.requestPaint();
                        }

                        target: button
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: root.current = button.index
                    onPressed: {
                        root.current = button.index;
                        if (button.modelData.hold)
                            button.startHold();
                    }
                    onReleased: {
                        if (button.modelData.hold)
                            button.cancelHold();
                    }
                    onCanceled: {
                        if (button.modelData.hold)
                            button.cancelHold();
                    }
                    onClicked: {
                        if (!button.modelData.hold)
                            root.activate(button.modelData.key);
                    }
                }
            }
        }
    }

    ShellText {
        id: label

        readonly property var cur: root.actions[root.current]
        readonly property bool pressing: root.currentItem ? root.currentItem.holding : false

        anchors.top: row.bottom
        anchors.topMargin: 6 * root.ui
        anchors.horizontalCenter: parent.horizontalCenter
        text: cur.hold && pressing ? cur.hint : cur.title
        color: cur.hold ? Theme.red : Theme.foreground
        font.pixelSize: 11 * root.ui
        font.weight: Font.Medium
    }
}
