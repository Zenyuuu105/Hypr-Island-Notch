import QtQuick
import qs
import ".."

Row {
    id: root

    property string timeText: ""
    property color textColor: Theme.shellForeground
    property int textSize: 16
    property string clockFont: Theme.fontFamily

    spacing: 0
    height: textSize * 1.35

    Repeater {
        model: root.timeText.split("")

        delegate: Item {
            id: digitCell

            required property int index
            required property string modelData

            readonly property string character: modelData
            readonly property bool isDigit: /^[0-9]$/.test(character)

            width: isDigit ? textSize * 0.62 : character === " " ? textSize * 0.22 : character === ":" ? textSize * 0.35 : textSize * 0.78
            height: root.height
            clip: true

            Text {
                id: staticCharacter
                anchors.centerIn: parent
                text: digitCell.character
                color: root.textColor
                font.family: root.clockFont
                font.pixelSize: root.textSize
                font.weight: Font.Bold
                visible: !digitCell.isDigit
            }

            Item {
                anchors.fill: parent
                clip: true
                visible: digitCell.isDigit

                Column {
                    id: digitStrip
                    y: -Number(digitCell.character) * height / 10
                    width: parent.width
                    height: parent.height * 10

                    Repeater {
                        model: 10

                        delegate: Text {
                            required property int index

                            width: digitStrip.width
                            height: digitCell.height
                            text: index
                            color: root.textColor
                            font.family: root.clockFont
                            font.pixelSize: root.textSize
                            font.weight: Font.Bold
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }

                    Behavior on y {
                        SpringAnim {}
                    }
                }
            }
        }
    }
}
