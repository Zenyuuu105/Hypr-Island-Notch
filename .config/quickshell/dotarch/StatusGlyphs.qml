import QtQuick

Row {
    id: statusRow
    spacing: 10

    property int wifiStrength: 82
    property int batteryPercent: 80
    property bool isCharging: false
    property color iconColor: "#cdd6f4"
    property color accentColor: "#89b4fa"
    property color chargingColor: "#a6e3a1"

    Canvas {
        id: wifiCanvas
        width: 20
        height: 18
        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            var cx = width / 2;
            var cy = height - 3;
            var radii = [4, 8, 12];
            var thresholds = [15, 45, 75];

            ctx.fillStyle = statusRow.wifiStrength > 0 ? statusRow.accentColor : Qt.alpha(statusRow.iconColor, 0.3);
            ctx.beginPath();
            ctx.arc(cx, cy, 1.8, 0, Math.PI * 2);
            ctx.fill();

            ctx.lineWidth = 1.8;
            ctx.lineCap = "round";
            for (var i = 0; i < 3; i++) {
                ctx.strokeStyle = (statusRow.wifiStrength >= thresholds[i])
                    ? statusRow.accentColor
                    : Qt.alpha(statusRow.iconColor, 0.25);
                ctx.beginPath();
                ctx.arc(cx, cy, radii[i], Math.PI * 1.25, Math.PI * 1.75);
                ctx.stroke();
            }
        }
        Connections {
            target: statusRow
            function onWifiStrengthChanged() { wifiCanvas.requestPaint() }
            function onAccentColorChanged() { wifiCanvas.requestPaint() }
        }
    }

    Item {
        width: 38
        height: 18

        Rectangle {
            id: battBody
            width: 34
            height: 18
            radius: 5
            color: "transparent"
            border.width: 1.5
            border.color: statusRow.isCharging ? statusRow.chargingColor : statusRow.iconColor

            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.margins: 2.5
                radius: 3
                width: Math.max(4, (parent.width - 5) * (statusRow.batteryPercent / 100.0))
                color: statusRow.isCharging ? statusRow.chargingColor : statusRow.accentColor

                Behavior on width {
                    SpringAnim {}
                }
            }

            Text {
                anchors.centerIn: parent
                text: statusRow.isCharging ? "⚡" + statusRow.batteryPercent : String(statusRow.batteryPercent)
                font.pixelSize: 13
                font.bold: true
                color: "#11111b"
            }
        }

        Rectangle {
            anchors.left: battBody.right
            anchors.leftMargin: 1.5
            anchors.verticalCenter: battBody.verticalCenter
            width: 2.5
            height: 7
            radius: 1
            color: statusRow.isCharging ? statusRow.chargingColor : statusRow.iconColor
        }
    }
}
