import QtQuick
import QtQuick.Layouts
import "ui/Singletons"

// Scrolling shell for the cursor and font page, so nothing is cut off.
Flickable {
    id: scroller

    clip: true
    contentWidth: width
    contentHeight: content.implicitHeight + Tokens.s5
    boundsBehavior: Flickable.StopAtBounds
    flickableDirection: Flickable.VerticalFlick

    CursorFontContent {
        id: content
        width: scroller.width
    }

    WheelHandler {
        target: null
        onWheel: event => {
            const max = Math.max(0, scroller.contentHeight - scroller.height)
            scroller.contentY = Math.max(0, Math.min(max, scroller.contentY - event.angleDelta.y * 0.5))
        }
    }
}
