import Quickshell

PanelWindow {
    // Invisible strip that only reserves space for the collapsed notch.
    // 32 = collapsedHeight, 6 = gap. Change the 6 to taste.
    exclusiveZone: 0
    implicitHeight: 1
    color: "transparent"
    mask: Region {}

    anchors {
        top: true
        left: true
        right: true
    }
}
