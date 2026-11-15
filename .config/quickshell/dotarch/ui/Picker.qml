import QtQuick
import QtQuick.Controls
import "Singletons"

// A modal, filterable list. Put one at the top of a window, call open(), react to
// chose(name). Sized to its parent; hidden until opened.
Item {
    id: pk

    property string title: ""
    property var options: []
    property string current: ""
    property string query: ""
    signal chose(string name)
    signal dismissed()

    readonly property var filtered: {
        var q = pk.query.trim().toLowerCase();
        if (q === "") return pk.options;
        return pk.options.filter(function (o) { return String(o).toLowerCase().indexOf(q) >= 0; });
    }

    visible: false
    z: 900

    function open() {
        pk.query = "";
        search.clear();
        pk.visible = true;
        search.grabFocus();
    }
    function close() { pk.visible = false; pk.dismissed(); }
    function pickFirst() { if (pk.filtered.length > 0) { pk.visible = false; pk.chose(pk.filtered[0]); } }

    Rectangle {
        anchors.fill: parent
        color: Tokens.paper
        opacity: 0.6
        TapHandler { onTapped: pk.close() }
    }

    Rectangle {
        anchors.centerIn: parent
        width: Math.min(440, parent.width - Tokens.s6 * 2)
        height: Math.min(560, parent.height - Tokens.s6 * 2)
        color: Tokens.paperLift
        radius: Tokens.radius
        border.width: Tokens.border
        border.color: Tokens.lineStrong
        TapHandler {}

        Column {
            id: top
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: Tokens.s4 }
            spacing: Tokens.s3
            Row {
                spacing: Tokens.s2
                Text {
                    text: "//"
                    color: Tokens.inkFaint
                    font.family: Tokens.mono
                    font.pixelSize: 10
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: pk.title.toUpperCase()
                    color: Tokens.inkDim
                    font.family: Tokens.ui
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    font.letterSpacing: Tokens.trackLabel
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: pk.filtered.length + " / " + pk.options.length
                    color: Tokens.inkFaint
                    font.family: Tokens.mono
                    font.pixelSize: 9
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
            Field {
                id: search
                width: parent.width
                placeholder: "Filter\u2026"
                onEdited: (t) => pk.query = t
                onAccepted: pk.pickFirst()
                onEscaped: pk.close()
            }
        }

        ListView {
            id: list
            anchors { left: parent.left; right: parent.right; top: top.bottom; bottom: parent.bottom }
            anchors.margins: Tokens.s2
            anchors.topMargin: Tokens.s3
            clip: true
            model: pk.filtered
            spacing: 1
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollRail { policy: ScrollBar.AsNeeded }

            delegate: Rectangle {
                id: item
                required property string modelData
                readonly property bool on: modelData === pk.current
                width: ListView.view.width
                height: 30
                radius: Tokens.radius
                color: on ? Tokens.bone : (ih.hovered ? Tokens.tint10 : "transparent")
                Behavior on color { ColorAnimation { duration: Tokens.snap } }

                Row {
                    x: Tokens.s3
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Tokens.s2
                    Text {
                        visible: item.on
                        text: "//"
                        color: Tokens.inkOnBoneDim
                        font.family: Tokens.mono
                        font.pixelSize: 10
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: item.modelData
                        color: item.on ? Tokens.inkOnBone : Tokens.ink
                        font.family: Tokens.ui
                        font.pixelSize: 13
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
                HoverHandler { id: ih; cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: { pk.visible = false; pk.chose(item.modelData); } }
            }
        }
    }
}
