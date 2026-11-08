import QtQuick
import QtQuick.Effects
import qs
import ".."

Item {
    id: root

    property real level: 0
    property bool charging: false

    readonly property real frac: Math.max(0, Math.min(1, level > 1 ? level / 100 : level))
    readonly property color fillColor: charging ? Theme.green
                                     : frac <= 0.15 ? Theme.red
                                     : Theme.primary

    readonly property int pad: 6

    implicitWidth: 25
    implicitHeight: 13

    // Oversized wrapper so the glow isn't clipped; layout size stays 25x13
    Item {
        id: glowWrap
        anchors.centerIn: parent
        width: root.width + root.pad * 2
        height: root.height + root.pad * 2

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: root.fillColor
            shadowBlur: 0.3
            shadowOpacity: 0.55
            shadowScale: 1.0
        }

        Item {
            x: root.pad
            y: root.pad
            width: root.width
            height: root.height

            Rectangle {
                id: track
                width: 22
                height: 13
                radius: 4
                color: Qt.rgba(Theme.shellForeground.r, Theme.shellForeground.g, Theme.shellForeground.b, 0.22)

                Rectangle {
                    height: parent.height
                    width: Math.max(root.frac > 0 ? 5 : 0, parent.width * root.frac)
                    topLeftRadius: 4
                    bottomLeftRadius: 4
                    topRightRadius: root.frac >= 0.97 ? 4 : 1
                    bottomRightRadius: root.frac >= 0.97 ? 4 : 1
                    color: root.fillColor

                    Behavior on width { SpringAnim {} }
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
            }

            Rectangle {
                anchors.left: track.right
                anchors.leftMargin: 1
                anchors.verticalCenter: track.verticalCenter
                width: 2
                height: 4
                radius: 1
                color: Qt.rgba(Theme.shellForeground.r, Theme.shellForeground.g, Theme.shellForeground.b, 0.35)
            }
        }
    }
}
