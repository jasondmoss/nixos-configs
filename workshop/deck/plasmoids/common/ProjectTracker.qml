/*
    Reports the active PhpStorm project to the Deck agent.

    PhpStorm's window caption carries the project path in brackets —
    "CHI: Castle Hill Inn [~/Repository/work/origin/castle-hill/castle-hill-inn] – file.php"
    — so the active window from Plasma's TasksModel tells which project the
    cards should follow. Reports are cheap and deduplicated: the agent only
    switches when the path changes. If PhpStorm is not the active window when
    the card loads, any PhpStorm window is reported with active=false, which
    the agent takes only while it has no project yet.

    SPDX-License-Identifier: GPL-2.0-or-later
*/
import QtQuick
import org.kde.taskmanager as TaskManager

Item {
    id: tracker

    required property DeckClient client
    property string lastReport: ""

    visible: false

    readonly property var tasks: TaskManager.TasksModel {
        filterByVirtualDesktop: false
        filterByActivity: false
        filterByScreen: false
        filterMinimized: false
        filterHidden: false
        groupMode: TaskManager.TasksModel.GroupDisabled
        sortMode: TaskManager.TasksModel.SortDisabled

        onActiveTaskChanged: debounce.restart()
        onDataChanged: debounce.restart()
        onCountChanged: debounce.restart()
    }

    Timer {
        id: debounce
        interval: 400
        onTriggered: tracker.scan()
    }

    function isIde(index)
    {
        const appId = String(tracker.tasks.data(index, TaskManager.AbstractTasksModel.AppId) || "");
        const appName = String(tracker.tasks.data(index, TaskManager.AbstractTasksModel.AppName) || "");
        return /phpstorm|jetbrains|intellij|webstorm/i.test(appId + " " + appName);
    }

    function captionOf(index)
    {
        return String(tracker.tasks.data(index, Qt.DisplayRole) || "");
    }

    function scan()
    {
        const active = tasks.activeTask;
        if (active && active.valid && isIde(active)) {
            report(captionOf(active), true);
            return;
        }
        // PhpStorm is not in front: offer any of its windows as a fallback.
        for (let row = 0; row < tasks.count; row++) {
            const index = tasks.index(row, 0);
            if (isIde(index)) {
                const caption = captionOf(index);
                if (/\[~?\/[^\]]+\]/.test(caption)) {
                    report(caption, false);
                    return;
                }
            }
        }
    }

    function report(caption, isActive)
    {
        if (!/\[~?\/[^\]]+\]/.test(caption)) {
            return;
        }
        const key = (isActive ? "A:" : "B:") + caption.replace(/\s[–-]\s.*$/, "");
        if (key === lastReport) {
            return;
        }
        lastReport = key;
        client.post("/project", { caption: caption, active: isActive });
    }

    Connections {
        target: tracker.client
        function onOnlineChanged() {
            if (tracker.client.online) {
                tracker.lastReport = "";
                debounce.restart();
            }
        }
    }

    Component.onCompleted: debounce.restart()
}
