import QtQuick
import qs
import qs.components

FocusScope {
    id: root

    property string currentView: "all"
    property string editingId: ""
    property string detailsId: ""
    property bool confirmClearAll: false
    property bool schedBad: false
    property string searchQuery: ""
    property string sortMode: "manual"
    property bool textEditorActive: todoInput.activeFocus || schedInput.activeFocus || categoryInput.activeFocus || dateInput.activeFocus || notesInput.activeFocus || searchInput.activeFocus || editingId !== ""
    readonly property string today: ShellState.todayKey()
    readonly property string tomorrow: ShellState.tomorrowKey()
    readonly property var visibleTodos: filterTodos(ShellState.todos)
    readonly property int detailsIndex: sourceIndexForId(detailsId)
    readonly property var detailsTask: detailsIndex >= 0 ? ShellState.todos[detailsIndex] : null

    function cycleSort() {
        const modes = ["manual", "due", "priority"];
        sortMode = modes[(modes.indexOf(sortMode) + 1) % modes.length];
    }

    function isoDate(d) {
        const m = d.getMonth() + 1;
        const day = d.getDate();
        return d.getFullYear().toString() + "-" + (m < 10 ? "0" : "") + m + "-" + (day < 10 ? "0" : "") + day;
    }

    function shiftDate(days) {
        if (!detailsTask)
            return;
        const parts = (detailsTask.dueDate || today).split("-");
        const d = new Date(Number(parts[0]), Number(parts[1]) - 1, Number(parts[2]) + days);
        ShellState.updateTodo(detailsIndex, { "dueDate": isoDate(d) });
    }

    function takeInitialFocus() {
        todoInput.forceActiveFocus(Qt.TabFocusReason);
    }

    function addTodo() {
        let date = "";
        if (currentView === "today") {
            date = today;
        } else if (currentView === "tomorrow") {
            date = tomorrow;
        } else if (currentView === "scheduled") {
            const typed = schedInput.text.trim();
            date = typed ? parseDisplayDate(typed) : tomorrow;
            if (!date) {
                schedBad = true;
                return;
            }
        }
        const before = {};
        for (let i = 0; i < ShellState.todos.length; i++)
            before[ShellState.todos[i].id] = true;
        ShellState.addTodo(todoInput.text);
        if (date) {
            for (let i = 0; i < ShellState.todos.length; i++) {
                const t = ShellState.todos[i];
                if (!before[t.id] && !t.dueDate) {
                    ShellState.updateTodo(i, { "dueDate": date });
                    break;
                }
            }
        }
        todoInput.clear();
        schedInput.clear();
    }

    function filterTodos(todos) {
        const result = [];
        for (let i = 0; i < todos.length; i++) {
            const task = todos[i];
            const due = task.dueDate || "";
            if (currentView === "today" && (!due || due > today))
                continue;
            if (currentView === "tomorrow" && due !== tomorrow)
                continue;
            if (currentView === "scheduled" && !due)
                continue;
            if (searchQuery) {
                const haystack = (task.text + " " + (task.category || "") + " " + (task.notes || "")).toLowerCase();
                if (haystack.indexOf(searchQuery.toLowerCase()) < 0)
                    continue;
            }
            result.push({
                "sourceIndex": i,
                "task": task
            });
        }
        if (sortMode !== "manual") {
            const rank = { "high": 3, "medium": 2, "low": 1 };
            result.sort((a, b) => {
                if (sortMode === "due") {
                    const ad = a.task.dueDate || "9999-99-99";
                    const bd = b.task.dueDate || "9999-99-99";
                    if (ad !== bd)
                        return ad < bd ? -1 : 1;
                } else {
                    const ar = rank[a.task.priority] || 0;
                    const br = rank[b.task.priority] || 0;
                    if (ar !== br)
                        return br - ar;
                }
                return a.sourceIndex - b.sourceIndex;
            });
        }
        return result;
    }

    function sourceIndexForId(id) {
        if (!id)
            return -1;
        for (let i = 0; i < ShellState.todos.length; i++) {
            if (ShellState.todos[i].id === id)
                return i;
        }
        return -1;
    }

    function selectRow(index) {
        if (visibleTodos.length === 0) {
            taskList.currentIndex = -1;
            return;
        }
        taskList.currentIndex = Math.max(0, Math.min(visibleTodos.length - 1, index));
        taskList.positionViewAtIndex(taskList.currentIndex, ListView.Contain);
        const item = taskList.itemAtIndex(taskList.currentIndex);
        if (item)
            item.forceActiveFocus(Qt.OtherFocusReason);
    }

    function moveSelection(offset) {
        selectRow((taskList.currentIndex < 0 ? (offset > 0 ? -1 : visibleTodos.length) : taskList.currentIndex) + offset);
    }

    function moveView(offset) {
        const views = ["all", "today", "tomorrow", "scheduled"];
        const current = Math.max(0, views.indexOf(currentView));
        setView(views[(current + offset + views.length) % views.length]);
    }

    function setView(view) {
        currentView = view;
        detailsId = "";
        editingId = "";
        Qt.callLater(() => {
            if (visibleTodos.length > 0)
                selectRow(0);
            else
                root.forceActiveFocus(Qt.OtherFocusReason);
        });
    }

    function toggleSelected() {
        if (taskList.currentIndex < 0 || taskList.currentIndex >= visibleTodos.length)
            return;
        ShellState.toggleTodo(visibleTodos[taskList.currentIndex].sourceIndex);
    }

    function reorderSelected(offset) {
        if (sortMode !== "manual" || searchQuery)
            return;
        const current = taskList.currentIndex;
        const target = current + offset;
        if (current < 0 || target < 0 || target >= visibleTodos.length)
            return;
        ShellState.swapTodos(visibleTodos[current].sourceIndex, visibleTodos[target].sourceIndex);
        Qt.callLater(() => selectRow(target));
    }

    function beginEditing(id) {
        detailsId = "";
        editingId = id;
    }

    function showDetails(id) {
        editingId = "";
        detailsId = detailsId === id ? "" : id;
    }

    function priorityColor(priority) {
        if (priority === "high")
            return Theme.red;
        if (priority === "medium")
            return Theme.yellow;
        if (priority === "low")
            return Theme.blue;
        return Theme.bg3;
    }

    function dueLabel(dueDate) {
        if (!dueDate)
            return "";
        return displayDate(dueDate);
    }

    function displayDate(isoDate) {
        const parts = String(isoDate || "").split("-");
        if (parts.length !== 3)
            return "";
        return parts[2] + "-" + parts[1] + "-" + parts[0].slice(-2);
    }

    function parseDisplayDate(displayDate) {
        const match = String(displayDate || "").trim().match(/^(\d{2})-(\d{2})-(\d{2})$/);
        if (!match)
            return "";
        const day = Number(match[1]);
        const month = Number(match[2]);
        const year = 2000 + Number(match[3]);
        const candidate = new Date(year, month - 1, day);
        if (candidate.getFullYear() !== year || candidate.getMonth() !== month - 1 || candidate.getDate() !== day)
            return "";
        return year.toString() + "-" + match[2] + "-" + match[1];
    }

    function cyclePriority() {
        if (!detailsTask)
            return;
        const priorities = ["none", "low", "medium", "high"];
        const current = Math.max(0, priorities.indexOf(detailsTask.priority || "none"));
        ShellState.updateTodo(detailsIndex, {
            "priority": priorities[(current + 1) % priorities.length]
        });
    }

    implicitWidth: 392
    implicitHeight: content.implicitHeight

    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Slash && !root.textEditorActive) {
            todoInput.forceActiveFocus(Qt.ShortcutFocusReason);
            event.accepted = true;
        } else if (!root.textEditorActive && event.key === Qt.Key_Up && (event.modifiers & Qt.ControlModifier)) {
            root.reorderSelected(-1);
            event.accepted = true;
        } else if (!root.textEditorActive && event.key === Qt.Key_Down && (event.modifiers & Qt.ControlModifier)) {
            root.reorderSelected(1);
            event.accepted = true;
        } else if (!root.textEditorActive && event.key === Qt.Key_Left) {
            root.moveView(-1);
            event.accepted = true;
        } else if (!root.textEditorActive && event.key === Qt.Key_Right) {
            root.moveView(1);
            event.accepted = true;
        } else if (!root.textEditorActive && (event.key === Qt.Key_Down || event.key === Qt.Key_J)) {
            root.moveSelection(1);
            event.accepted = true;
        } else if (!root.textEditorActive && (event.key === Qt.Key_Up || event.key === Qt.Key_K)) {
            root.moveSelection(-1);
            event.accepted = true;
        } else if (!root.textEditorActive && event.key === Qt.Key_Space) {
            root.toggleSelected();
            event.accepted = true;
        } else if (!root.textEditorActive && event.key === Qt.Key_E && taskList.currentIndex >= 0) {
            root.beginEditing(root.visibleTodos[taskList.currentIndex].task.id);
            event.accepted = true;
        } else if (!root.textEditorActive && event.key === Qt.Key_D && taskList.currentIndex >= 0) {
            root.showDetails(root.visibleTodos[taskList.currentIndex].task.id);
            event.accepted = true;
        }
    }

    onVisibleTodosChanged: {
        if (visibleTodos.length === 0)
            taskList.currentIndex = -1;
        else if (taskList.currentIndex >= visibleTodos.length)
            taskList.currentIndex = visibleTodos.length - 1;
    }

    Column {
        id: content

        width: parent.width
        spacing: 14

        Item {
            width: parent.width
            height: 36

            ShellText {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: "Todo"
                font.pixelSize: 19
                font.weight: Font.Bold
            }

        }

        Row {
            width: parent.width
            height: 42
            spacing: 0

            Item {
                width: parent.width - (schedBox.visible ? schedBox.width : 0)
                height: parent.height

                TextInput {
                    id: todoInput

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    leftPadding: 2
                    rightPadding: 2
                    color: Theme.foreground
                    selectionColor: Theme.primaryContainer
                    selectedTextColor: Theme.foreground
                    font.family: Theme.fontFamily
                    font.pixelSize: 15
                    activeFocusOnTab: true
                    Keys.onReturnPressed: root.addTodo()
                    Keys.onEnterPressed: root.addTodo()
                    Keys.onDownPressed: root.moveSelection(1)

                    ShellText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Add task…  !high  #category  today"
                        color: Theme.mutedDark
                        visible: !parent.text
                        font.pixelSize: 13
                    }
                }

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: todoInput.activeFocus ? 2 : 1
                    color: todoInput.activeFocus ? Theme.primary : Theme.bg3
                }
            }

            Item {
                id: schedBox

                width: 96
                height: parent.height
                visible: root.currentView === "scheduled"

                TextInput {
                    id: schedInput

                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    color: root.schedBad ? Theme.red : Theme.foreground
                    selectionColor: Theme.primaryContainer
                    selectedTextColor: Theme.foreground
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    activeFocusOnTab: true
                    onTextChanged: root.schedBad = false
                    Keys.onReturnPressed: root.addTodo()
                    Keys.onEnterPressed: root.addTodo()

                    ShellText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "DD-MM-YY"
                        visible: !parent.text
                        color: Theme.mutedDark
                        font.pixelSize: 12
                    }
                }

                Rectangle {
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: schedInput.activeFocus ? 2 : 1
                    color: root.schedBad ? Theme.red : (schedInput.activeFocus ? Theme.primary : Theme.bg3)
                }
            }

        }

        Row {
            id: viewTabs

            width: parent.width
            height: 32
            spacing: 22

            Repeater {
                model: [
                    { "key": "all", "label": "All" },
                    { "key": "today", "label": "Today" },
                    { "key": "tomorrow", "label": "Tomorrow" },
                    { "key": "scheduled", "label": "Scheduled" }
                ]

                delegate: Item {
                    required property var modelData

                    width: tabLabel.implicitWidth
                    height: viewTabs.height

                    ShellText {
                        id: tabLabel

                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.label
                        color: root.currentView === modelData.key ? Theme.foreground : Theme.muted
                        font.pixelSize: 13
                        font.weight: root.currentView === modelData.key ? Font.Bold : Font.Normal
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: 2
                        color: Theme.primary
                        visible: root.currentView === modelData.key
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.setView(modelData.key)
                    }
                }
            }

            Item { width: 1; height: 1 }

            ShellText {
                anchors.verticalCenter: parent.verticalCenter
                text: root.visibleTodos.length.toString()
                color: Theme.mutedDark
                font.pixelSize: 12
            }
        }

        Item {
            width: parent.width
            height: 26

            TextInput {
                id: searchInput

                anchors.left: parent.left
                anchors.right: sortLabel.left
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.foreground
                selectionColor: Theme.primaryContainer
                selectedTextColor: Theme.foreground
                font.family: Theme.fontFamily
                font.pixelSize: 13
                clip: true
                onTextChanged: root.searchQuery = text
                Keys.onDownPressed: root.moveSelection(1)
                Keys.onEscapePressed: (event) => {
                    clear();
                    root.forceActiveFocus(Qt.OtherFocusReason);
                    event.accepted = true;
                }

                ShellText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Search…"
                    color: Theme.mutedDark
                    visible: !parent.text
                    font.pixelSize: 12
                }
            }

            Rectangle {
                anchors.left: parent.left
                anchors.right: searchInput.right
                anchors.bottom: parent.bottom
                height: searchInput.activeFocus ? 2 : 1
                color: searchInput.activeFocus ? Theme.primary : Theme.bg3
            }

            ShellText {
                id: sortLabel

                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: "Sort: " + (root.sortMode === "due" ? "due date" : root.sortMode === "priority" ? "priority" : "manual")
                color: root.sortMode === "manual" ? Theme.muted : Theme.primary
                font.pixelSize: 12

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -5
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.cycleSort()
                }
            }
        }

        ListView {
            id: taskList

            width: parent.width
            height: count > 0 ? Math.min(6, count) * 46 : 64
            clip: true
            interactive: count > 6
            boundsBehavior: Flickable.StopAtBounds
            currentIndex: count > 0 ? 0 : -1
            model: root.visibleTodos

            onCurrentIndexChanged: {
                if (root.detailsId && currentIndex >= 0 && currentIndex < root.visibleTodos.length)
                    root.detailsId = root.visibleTodos[currentIndex].task.id;
            }

            ShellText {
                anchors.centerIn: parent
                visible: taskList.count === 0
                text: root.currentView === "all" ? "Nothing here — nice." : "No tasks in this view."
                color: Theme.mutedDark
                font.pixelSize: 13
            }

            delegate: FocusScope {
                id: taskRow

                required property var modelData
                required property int index
                readonly property var task: modelData.task
                readonly property bool selected: taskList.currentIndex === index

                function saveTitle() {
                    const clean = editInput.text.trim();
                    if (clean)
                        ShellState.updateTodo(modelData.sourceIndex, { "text": clean });
                    root.editingId = "";
                    forceActiveFocus(Qt.OtherFocusReason);
                }

                width: ListView.view.width
                height: 46
                activeFocusOnTab: true

                Keys.onReturnPressed: root.showDetails(task.id)
                Keys.onEnterPressed: root.showDetails(task.id)

                onActiveFocusChanged: {
                    if (activeFocus)
                        taskList.currentIndex = index;
                }

                Rectangle {
                    anchors.fill: parent
                    radius: Theme.radiusSmall
                    color: taskRow.selected ? Theme.primaryContainer : "transparent"
                }

                Connections {
                    target: root
                    function onEditingIdChanged() {
                        if (root.editingId === taskRow.task.id)
                            Qt.callLater(() => editInput.forceActiveFocus(Qt.OtherFocusReason));
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        taskList.currentIndex = index;
                        taskRow.forceActiveFocus(Qt.MouseFocusReason);
                    }
                    onDoubleClicked: root.beginEditing(taskRow.task.id)
                }

                Rectangle {
                    id: checkbox

                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    width: 18
                    height: 18
                    radius: 5
                    color: taskRow.task.done ? Theme.primary : "transparent"
                    border.width: 1
                    border.color: taskRow.task.done ? Theme.primary : Theme.mutedDark

                    ShellText {
                        anchors.centerIn: parent
                        text: taskRow.task.done ? "✓" : ""
                        color: Theme.bgDim
                        font.pixelSize: 11
                        font.weight: Font.Bold
                    }

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -6
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            taskList.currentIndex = taskRow.index;
                            ShellState.toggleTodo(taskRow.modelData.sourceIndex);
                        }
                    }
                }

                TextInput {
                    id: editInput

                    anchors.left: priorityDot.right
                    anchors.leftMargin: 12
                    anchors.right: metadata.left
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    visible: root.editingId === taskRow.task.id
                    text: taskRow.task.text
                    color: Theme.foreground
                    selectionColor: Theme.primaryContainer
                    selectedTextColor: Theme.foreground
                    font.family: Theme.fontFamily
                    font.pixelSize: 15
                    Keys.onReturnPressed: taskRow.saveTitle()
                    Keys.onEnterPressed: taskRow.saveTitle()
                    Keys.onEscapePressed: (event) => {
                        root.editingId = "";
                        taskRow.forceActiveFocus(Qt.OtherFocusReason);
                        event.accepted = true;
                    }
                }

                ShellText {
                    anchors.left: priorityDot.right
                    anchors.leftMargin: 12
                    anchors.right: metadata.left
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    visible: root.editingId !== taskRow.task.id
                    text: taskRow.task.text
                    color: taskRow.task.done ? Theme.mutedDark : Theme.foreground
                    font.strikeout: taskRow.task.done
                    elide: Text.ElideRight
                    font.pixelSize: 15
                }

                Rectangle {
                    id: priorityDot

                    anchors.left: checkbox.right
                    anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    width: 5
                    height: 5
                    radius: 3
                    color: taskRow.task.priority && taskRow.task.priority !== "none" ? root.priorityColor(taskRow.task.priority) : "transparent"
                }

                Row {
                    id: metadata

                    anchors.right: detailsButton.left
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 10

                    ShellText {
                        visible: !!taskRow.task.category
                        text: "#" + (taskRow.task.category || "")
                        color: Theme.blue
                        font.pixelSize: 12
                    }

                    ShellText {
                        visible: !!taskRow.task.dueDate
                        text: root.dueLabel(taskRow.task.dueDate || "")
                        color: taskRow.task.dueDate < root.today ? Theme.red : Theme.muted
                        font.pixelSize: 12
                    }
                }

                Item {
                    id: detailsButton

                    anchors.right: parent.right
                    width: 26
                    height: parent.height

                    ShellText {
                        anchors.centerIn: parent
                        text: root.detailsId === taskRow.task.id ? "⌄" : "›"
                        color: taskRow.selected ? Theme.primary : Theme.mutedDark
                        font.pixelSize: 17
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            const wasOpenForThisTask = root.detailsId === taskRow.task.id;
                            taskList.currentIndex = taskRow.index;
                            root.detailsId = wasOpenForThisTask ? "" : taskRow.task.id;
                        }
                    }
                }
            }
        }

        Column {
            id: detailsPane

            width: parent.width
            spacing: 12
            visible: root.detailsTask !== null

            Row {
                width: parent.width
                height: 30
                spacing: 8

                ShellText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "DETAILS"
                    color: Theme.muted
                    font.pixelSize: 12
                    font.weight: Font.Bold
                }

                Item { width: parent.width - 150; height: 1 }

                ShellText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Delete"
                    color: Theme.red
                    font.pixelSize: 12

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -7
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            ShellState.removeTodo(root.detailsIndex);
                            root.detailsId = "";
                        }
                    }
                }

                ShellText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Close"
                    color: Theme.muted
                    font.pixelSize: 12

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -7
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.detailsId = ""
                    }
                }
            }

            Row {
                width: parent.width
                height: 36
                spacing: 12

                FocusScope {
                    id: priorityButton

                    width: 105
                    height: parent.height
                    activeFocusOnTab: true
                    Keys.onReturnPressed: root.cyclePriority()
                    Keys.onEnterPressed: root.cyclePriority()
                    Keys.onSpacePressed: root.cyclePriority()

                    Rectangle {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        width: 6
                        height: 6
                        radius: 3
                        color: root.detailsTask ? root.priorityColor(root.detailsTask.priority) : Theme.bg3
                    }

                    ShellText {
                        anchors.left: parent.left
                        anchors.leftMargin: 13
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Priority: " + (root.detailsTask ? (root.detailsTask.priority || "none") : "none")
                        color: priorityButton.activeFocus ? Theme.foreground : Theme.muted
                        font.pixelSize: 12
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.cyclePriority()
                    }
                }

                Item {
                    width: parent.width - 117
                    height: parent.height

                    ShellText {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: "#"
                        color: Theme.blue
                        font.pixelSize: 13
                    }

                    TextInput {
                        id: categoryInput

                        anchors.left: parent.left
                        anchors.leftMargin: 13
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.detailsTask ? (root.detailsTask.category || "") : ""
                        color: Theme.foreground
                        selectionColor: Theme.primaryContainer
                        selectedTextColor: Theme.foreground
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                        activeFocusOnTab: true
                        onEditingFinished: {
                            if (root.detailsIndex >= 0)
                                ShellState.updateTodo(root.detailsIndex, { "category": text.trim().replace(/^#/, "") });
                        }
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.leftMargin: 13
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: categoryInput.activeFocus ? 2 : 1
                        color: categoryInput.activeFocus ? Theme.blue : Theme.bg3
                    }
                }
            }

            Row {
                width: parent.width
                height: 36
                spacing: 10

                Repeater {
                    model: [
                        { "label": "Today", "date": root.today },
                        { "label": "Tomorrow", "date": root.tomorrow },
                        { "label": "Clear", "date": "" }
                    ]

                    delegate: ShellText {
                        required property var modelData

                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.label
                        color: root.detailsTask && root.detailsTask.dueDate === modelData.date ? Theme.primary : Theme.muted
                        font.pixelSize: 12

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -5
                            cursorShape: Qt.PointingHandCursor
                            onClicked: ShellState.updateTodo(root.detailsIndex, { "dueDate": modelData.date })
                        }
                    }
                }

                Item { width: 12; height: 1 }

                TextInput {
                    id: dateInput

                    width: 82
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.detailsTask ? root.displayDate(root.detailsTask.dueDate || "") : ""
                    color: Theme.foreground
                    selectionColor: Theme.primaryContainer
                    selectedTextColor: Theme.foreground
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    activeFocusOnTab: true
                    onEditingFinished: {
                        const clean = text.trim();
                        const parsed = root.parseDisplayDate(clean);
                        if (root.detailsIndex >= 0 && (!clean || parsed))
                            ShellState.updateTodo(root.detailsIndex, { "dueDate": clean ? parsed : "" });
                    }

                    ShellText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "DD-MM-YY"
                        visible: !parent.text
                        color: Theme.mutedDark
                        font.pixelSize: 12
                    }
                }

                ShellText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "‹"
                    color: Theme.muted
                    font.pixelSize: 17

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -6
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.shiftDate(-1)
                    }
                }

                ShellText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "›"
                    color: Theme.muted
                    font.pixelSize: 17

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -6
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.shiftDate(1)
                    }
                }

                ShellText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "+7d"
                    color: Theme.muted
                    font.pixelSize: 12

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -6
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.shiftDate(7)
                    }
                }
            }

            Item {
                width: parent.width
                height: 84

                ShellText {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    text: "Notes"
                    color: Theme.mutedDark
                    font.pixelSize: 12
                }

                TextEdit {
                    id: notesInput

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.topMargin: 15
                    anchors.bottom: parent.bottom
                    text: root.detailsTask ? (root.detailsTask.notes || "") : ""
                    color: Theme.foreground
                    selectionColor: Theme.primaryContainer
                    selectedTextColor: Theme.foreground
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    wrapMode: TextEdit.Wrap
                    activeFocusOnTab: true
                    onActiveFocusChanged: {
                        if (!activeFocus && root.detailsIndex >= 0)
                            ShellState.updateTodo(root.detailsIndex, { "notes": text.trim() });
                    }
                }

            }
        }

        Item {
            width: parent.width
            height: 24
            visible: root.detailsTask === null && ShellState.todos.length > 0

            ShellText {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: root.confirmClearAll ? "Click again to clear everything" : "Clear all"
                color: root.confirmClearAll ? Theme.red : Theme.mutedDark
                font.pixelSize: 11

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -6
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.confirmClearAll) {
                            ShellState.saveTodos([]);
                            root.confirmClearAll = false;
                            root.detailsId = "";
                            root.editingId = "";
                        } else {
                            root.confirmClearAll = true;
                            confirmTimer.restart();
                        }
                    }
                }
            }

            ShellText {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                visible: ShellState.todos.some((task) => task.done)
                text: "Clear completed"
                color: Theme.mutedDark
                font.pixelSize: 11

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -6
                    cursorShape: Qt.PointingHandCursor
                    onClicked: ShellState.clearCompletedTodos()
                }
            }

            Timer {
                id: confirmTimer

                interval: 3000
                onTriggered: root.confirmClearAll = false
            }
        }
    }
}
