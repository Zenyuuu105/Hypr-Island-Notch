pragma Singleton

import QtQuick
import Quickshell

// The one place the look is defined. Edit the palette here and everything follows.
// Fonts fall back through the lists below, so the look degrades gracefully when
// Space Grotesk / Fraunces are not installed.
Singleton {
    id: t

    // ── paper and ink ───────────────────────────────────────────────────
    readonly property color paper: "#000000"
    readonly property color paperLift: "#0a0a0a"
    readonly property color ink: "#cdc4ba"
    readonly property color inkDim: "#b0a9a0"
    readonly property color inkMuted: Qt.rgba(inkDim.r, inkDim.g, inkDim.b, 0.88)
    readonly property color inkFaint: Qt.rgba(inkDim.r, inkDim.g, inkDim.b, 0.68)

    readonly property color bone: ink
    readonly property color inkOnBone: "#000000"
    readonly property color inkOnBoneDim: Qt.rgba(inkOnBone.r, inkOnBone.g, inkOnBone.b, 0.62)
    readonly property color alert: "#e2342a"

    readonly property color line: Qt.rgba(ink.r, ink.g, ink.b, 0.26)
    readonly property color lineSoft: Qt.rgba(ink.r, ink.g, ink.b, 0.13)
    readonly property color lineStrong: Qt.rgba(ink.r, ink.g, ink.b, 0.42)
    readonly property color tint5: Qt.rgba(ink.r, ink.g, ink.b, 0.05)
    readonly property color tint10: Qt.rgba(ink.r, ink.g, ink.b, 0.10)
    readonly property color tint16: Qt.rgba(ink.r, ink.g, ink.b, 0.16)

    // ── type ────────────────────────────────────────────────────────────
    function pick(list) {
        var have = Qt.fontFamilies();
        for (var i = 0; i < list.length; i++)
            if (have.indexOf(list[i]) >= 0) return list[i];
        return list[list.length - 1];
    }
    readonly property string display: pick(["Fraunces", "Noto Serif Display", "Geist", "Inter Display", "Inter"])
    readonly property string ui: pick(["Space Grotesk", "Geist", "Inter", "SF Pro Text", "Noto Sans"])
    readonly property string mono: pick(["SpaceMono Nerd Font", "JetBrainsMono Nerd Font", "Geist Mono", "DejaVu Sans Mono"])

    readonly property int fTitle: 32
    readonly property int fRow: 15
    readonly property int fBody: 14
    readonly property int fSmall: 13
    readonly property int fMicro: 11
    readonly property int fTiny: 9
    readonly property real trackLabel: 1.4
    readonly property real trackMark: 2.2

    // ── space and geometry ──────────────────────────────────────────────
    readonly property int s1: 4
    readonly property int s2: 8
    readonly property int s3: 12
    readonly property int s4: 16
    readonly property int s5: 24
    readonly property int s6: 32
    readonly property int radius: 6
    readonly property real border: 1
    readonly property int rowH: 48
    readonly property int ctlH: 26
    readonly property int railW: 268
    readonly property int cardWide: 760

    // ── motion ──────────────────────────────────────────────────────────
    readonly property int snap: 90
    readonly property int move: 170
    readonly property int swap: 210
    readonly property int flap: 110
    readonly property int ease: Easing.OutCubic
    readonly property int easeSnap: Easing.OutQuad
}
