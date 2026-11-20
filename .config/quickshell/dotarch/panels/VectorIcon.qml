import QtQuick
import QtQuick.Shapes

Item {
    id: vi

    property string name: ""
    property color color: "white"
    property real size: 18
    property int level: 3
    property real value: 0
    property bool searching: false
    property real strokeWidth: 1.9
    property int phase: 3

    readonly property bool dims: name === "wifi" || name === "volume"
    readonly property int lv: name === "volume" ? (value > 0.5 ? 2 : (value > 0.02 ? 1 : 0))
                                                : ((name === "wifi" && searching) ? phase : level)

    readonly property var icons: ({
        "wifi": ["M12 20h.01", "M8.5 16.43a5 5 0 0 1 7 0", "M5 12.86a10 10 0 0 1 14 0", "M2 8.82a15 15 0 0 1 20 0"],
        "wifi_off": ["M12 20h.01", "M8.5 16.43a5 5 0 0 1 7 0", "M5 12.86a10 10 0 0 1 14 0", "M2 8.82a15 15 0 0 1 20 0", "M3 3l18 18"],
        "focus": ["M3 12a9 9 0 1 0 18 0a9 9 0 1 0 -18 0", "M8 12h8"],
        "bluetooth": ["M7 7l10 10-5 5V2l5 5-5 5", "M7 17l10-10"],
        "moon": ["M12 3a6 6 0 0 0 9 9 9 9 0 1 1-9-9Z"],
        "sun": ["M16 12a4 4 0 1 0-8 0 4 4 0 0 0 8 0", "M12 2v2 M12 20v2 M4.93 4.93l1.41 1.41 M17.66 17.66l1.41 1.41 M2 12h2 M20 12h2 M6.34 17.66l-1.41 1.41 M19.07 4.93l-1.41 1.41"],
        "volume": ["M11 5L6 9H2v6h4l5 4V5Z", "M15.54 8.46a5 5 0 0 1 0 7.07", "M19.07 4.93a10 10 0 0 1 0 14.14"],
        "mute": ["M11 5L6 9H2v6h4l5 4V5Z", "M22 9l-6 6 M16 9l6 6"],
        "chevron": ["M9 6l6 6-6 6"],
        "back": ["M15 6l-6 6 6 6"],
        "refresh": ["M21 12a9 9 0 1 1-3-6.7", "M21 4v5h-5"],
        "bell": ["M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9", "M10.3 21a1.94 1.94 0 0 0 3.4 0"],
        "mic": ["M12 2a3 3 0 0 0-3 3v7a3 3 0 0 0 6 0V5a3 3 0 0 0-3-3Z", "M19 10v2a7 7 0 0 1-14 0v-2", "M12 19v3"],
        "mic_off": ["M12 2a3 3 0 0 0-3 3v7a3 3 0 0 0 6 0V5a3 3 0 0 0-3-3Z", "M19 10v2a7 7 0 0 1-14 0v-2", "M12 19v3", "M3 3l18 18"],
        "lock": ["M5 11h14v10H5Z", "M8 11V7a4 4 0 0 1 8 0v4"],
        "check": ["M5 12l5 5L20 7"]
    })
    readonly property var segs: icons[name] || []

    width: size
    height: size
    transformOrigin: Item.Center
    rotation: name === "sun" ? Math.max(0, Math.min(1, value)) * 180 : 0

    Behavior on rotation {
        NumberAnimation {
            duration: 260
            easing.type: Easing.OutCubic
        }
    }

    NumberAnimation on phase {
        from: 0
        to: 3
        duration: 1100
        loops: Animation.Infinite
        running: vi.searching && vi.name === "wifi"
    }

    Item {
        width: 24
        height: 24
        scale: vi.size / 24
        transformOrigin: Item.TopLeft

        Repeater {
            model: vi.segs

            Shape {
                required property var modelData
                required property int index

                width: 24
                height: 24
                preferredRendererType: Shape.CurveRenderer
                opacity: (vi.dims && index > vi.lv) ? 0.25 : 1

                Behavior on opacity {
                    NumberAnimation { duration: 220 }
                }

                ShapePath {
                    strokeColor: vi.color
                    strokeWidth: vi.name === "bluetooth" ? 1.8 : vi.strokeWidth
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap
                    joinStyle: ShapePath.RoundJoin

                    PathSvg {
                        path: modelData
                    }
                }
            }
        }
    }
}
