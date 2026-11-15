import QtQuick
import "../ui"
import "../ui/Singletons"

SettingsPage {
    eyebrow: "LOOK"
    title: "Desktop"
    blurb: "Gaps, corners, borders and effects. Changes apply to your running desktop as you make them."

    SettingCard {
        title: "WINDOWS"
        KeySlider { key: "general:gaps_in"; label: "Inner gaps"; desc: "Space between tiled windows."; unit: "px"; from: 0; to: 40 }
        KeySlider { divider: true; key: "general:gaps_out"; label: "Outer gaps"; desc: "Space between windows and the screen edge."; unit: "px"; from: 0; to: 80 }
        KeySlider { divider: true; key: "general:border_size"; label: "Border width"; desc: "Thickness of the window outline."; unit: "px"; from: 0; to: 10 }
        KeySlider { divider: true; key: "decoration:rounding"; label: "Corner radius"; desc: "How round window corners are."; unit: "px"; from: 0; to: 30 }
    }

    SettingCard {
        title: "EFFECTS"
        KeySwitch { key: "decoration:blur:enabled"; label: "Blur"; desc: "Frosted background behind translucent windows." }
        KeySwitch { divider: true; key: "animations:enabled"; label: "Animations"; desc: "Window and workspace motion." }
    }
}
