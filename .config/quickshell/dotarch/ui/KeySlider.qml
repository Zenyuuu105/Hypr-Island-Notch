import QtQuick
import "Singletons"

// A slider row bound to a Store key. decimals: 0 = whole numbers.
SettingRow {
    id: r
    property string key: ""
    property real from: 0
    property real to: 100
    property int decimals: 0
    readonly property real cur: Number(Store.get(key))

    anchors.left: parent.left
    anchors.right: parent.right
    controlWidth: Math.min(240, Math.max(160, Math.round(width * 0.34)))
    value: cur.toFixed(decimals)
    def: Number(Store.defaults[key]).toFixed(decimals)
    changed: Store.changed(key)
    onResetRequested: Store.reset(key)

    Slid {
        anchors.fill: parent
        from: r.from
        to: r.to
        value: r.cur
        onModified: (v) => Store.set(r.key, r.decimals > 0 ? Number(v.toFixed(r.decimals)) : Math.round(v))
    }
}
