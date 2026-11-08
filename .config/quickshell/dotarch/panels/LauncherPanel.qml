import "../Expression.js" as Expression
import QtQuick
import Quickshell
import Quickshell.Widgets
import qs
import qs.components
import ".."

FocusScope {
    id: root

    property int selectedIndex: 0
    readonly property var answer: Expression.evaluate(searchInput.text)
    readonly property bool hasAnswer: answer !== null

    function takeInitialFocus() {
        searchInput.forceActiveFocus(Qt.TabFocusReason);
    }

    function moveSelection(offset) {
        const count = filteredApps.values.length;
        if (count === 0) {
            selectedIndex = 0;
            return;
        }
        selectedIndex = Math.max(0, Math.min(count - 1, selectedIndex + offset));
        results.positionViewAtIndex(selectedIndex, ListView.Contain);
    }

    function resetSelection() {
        selectedIndex = 0;
        Qt.callLater(() => results.positionViewAtBeginning());
    }

    Connections {
        function onPanelChanged() {
            if (ShellState.panel !== "launcher") {
                searchInput.clear();
                root.resetSelection();
            }
        }
        target: ShellState
    }

    function activateSelection() {
        if (hasAnswer) {
            Quickshell.clipboardText = String(answer);
            ShellState.close();
            return;
        }
        const values = filteredApps.values;
        if (values.length > 0) {
            values[Math.max(0, Math.min(selectedIndex, values.length - 1))].execute();
            ShellState.close();
        }
    }

    // Force strict dimensions for a horizontal rectangle shape
    width: 560 
    implicitWidth: 560
    implicitHeight: content.implicitHeight + 24

    Column {
        id: content
        y: 12
        width: parent.width
        spacing: 6

        // Search Bar 
        Item {
            width: parent.width
            height: 48

            ShellText {
                id: searchIcon
                anchors.left: parent.left
                anchors.leftMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                text: ""
                color: Theme.muted
                font.pixelSize: 16
            }

            TextInput {
                id: searchInput
                anchors.left: searchIcon.right
                anchors.leftMargin: 12
                anchors.right: parent.right
                anchors.rightMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.foreground
                font.family: Theme.fontFamily
                font.pixelSize: 15
                clip: true
                selectByMouse: true
                activeFocusOnTab: true
                selectionColor: Theme.primaryContainer

                onTextChanged: root.resetSelection()
                Keys.onDownPressed: root.moveSelection(1)
                Keys.onUpPressed: root.moveSelection(-1)
                Keys.onReturnPressed: root.activateSelection()
                Keys.onEnterPressed: root.activateSelection()
                Keys.onEscapePressed: ShellState.close()

                ShellText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Search..."
                    color: Theme.mutedDark
                    visible: !parent.text
                    font.pixelSize: 15
                }
            }
            
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                height: 1
                color: Theme.bg1 
            }
        }

        // Calculator Result Area
        Rectangle {
            width: parent.width - 24
            anchors.horizontalCenter: parent.horizontalCenter
            height: root.hasAnswer ? 64 : 0
            radius: Theme.radiusSmall
            color: Theme.primaryContainer
            opacity: root.hasAnswer ? 1 : 0
            clip: true

            Column {
                anchors.left: parent.left
                anchors.leftMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                ShellText {
                    text: String(searchInput.text).replace(/\*/g, "×").replace(/\//g, "÷")
                    color: Theme.muted
                    font.pixelSize: 12
                }

                ShellText {
                    text: root.hasAnswer ? String(root.answer) : ""
                    color: Theme.primary
                    font.pixelSize: 31
                    font.weight: Font.Bold
                }
            }

            Behavior on height { SpringAnim {} }
            Behavior on opacity { NumberAnimation { duration: Theme.animationFast } }
        }

        // Applications List View
        ListView {
            id: results
            width: parent.width
            // Max 4 items visible so the launcher stays horizontal rather than long/vertical
            height: Math.min(4, count) * 58
            spacing: 2
            clip: true
            interactive: contentHeight > height

            model: ScriptModel {
                id: filteredApps
                values: DesktopEntries.applications.values.filter((entry) => {
                    if (entry.noDisplay) return false;
                    const query = searchInput.text.toLowerCase();
                    const name = String(entry.name || "").toLowerCase();
                    const genericName = String(entry.genericName || "").toLowerCase();
                    const keywords = entry.keywords ? entry.keywords.join(" ").toLowerCase() : "";
                    return !query || name.includes(query) || genericName.includes(query) || keywords.includes(query);
                }).sort((left, right) => {
                    const leftName = String(left.name || "").toLowerCase();
                    const rightName = String(right.name || "").toLowerCase();
                    if (leftName < rightName) return -1;
                    if (leftName > rightName) return 1;
                    return String(left.name || "").localeCompare(String(right.name || ""));
                })
            }

            delegate: Item {
                required property var modelData
                required property int index

                width: results.width
                height: 58
                
                // Separate the "brick" logic (isSelected) from the background logic (isHovered)
                property bool isSelected: index === root.selectedIndex && !root.hasAnswer
                property bool isHovered: itemMouseArea.containsMouse

                // Background Highlight Box - Triggers on BOTH hover and selection
                Rectangle {
                    id: highlightBox
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    anchors.topMargin: 1
                    anchors.bottomMargin: 1
                    radius: 12
                    color: (parent.isSelected || parent.isHovered) ? Qt.alpha(Theme.shellForeground, 0.07) : "transparent"
                    
                    Behavior on color {
                        ColorAnimation { duration: Theme.animationFast }
                    }

                    // Accent Line ("The Brick") - Triggers ONLY on keyboard selection
                    Rectangle {
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        width: 3
                        height: 20
                        radius: 1.5
                        color: Theme.primary
                        opacity: parent.parent.isSelected ? 1 : 0 
                        
                        Behavior on opacity {
                            NumberAnimation { duration: Theme.animationFast }
                        }
                    }

                    Item {
                        id: iconWrapper
                        anchors.left: parent.left
                        anchors.leftMargin: 26
                        anchors.verticalCenter: parent.verticalCenter
                        width: 32
                        height: 32

                        IconImage {
                            anchors.centerIn: parent
                            implicitSize: 30
                            source: Quickshell.iconPath(modelData.icon, "application-x-executable")
                        }
                    }

                    Column {
                        anchors.left: iconWrapper.right
                        anchors.leftMargin: 14
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        ShellText {
                            width: parent.width
                            text: modelData.name
                            elide: Text.ElideRight
                            color: Theme.foreground
                            font.pixelSize: 14
                            font.weight: Font.DemiBold
                        }

                        ShellText {
                            width: parent.width
                            text: modelData.genericName || modelData.comment || "Application"
                            elide: Text.ElideRight
                            color: Theme.muted
                            font.pixelSize: 11
                        }
                    }
                }

                MouseArea {
                    id: itemMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    // Removed the code that forced the index (and brick) to follow the mouse
                    onClicked: {
                        modelData.execute();
                        ShellState.close();
                    }
                }
            }
        }
    }
}