import QtQuick

Canvas {
    id: bell

    property color tint: "#8a8f98"

    width: 12
    height: 14
    onTintChanged: requestPaint()

    onPaint: {
        var ctx = getContext("2d");
        ctx.reset();
        ctx.lineWidth = 1.4;
        ctx.lineCap = "round";
        ctx.lineJoin = "round";
        ctx.strokeStyle = tint;
        ctx.beginPath();
        ctx.arc(6, 5.5, 3.4, Math.PI, 0, false);
        ctx.lineTo(9.4, 9.4);
        ctx.lineTo(10.6, 10.8);
        ctx.lineTo(1.4, 10.8);
        ctx.lineTo(2.6, 9.4);
        ctx.closePath();
        ctx.stroke();
        ctx.beginPath();
        ctx.arc(6, 12.4, 1.2, 0, Math.PI, false);
        ctx.stroke();
        ctx.beginPath();
        ctx.moveTo(6, 1.4);
        ctx.lineTo(6, 2.2);
        ctx.stroke();
    }
}
