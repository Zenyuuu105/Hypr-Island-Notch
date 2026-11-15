import QtQuick
import "../ui"
import "../ui/Singletons"

SettingsPage {
    eyebrow: "DEVICES"
    title: "Input"
    blurb: "Pointer, touchpad and key repeat."

    SettingCard {
        title: "POINTER"
        KeySlider { key: "input:sensitivity"; label: "Sensitivity"; desc: "Pointer speed offset; 0 is the device default."; from: -1; to: 1; decimals: 2 }
        KeySeg {
            divider: true
            key: "input:follow_mouse"
            label: "Focus behavior"
            desc: "How windows take focus as the pointer moves."
            options: ["Click", "Follow"]
            values: [0, 1]
        }
    }

    SettingCard {
        title: "TOUCHPAD"
        KeySwitch { key: "input:touchpad:natural_scroll"; label: "Natural scroll"; desc: "Two fingers drag the content like a touchscreen." }
        KeySwitch { divider: true; key: "input:touchpad:tap-to-click"; label: "Tap to click"; desc: "A tap counts as a click." }
        KeySwitch { divider: true; key: "input:touchpad:disable_while_typing"; label: "Disable while typing"; desc: "Ignore the pad while typing so a palm can't nudge it." }
    }

    SettingCard {
        title: "KEY REPEAT"
        KeyStep { key: "input:repeat_rate"; label: "Repeat rate"; desc: "Characters per second while a key is held."; unit: "/s"; from: 1; to: 100 }
        KeyStep { divider: true; key: "input:repeat_delay"; label: "Repeat delay"; desc: "Pause before a held key starts repeating."; unit: "ms"; from: 100; to: 2000; stepBy: 50 }
    }
}
