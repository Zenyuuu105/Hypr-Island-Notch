import QtQuick
import "Singletons"

// A switch row bound to a Store key.
SettingRow {
    id: r
    property string key: ""
    anchors.left: parent.left
    anchors.right: parent.right
    controlWidth: 54
    def: Store.defaults[key] ? "ON" : "OFF"
    changed: Store.changed(key)
    onResetRequested: Store.reset(key)

    Sw {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        on: Store.get(r.key) === true
        onToggled: (v) => Store.set(r.key, v)
    }
}
