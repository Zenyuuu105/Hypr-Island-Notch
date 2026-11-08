import QtQuick
import qs
import qs.components

FocusScope {
    id: root

    property int viewYear: new Date().getFullYear()
    property int viewMonth: new Date().getMonth()
    property var now: new Date()
    property bool wheelLocked: false
    readonly property real cellWidth: width / 7
    readonly property int firstWeekday: new Date(viewYear, viewMonth, 1).getDay()

    function takeInitialFocus() {
        root.forceActiveFocus(Qt.TabFocusReason);
    }

    function shift(offset) {
        const d = new Date(viewYear, viewMonth + offset, 1);
        viewYear = d.getFullYear();
        viewMonth = d.getMonth();
    }

    function goToday() {
        const n = new Date();
        now = n;
        viewYear = n.getFullYear();
        viewMonth = n.getMonth();
    }

    implicitWidth: 312
    implicitHeight: 268
    Keys.onLeftPressed: root.shift(-1)
    Keys.onRightPressed: root.shift(1)
    Keys.onReturnPressed: root.goToday()
    Keys.onEnterPressed: root.goToday()

    Connections {
        target: ShellState

        function onPanelChanged() {
            if (ShellState.panel === "calendar")
                root.goToday();
        }
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }

    Timer {
        id: wheelCooldown

        interval: 150
        onTriggered: root.wheelLocked = false
    }

    WheelHandler {
        target: null
        onWheel: (event) => {
            if (!root.wheelLocked) {
                root.shift(event.angleDelta.y > 0 ? -1 : 1);
                root.wheelLocked = true;
                wheelCooldown.restart();
            }
            event.accepted = true;
        }
    }

    component NavButton: FocusScope {
        id: nav

        property string glyph: ""
        property string accessibleName: ""

        signal clicked()

        width: 30
        height: 30
        activeFocusOnTab: true
        Keys.onReturnPressed: nav.clicked()
        Keys.onEnterPressed: nav.clicked()
        Keys.onSpacePressed: nav.clicked()
        Accessible.role: Accessible.Button
        Accessible.name: accessibleName

        Rectangle {
            anchors.fill: parent
            radius: 15
            color: navPointer.containsMouse ? Theme.bg2 : Theme.cardColor
            border.width: nav.activeFocus ? 2 : 1
            border.color: nav.activeFocus ? Theme.cardBorderSelected : Theme.cardBorder
        }

        ShellText {
            anchors.centerIn: parent
            text: nav.glyph
            font.family: Theme.iconFontFamily
            color: Theme.foreground
            font.pixelSize: 15
        }

        MouseArea {
            id: navPointer

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: nav.clicked()
        }
    }

    Column {
        anchors.fill: parent
        spacing: 4

        Item {
            width: parent.width
            height: 32

            NavButton {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                glyph: "\uDB80\uDC4D"
                accessibleName: "Previous month"
                onClicked: root.shift(-1)
            }

            ShellText {
                anchors.centerIn: parent
                text: Qt.formatDate(new Date(root.viewYear, root.viewMonth, 1), "MMMM yyyy")
                color: Theme.shellForeground
                font.pixelSize: 15
                font.weight: Font.Bold

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -6
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.goToday()
                }
            }

            NavButton {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                glyph: "\uDB80\uDC54"
                accessibleName: "Next month"
                onClicked: root.shift(1)
            }
        }

        Row {
            width: parent.width

            Repeater {
                model: 7

                Item {
                    required property int index

                    width: root.cellWidth
                    height: 22

                    ShellText {
                        anchors.centerIn: parent
                        text: "SMTWTFS"[index]
                        color: Theme.mutedDark
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                    }
                }
            }
        }

        Grid {
            width: parent.width
            columns: 7

            Repeater {
                model: 42

                Item {
                    id: dayCell

                    required property int index
                    readonly property var cellDate: new Date(root.viewYear, root.viewMonth, 1 - root.firstWeekday + index)
                    readonly property bool inMonth: cellDate.getMonth() === root.viewMonth
                    readonly property bool isToday: cellDate.getFullYear() === root.now.getFullYear() && cellDate.getMonth() === root.now.getMonth() && cellDate.getDate() === root.now.getDate()

                    width: root.cellWidth
                    height: 34

                    Rectangle {
                        anchors.centerIn: parent
                        width: 30
                        height: 30
                        radius: 15
                        color: dayCell.isToday ? Theme.primary : (dayPointer.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent")
                    }

                    ShellText {
                        anchors.centerIn: parent
                        text: dayCell.cellDate.getDate()
                        color: dayCell.isToday ? Theme.bgDim : (dayCell.inMonth ? Theme.shellForeground : Theme.mutedDark)
                        font.pixelSize: 13
                        font.weight: dayCell.isToday ? Font.Bold : Font.Normal
                    }

                    MouseArea {
                        id: dayPointer

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (!dayCell.inMonth)
                                root.shift(dayCell.index < root.firstWeekday ? -1 : 1);
                        }
                    }
                }
            }
        }
    }
}
