pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import "Singletons"

// Renders a page definition ({ name, group, sections: [{ title, footer, items }] })
// as Ryoku-style cards. Item types: toggle, slider, choice, button, font, swatch.
// An item may carry `when: { k, v }` to show only while cfg[k] === v.
// Anything declared inside the sheet rides in the scroll area above the cards
// (the notch preview uses this).
Item {
    id: sheet

    property var page: ({ name: "", group: "", sections: [] })
    property var cfg: null
    default property alias lead: leadSlot.data

    signal edited(string key, var value)
    signal activated(var item)
    signal fontPickRequested(var item)

    onPageChanged: flick.contentY = 0

    // ── logic ────────────────────────────────────────────────────────────
    function shown(it) {
        if (!it.when) return true;
        return !!sheet.cfg && sheet.cfg[it.when.k] === it.when.v;
    }
    function visibleItems(sec) {
        return sec.items.filter(function (it) { return sheet.shown(it); });
    }
    function val(it) { return (sheet.cfg && it.key) ? sheet.cfg[it.key] : undefined; }

    function optText(it, key) {
        var o = it.options || [];
        for (var i = 0; i < o.length; i++) if (o[i].key === key) return o[i].text;
        return "";
    }
    function optKey(it, text) {
        var o = it.options || [];
        for (var i = 0; i < o.length; i++) if (o[i].text === text) return o[i].key;
        return text;
    }
    function optTexts(it) {
        var out = [], o = it.options || [];
        for (var i = 0; i < o.length; i++) out.push(o[i].text);
        return out;
    }
    function segW(it) {
        var w = 0, o = it.options || [];
        for (var i = 0; i < o.length; i++) w += Math.max(52, String(o[i].text).length * 7 + 18);
        return w + 4 * Math.max(0, o.length - 1);
    }
    function isBlock(it) {
        if (it.type === "swatch") return true;
        if (it.type === "choice") return (it.options || []).length >= 3 || sheet.segW(it) > 200;
        return false;
    }
    function readout(it) {
        if (it.type !== "slider") return "";
        var v = Number(sheet.val(it));
        if (it.zero && v === 0) return it.zero;
        return String(v);
    }
    function readoutUnit(it) {
        if (it.type !== "slider") return "";
        var v = Number(sheet.val(it));
        return (it.zero && v === 0) ? "" : (it.unit || "");
    }
    function ctlWidth(it, w) {
        if (it.type === "toggle") return 54;
        if (it.type === "slider") return Math.min(240, Math.max(160, Math.round(w * 0.34)));
        if (it.type === "choice") return sheet.segW(it);
        if (it.type === "button") return Math.max(88, String(it.text || "").length * 8 + 34);
        return 54;
    }
    function rowDesc(it) {
        if (it.pageName) return it.pageName + (it.hint ? "  \u00b7  " + it.hint : "");
        return it.hint || "";
    }

    // ── head ─────────────────────────────────────────────────────────────
    Column {
        id: head
        anchors { left: parent.left; top: parent.top }
        width: parent.width - Tokens.s3
        spacing: Tokens.s3

        Row {
            visible: sheet.page.group !== undefined && sheet.page.group !== ""
            height: 18
            spacing: Tokens.s2
            Rectangle { width: 16; height: 1; color: Tokens.ink; anchors.verticalCenter: parent.verticalCenter }
            Text {
                text: sheet.page.group || ""
                color: Tokens.inkMuted
                font.family: Tokens.ui
                font.pixelSize: 9
                font.weight: Font.Medium
                font.letterSpacing: Tokens.trackMark
                anchors.verticalCenter: parent.verticalCenter
            }
        }
        Text {
            text: sheet.page.name
            color: Tokens.ink
            font.family: Tokens.display
            font.pixelSize: Tokens.fTitle
        }
    }

    // ── body ─────────────────────────────────────────────────────────────
    Flickable {
        id: flick
        anchors { left: parent.left; right: parent.right; top: head.bottom; bottom: parent.bottom }
        anchors.topMargin: Tokens.s5
        contentWidth: width
        contentHeight: Math.max(col.height + Tokens.s5, height)
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollRail { policy: ScrollBar.AsNeeded }

        Column {
            id: col
            width: flick.width - Tokens.s3
            spacing: Tokens.s5

            Column {
                id: leadSlot
                width: col.width
                spacing: Tokens.s4
            }

            Text {
                visible: !!sheet.page.empty
                width: col.width
                topPadding: Tokens.s6
                horizontalAlignment: Text.AlignHCenter
                text: sheet.page.empty || ""
                color: Tokens.inkMuted
                font.family: Tokens.ui
                font.pixelSize: Tokens.fBody
            }

            CardColumns {
                id: cards
                width: col.width

                Repeater {
                    model: sheet.page.sections

                    SettingCard {
                        id: card
                        required property var modelData
                        title: (modelData.title ? modelData.title : "Settings").toUpperCase()
                        note: modelData.footer || ""
                        visible: rep.count > 0

                        Repeater {
                            id: rep
                            model: sheet.visibleItems(card.modelData)

                            SettingRow {
                                id: srow
                                required property var modelData
                                required property int index
                                readonly property var it: modelData

                                anchors.left: parent.left
                                anchors.right: parent.right
                                divider: index > 0
                                label: it.label
                                desc: sheet.rowDesc(it)
                                value: sheet.readout(it)
                                unit: sheet.readoutUnit(it)
                                block: sheet.isBlock(it)
                                footH: it.type === "font" ? 32 : 0
                                controlWidth: sheet.ctlWidth(it, srow.width)

                                Loader {
                                    anchors.fill: parent
                                    sourceComponent: {
                                        switch (srow.it.type) {
                                        case "toggle": return toggleC;
                                        case "slider": return sliderC;
                                        case "choice": return choiceC;
                                        case "button": return buttonC;
                                        case "font": return fontC;
                                        case "swatch": return swatchC;
                                        default: return null;
                                        }
                                    }
                                }

                                Component {
                                    id: toggleC
                                    Sw {
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        on: !!sheet.val(srow.it)
                                        onToggled: (v) => sheet.edited(srow.it.key, v)
                                    }
                                }
                                Component {
                                    id: sliderC
                                    Slid {
                                        anchors.fill: parent
                                        from: srow.it.min !== undefined ? srow.it.min : 0
                                        to: srow.it.max !== undefined ? srow.it.max : 100
                                        value: Number(sheet.val(srow.it)) || 0
                                        onModified: (v) => {
                                            var s = srow.it.step || 1;
                                            var n = Math.round(v / s) * s;
                                            n = Math.max(from, Math.min(to, n));
                                            sheet.edited(srow.it.key, n);
                                        }
                                    }
                                }
                                Component {
                                    id: choiceC
                                    Seg {
                                        anchors.right: parent.right
                                        anchors.left: srow.block ? parent.left : undefined
                                        anchors.verticalCenter: parent.verticalCenter
                                        options: sheet.optTexts(srow.it)
                                        current: sheet.optText(srow.it, sheet.val(srow.it))
                                        onChose: (label) => sheet.edited(srow.it.key, sheet.optKey(srow.it, label))
                                    }
                                }
                                Component {
                                    id: buttonC
                                    Btn {
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        compact: true
                                        text: String(srow.it.text || "").toUpperCase()
                                        onAct: sheet.activated(srow.it)
                                    }
                                }
                                Component {
                                    id: fontC
                                    PickBar {
                                        anchors.fill: parent
                                        value: String(sheet.val(srow.it) || "")
                                        onOpened: sheet.fontPickRequested(srow.it)
                                    }
                                }
                                Component {
                                    id: swatchC
                                    Row {
                                        anchors.left: parent.left
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: Tokens.s2
                                        Repeater {
                                            model: srow.it.swatches || []
                                            Rectangle {
                                                id: sw
                                                required property string modelData
                                                readonly property bool on: String(sheet.val(srow.it)).toLowerCase() === modelData.toLowerCase()
                                                width: 28
                                                height: 28
                                                radius: Tokens.radius
                                                color: modelData
                                                border.width: on ? 2 : Tokens.border
                                                border.color: on ? Tokens.ink : Tokens.line
                                                scale: swh.hovered ? 1.08 : 1
                                                Behavior on scale { NumberAnimation { duration: Tokens.snap } }
                                                HoverHandler { id: swh; cursorShape: Qt.PointingHandCursor }
                                                TapHandler { onTapped: sheet.edited(srow.it.key, sw.modelData) }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
