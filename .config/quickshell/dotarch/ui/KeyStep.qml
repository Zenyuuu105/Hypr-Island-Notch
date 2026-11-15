import QtQuick
import "Singletons"

// A +/- stepper row bound to a Store key.
SettingRow {
    id: r
    property string key: ""
    property int from: 0
    property int to: 100
    property int stepBy: 1

    anchors.left: parent.left
    anchors.right: parent.right
    controlWidth: 58
    value: String(Math.round(Number(Store.get(key))))
    def: String(Store.defaults[key])
    changed: Store.changed(key)
    onResetRequested: Store.reset(key)

    Step {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        from: r.from
        to: r.to
        stepBy: r.stepBy
        value: Math.round(Number(Store.get(r.key)))
        onModified: (v) => Store.set(r.key, v)
    }
}
