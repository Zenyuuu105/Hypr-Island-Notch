pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Settings values, persisted to ~/.config/dotarch/settings.json, and applied to
// the running compositor the moment they change. Keys are Hyprland option names
// ("general:gaps_in"), so adding a setting is: add a default here, add a row.
//
// Only values you have changed are written to disk; everything else follows the
// default. On start the saved values are re-applied, so they survive a relogin.
Singleton {
    id: store

    readonly property var defaults: ({
        "general:gaps_in": 5,
        "general:gaps_out": 20,
        "general:border_size": 2,
        "decoration:rounding": 10,
        "decoration:blur:enabled": true,
        "animations:enabled": true,
        "input:sensitivity": 0,
        "input:follow_mouse": 1,
        "input:repeat_rate": 25,
        "input:repeat_delay": 600,
        "input:touchpad:natural_scroll": false,
        "input:touchpad:tap-to-click": true,
        "input:touchpad:disable_while_typing": true
    })

    property var values: ({})
    readonly property string path: (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/dotarch/settings.json"

    function get(k) {
        var v = values[k];
        return v === undefined ? defaults[k] : v;
    }
    function changed(k) { return values[k] !== undefined && values[k] !== defaults[k]; }

    // ONE place that talks to the compositor. If your Hyprland build wants
    // something other than `hyprctl keyword`, change only this function.
    function apply(k, v) {
        Quickshell.execDetached(["hyprctl", "keyword", k, String(v)]);
    }

    function set(k, v) {
        var n = Object.assign({}, values);
        n[k] = v;
        values = n;
        apply(k, v);
        saveTimer.restart();
    }
    function reset(k) {
        var n = Object.assign({}, values);
        delete n[k];
        values = n;
        apply(k, defaults[k]);
        saveTimer.restart();
    }
    function resetAll() {
        for (var k in defaults) apply(k, defaults[k]);
        values = ({});
        saveTimer.restart();
    }

    Timer {
        id: saveTimer
        interval: 300
        onTriggered: file.setText(JSON.stringify(store.values, null, 2))
    }

    FileView {
        id: file
        path: store.path
        blockLoading: true
        printErrors: false
        onLoaded: {
            try {
                var o = JSON.parse(file.text());
                if (o && typeof o === "object") {
                    store.values = o;
                    for (var k in o) store.apply(k, o[k]);
                }
            } catch (e) {}
        }
    }
}
