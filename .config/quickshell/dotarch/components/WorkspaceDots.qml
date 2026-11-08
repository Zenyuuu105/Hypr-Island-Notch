import QtQuick
import QtQuick.Effects
import Quickshell.Hyprland
import qs
import ".."

Row {
    id: root

    property int count: 5
    readonly property int current: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1

    spacing: 5

    Repeater {
        model: root.count

        Rectangle {
            id: dot

            required property int index
            readonly property bool isActive: root.current === index + 1

            anchors.verticalCenter: parent.verticalCenter
            width: isActive ? 10 : 6
            height: isActive ? 16 : 10
            radius: width / 2
            color: isActive ? Theme.primary : Theme.shellForeground
            opacity: isActive ? 1 : 0.28

            // Soft glow behind the active dot only
            Item {
                z: -1
                anchors.centerIn: parent
                width: dot.width + 12
                height: dot.height + 12
                opacity: dot.isActive ? 1 : 0
                visible: opacity > 0

                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: Theme.primary
                    shadowBlur: 0.3
                    shadowOpacity: 0.55
                    shadowScale: 1.0
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: dot.width
                    height: dot.height
                    radius: dot.radius
                    color: Theme.primary
                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: 140
                    }
                }
            }

            Behavior on width {
                SpringAnim {}
            }

            Behavior on height {
                SpringAnim {}
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: 140
                }
            }

            MouseArea {
                anchors.fill: parent
                anchors.margins: -3
                cursorShape: Qt.PointingHandCursor
                onClicked: Hyprland.dispatch("workspace " + (parent.index + 1))
            }
        }
    }
}
