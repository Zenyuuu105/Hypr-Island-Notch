import QtQuick
import QtQuick.Layouts

Item {
    id: root
    implicitWidth: 420
    implicitHeight: col.implicitHeight + 24

    property string workspaceName: "Desktop"
    property string trackTitle: ""
    property string trackArtist: ""
    property url artUrl: ""
    property string notifText: "All caught up"

    ColumnLayout {
        id: col
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        // Clock + date
        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 0
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: Qt.formatTime(new Date(), "hh:mm")
                color: "white"; font.pixelSize: 20; font.weight: Font.DemiBold
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: Qt.formatDate(new Date(), "ddd, MMM d")
                color: "#9aa0a6"; font.pixelSize: 11
            }
        }

        // Three columns
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            // Left: workspace
            RowLayout {
                Layout.preferredWidth: 110
                spacing: 6
                Text { text: "󰍹"; color: "white"; font.pixelSize: 14 }
                Text { text: root.workspaceName; color: "white"; font.pixelSize: 12 }
            }

            // Center: media
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 44
                radius: 12
                color: "#1c1c1e"
                RowLayout {
                    anchors.fill: parent; anchors.margins: 6; spacing: 8
                    Image {
                        Layout.preferredWidth: 32; Layout.preferredHeight: 32
                        source: root.artUrl; fillMode: Image.PreserveAspectCrop
                    }
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 0
                        Text { text: root.trackTitle; color: "white"; font.pixelSize: 12; elide: Text.ElideRight; Layout.fillWidth: true }
                        Text { text: root.trackArtist; color: "#9aa0a6"; font.pixelSize: 10; elide: Text.ElideRight; Layout.fillWidth: true }
                    }
                }
            }

            // Right: notifications
            RowLayout {
                Layout.preferredWidth: 110
                Layout.alignment: Qt.AlignRight
                spacing: 6
                Text { text: root.notifText; color: "white"; font.pixelSize: 12 }
                Text { text: "󰂚"; color: "white"; font.pixelSize: 14 }
            }
        }
    }
}
