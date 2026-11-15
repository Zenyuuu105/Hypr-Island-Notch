import QtQuick
import "Singletons"

// A page body of cards laid into balanced columns. Each card goes into whichever
// column is currently shortest, so a wide window gets 2-3 columns of cards. Works
// with cards declared directly or produced by a Repeater (the Repeater itself has
// no height and is skipped).
Item {
    id: root

    property real spacing: Tokens.s4
    property real columnSpacing: Tokens.s5
    property int maxColumns: 3
    property real minColumnWidth: 440
    property real fillTo: 0
    default property alias content: stage.data

    function isBlock(c) {
        return c && c.visible !== false && (c.implicitHeight > 0 || c.height > 0);
    }

    readonly property int blocks: {
        var n = 0;
        for (var i = 0; i < stage.children.length; i++)
            if (root.isBlock(stage.children[i])) n++;
        return n;
    }
    readonly property int capacity: Math.max(1, Math.min(maxColumns,
        Math.floor((width + columnSpacing) / (minColumnWidth + columnSpacing))))
    readonly property int columns: Math.max(1, Math.min(capacity, blocks))
    readonly property real colWidth: Math.min(Tokens.cardWide,
        Math.max(200, Math.floor((width - (columns - 1) * columnSpacing) / columns)))

    property real layoutHeight: 0
    implicitHeight: layoutHeight
    height: implicitHeight

    Item { id: stage; anchors.fill: parent }

    property bool _laying: false
    function relay() {
        if (_laying) { settle.restart(); return; }
        lay();
        settle.restart();   // one trailing pass to catch late size changes
    }

    function lay() {
        if (width <= 0 || _laying) return;
        _laying = true;
        var cur = [];
        for (var c = 0; c < columns; c++) cur.push(0);
        var lowest = 0;
        for (var i = 0; i < stage.children.length; i++) {
            var kid = stage.children[i];
            if (!root.isBlock(kid)) continue;
            if (Math.abs(kid.width - colWidth) > 0.5) kid.width = colWidth;
            var col = 0;
            for (var k = 1; k < columns; k++)
                if (cur[k] < cur[col] - 0.5) col = k;
            kid.x = col * (colWidth + columnSpacing);
            kid.y = cur[col];
            cur[col] += kid.height + spacing;
            lowest = Math.max(lowest, cur[col] - spacing);
        }
        layoutHeight = Math.max(lowest, fillTo);
        _laying = false;
    }

    Timer { id: settle; interval: 16; repeat: false; onTriggered: root.lay() }
    onWidthChanged: relay()
    onColumnsChanged: relay()
    onFillToChanged: relay()

    property var _wired: []
    function wireChildren() {
        for (var i = 0; i < stage.children.length; i++) {
            var c = stage.children[i];
            if (!c || _wired.indexOf(c) !== -1) continue;
            _wired.push(c);
            c.heightChanged.connect(root.relay);
            c.visibleChanged.connect(root.relay);
        }
    }
    Connections {
        target: stage
        function onChildrenChanged() { root.wireChildren(); root.relay(); }
    }
    Component.onCompleted: { wireChildren(); lay(); settle.restart(); }
}
