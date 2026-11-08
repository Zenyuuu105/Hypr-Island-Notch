import QtQuick

Item {
    id: s
    visible: false

    property real target: 0
    property real value: 0
    property real velocity: 0
    property real omega: 22
    property real zeta: 0.8
    property bool animated: true
    property real omegaUp: 0
    property real zetaUp: 0.8
    property real omegaDown: 0
    property real zetaDown: 0.8
    property bool active: false

    onTargetChanged: {
        if (!animated) { snapToTarget(); return }
        if (omegaUp > 0) {
            var up = target >= value
            omega = up ? omegaUp : (omegaDown > 0 ? omegaDown : omegaUp)
            zeta = up ? zetaUp : zetaDown
        }
        active = true
    }

    function snapToTarget() { value = target; velocity = 0; active = false }
    function snap(v) { value = v; velocity = 0; target = v; active = false }

    function step(dt) {
        dt = Math.min(dt, 0.05)
        var n = Math.max(1, Math.ceil(dt / 0.004))
        var h = dt / n
        var x = value, v = velocity
        var w2 = omega * omega, c = 2 * zeta * omega
        for (var i = 0; i < n; i++) {
            v += (-w2 * (x - target) - c * v) * h
            x += v * h
        }
        if (Math.abs(x - target) < 0.0005 && Math.abs(v) < 0.01) { x = target; v = 0; active = false }
        value = x
        velocity = v
    }

    FrameAnimation { running: s.active; onTriggered: s.step(frameTime) }
}
