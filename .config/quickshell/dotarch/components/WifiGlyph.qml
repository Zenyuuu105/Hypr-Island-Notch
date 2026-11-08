import QtQuick
import QtQuick.Effects
import qs

Item {
    id: root

    property real level: 0
    property bool connected: false
    property color foreground: Theme.primary
    readonly property color iconColor: connected
        ? foreground
        : Qt.alpha(Theme.muted, 0.65)

    readonly property int pad: 6

    implicitWidth: 18
    implicitHeight: 14

    Item {
        anchors.centerIn: parent
        width: root.width + root.pad * 2
        height: root.height + root.pad * 2

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: root.connected
            shadowColor: root.iconColor
            shadowBlur: 0.3
            shadowOpacity: 0.55
            shadowScale: 1.0
        }

        Item {
            x: root.pad
            y: root.pad
            width: root.width
            height: root.height

            Repeater {
                model: 4

                Rectangle {
                    required property int index

                    x: index * 5
                    y: root.height - height
                    width: 3
                    height: 4 + index * 3
                    radius: 1
                    color: root.iconColor
                    opacity: root.connected && (index === 0 || root.level > index * 0.25)
                        ? 1
                        : 0.3

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 120
                        }
                    }
                }
            }
        }
    }
}
