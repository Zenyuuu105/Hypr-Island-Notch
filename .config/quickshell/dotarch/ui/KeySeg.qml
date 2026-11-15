import QtQuick
import "Singletons"

// A segmented row bound to a Store key. `options` are the labels, `values` the
// stored values in the same order.
SettingRow {
    id: r
    property string key: ""
    property var options: []
    property var values: []

    function labelOf(v) {
        var i = values.indexOf(v);
        return i >= 0 ? options[i] : "";
    }

    anchors.left: parent.left
    anchors.right: parent.right
    controlWidth: Math.max(120, 62 * Math.max(2, options.length))
    def: labelOf(Store.defaults[key])
    changed: Store.changed(key)
    onResetRequested: Store.reset(key)

    Seg {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        options: r.options
        current: r.labelOf(Store.get(r.key))
        onChose: (label) => Store.set(r.key, r.values[r.options.indexOf(label)])
    }
}
