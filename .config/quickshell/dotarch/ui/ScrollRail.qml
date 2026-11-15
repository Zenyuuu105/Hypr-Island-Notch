import QtQuick
import QtQuick.Controls
import "Singletons"

ScrollBar {
    id: bar
    implicitWidth: 8
    contentItem: Rectangle {
        implicitWidth: 3
        radius: 1
        color: Tokens.lineStrong
        opacity: bar.active ? 1 : 0.4
        Behavior on opacity { NumberAnimation { duration: Tokens.flap } }
    }
    background: Item {}
}
