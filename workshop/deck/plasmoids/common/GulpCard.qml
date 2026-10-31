/*
    Gulp card — the agent's watcher for the project open in PhpStorm: state,
    last build, errors and the live log (GET /gulp, POST /gulp/*). Lines are
    fetched incrementally with ?since=<seq>. Embedded by the Deck widget and
    the standalone Gulp widget.

    SPDX-License-Identifier: GPL-2.0-or-later
*/
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami
import "Utils.js" as Utils

Item {
    id: root

    // Configuration: the embedding widget binds these (its own keys may differ).
    property int port: Plasmoid.configuration.port
    property bool trackPhpStorm: Plasmoid.configuration.trackPhpStorm
    property int fontSize: Plasmoid.configuration.fontSize
    property bool wrapLines: Plasmoid.configuration.wrapLines
    property int maxLines: Plasmoid.configuration.maxLines
    property bool idleWhenNoProject: Plasmoid.configuration.idleWhenNoProject
    // Polling pauses while the card is hidden (a background tab of the Deck widget).
    property bool polling: root.visible
    readonly property string statusWord: root.state === "offline" || root.noProject ? "muted" : root.state

    readonly property var gulp: client.payload
    readonly property bool noProject: root.idleWhenNoProject && client.online
        && gulp !== null && !!gulp.work && gulp.work.reported === true && gulp.work.windows === 0
    readonly property string state: client.online && gulp ? (gulp.state || "stopped") : "offline"
    readonly property bool running: state === "watching" || state === "compiling" || state === "error"
    readonly property var project: gulp && gulp.project ? gulp.project : null
    readonly property string projectTitle: project ? (project.title || project.name || "") : ""
    property string projectPath: ""
    property int lastSeq: 0
    property bool autoScroll: true
    property double now: Date.now()

    // "gulp default · origin", "npm run watch · washington", or plain "Gulp".
    readonly property string runnerTitle: root.gulp && root.gulp.label
        ? root.gulp.label + (root.gulp.theme ? " · " + root.gulp.theme : "")
        : i18n("Gulp")
    readonly property string tooltipMain: root.runnerTitle
    readonly property string tooltipSub: root.statusText

    ListModel { id: lines }

    DeckClient {
        id: client
        active: root.polling
        port: root.port
        endpoint: "/gulp"
        query: "since=" + root.lastSeq
        interval: root.running ? 1000 : 3000
        onReceived: (data) => root.ingest(data)
    }

    Loader {
        active: root.trackPhpStorm
        sourceComponent: ProjectTracker { client: client }
    }

    Timer {
        interval: 15000
        running: true
        repeat: true
        onTriggered: root.now = Date.now()
    }

    function ingest(data)
    {
        const path = data.project ? data.project.path : "";
        if (path !== root.projectPath || (data.seq || 0) < root.lastSeq) {
            // Another project's watcher, or the agent restarted: start over.
            root.projectPath = path;
            lines.clear();
            if (root.lastSeq !== 0) {
                root.lastSeq = 0;
                client.refresh();
                return;
            }
        }
        if (!data.lines) {
            return;
        }
        for (const line of data.lines) {
            if (line.seq > root.lastSeq) {
                lines.append({ seq: line.seq, html: line.html, text: line.text });
                root.lastSeq = line.seq;
            }
        }
        const max = Math.max(20, root.maxLines);
        while (lines.count > max) {
            lines.remove(0);
        }
    }

    function action(verb)
    {
        client.post("/gulp/" + verb, {}, () => {
            if (verb === "clear") {
                lines.clear();
            }
            client.refresh();
        });
    }

    readonly property string statusText: {
        const g = root.gulp;
        switch (root.state) {
        case "offline":
            return client.error;
        case "watching": {
            const ev = g.last_event;
            if (ev && ev.kind === "finished" && ev.task !== g.task && ev.task !== "watch") {
                return i18n("Watching · '%1' finished in %2 · %3", ev.task, ev.duration, Utils.relTime(ev.at, root.now));
            }
            return i18n("Watching since %1", Utils.relTime(g.started_at, root.now));
        }
        case "compiling":
            return i18n("Running '%1'…", g.last_event ? g.last_event.task : "");
        case "error":
            return i18n("Error in '%1' · %2", (g.error && g.error.task) || "?", g.error ? Utils.relTime(g.error.at, root.now) : "");
        case "exited":
            return i18n("Exited with code %1 · %2", g.exit_code, Utils.relTime(g.ended_at, root.now));
        case "external":
            return i18n("Running outside the agent (PhpStorm?), pid %1 — its output is not visible here", g.external_pid);
        case "missing":
            return g.message || i18n("No watcher in this project");
        default:
            return g && g.message ? g.message : i18n("Stopped");
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Kirigami.Units.smallSpacing

        CardHeader {
            Layout.fillWidth: true
            icon: "run-build"
            title: root.noProject ? i18n("Gulp") : root.runnerTitle
            subtitle: root.noProject ? i18n("no project open")
                : (root.project ? (root.projectTitle ? root.projectTitle + "  " : "") + (root.project.short || "") : "")
            status: root.state === "offline" || root.noProject ? "muted" : root.state

            PlasmaComponents3.ToolButton {
                icon.name: root.running ? "media-playback-stop" : "media-playback-start"
                enabled: client.online && root.gulp && root.gulp.available && root.state !== "external"
                onClicked: root.action(root.running ? "stop" : "start")
                PlasmaComponents3.ToolTip.text: root.running ? i18n("Stop the watcher") : i18n("Start `%1`", root.gulp && root.gulp.label ? root.gulp.label : "gulp default")
                PlasmaComponents3.ToolTip.visible: hovered
                PlasmaComponents3.ToolTip.delay: Kirigami.Units.toolTipDelay
            }

            PlasmaComponents3.ToolButton {
                icon.name: "view-refresh"
                enabled: client.online && root.gulp && root.gulp.available && root.state !== "external"
                onClicked: root.action("restart")
                PlasmaComponents3.ToolTip.text: i18n("Restart the watcher")
                PlasmaComponents3.ToolTip.visible: hovered
                PlasmaComponents3.ToolTip.delay: Kirigami.Units.toolTipDelay
            }

            PlasmaComponents3.ToolButton {
                icon.name: "edit-clear-all"
                enabled: lines.count > 0
                onClicked: root.action("clear")
                PlasmaComponents3.ToolTip.text: i18n("Clear the log")
                PlasmaComponents3.ToolTip.visible: hovered
                PlasmaComponents3.ToolTip.delay: Kirigami.Units.toolTipDelay
            }

            PlasmaComponents3.ToolButton {
                icon.name: "document-open"
                visible: client.online && root.gulp && !!root.gulp.gulpfile
                onClicked: client.post("/open", { path: root.gulp.gulpfile })
                PlasmaComponents3.ToolTip.text: root.gulp && root.gulp.runner === "gulp" ? i18n("Open the gulpfile in PhpStorm") : i18n("Open package.json in PhpStorm")
                PlasmaComponents3.ToolTip.visible: hovered
                PlasmaComponents3.ToolTip.delay: Kirigami.Units.toolTipDelay
            }
        }

        Offline {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.noProject
            icon: "system-suspend"
            message: root.running
                ? i18n("No project open\nThe last watcher is still running; stop it with the button above or leave it.")
                : i18n("No project open\nThe card wakes up with the next project in PhpStorm.")
        }

        PlasmaComponents3.Label {
            Layout.fillWidth: true
            visible: !root.noProject
            text: root.statusText
            font: Kirigami.Theme.smallFont
            color: root.state === "offline" ? Kirigami.Theme.disabledTextColor : Utils.statusColor(root.state)
            elide: Text.ElideRight
            wrapMode: root.state === "offline" || root.state === "external" ? Text.WordWrap : Text.NoWrap
        }

        // Watchers of other projects that are still running.
        Flow {
            Layout.fillWidth: true
            visible: client.online && root.gulp && root.gulp.others && root.gulp.others.length > 0 && !root.noProject
            spacing: Kirigami.Units.smallSpacing

            PlasmaComponents3.Label {
                text: i18n("also watching:")
                font: Kirigami.Theme.smallFont
                color: Kirigami.Theme.disabledTextColor
            }

            Repeater {
                model: client.online && root.gulp && root.gulp.others ? root.gulp.others : []
                delegate: Pill {
                    required property var modelData
                    text: modelData.name + (modelData.theme ? " · " + modelData.theme : "")
                    tint: Utils.palette.running
                    small: true
                }
            }
        }

        // Error excerpt
        Rectangle {
            Layout.fillWidth: true
            visible: root.state === "error" && !root.noProject && root.gulp.error && root.gulp.error.lines.length > 0
            implicitHeight: errorText.implicitHeight + Kirigami.Units.smallSpacing * 2
            radius: 4
            color: Qt.rgba(1, 0.37, 0.43, 0.14)
            border.width: 1
            border.color: Qt.rgba(1, 0.37, 0.43, 0.5)

            PlasmaComponents3.Label {
                id: errorText
                anchors.fill: parent
                anchors.margins: Kirigami.Units.smallSpacing
                text: root.state === "error" && root.gulp.error ? root.gulp.error.lines.join("\n") : ""
                font.family: Kirigami.Theme.fixedWidthFont.family
                font.pixelSize: Math.max(8, root.fontSize - 1)
                wrapMode: Text.WrapAnywhere
                maximumLineCount: 8
                elide: Text.ElideRight
            }
        }

        PlasmaComponents3.ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: client.online && !root.noProject

            ListView {
                id: logView
                model: lines
                clip: true
                spacing: 0
                boundsBehavior: Flickable.StopAtBounds

                delegate: Text {
                    required property string html
                    width: ListView.view.width
                    text: html
                    textFormat: Text.RichText
                    wrapMode: root.wrapLines ? Text.WrapAnywhere : Text.NoWrap
                    font.family: Kirigami.Theme.fixedWidthFont.family
                    font.pixelSize: root.fontSize
                    color: Kirigami.Theme.textColor
                }

                onCountChanged: {
                    if (root.autoScroll) {
                        Qt.callLater(() => logView.positionViewAtEnd());
                    }
                }
                onMovementEnded: root.autoScroll = logView.atYEnd
                onFlickEnded: root.autoScroll = logView.atYEnd

                PlasmaComponents3.Label {
                    anchors.centerIn: parent
                    visible: lines.count === 0
                    text: root.running ? i18n("Waiting for output…") : i18n("No output yet")
                    color: Kirigami.Theme.disabledTextColor
                }
            }
        }

        Offline {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: !client.online
            message: client.error
        }

        PlasmaComponents3.ToolButton {
            Layout.alignment: Qt.AlignRight
            visible: !root.autoScroll && lines.count > 0 && !root.noProject
            icon.name: "go-bottom"
            text: i18n("Follow")
            onClicked: {
                root.autoScroll = true;
                logView.positionViewAtEnd();
            }
        }
    }
}
