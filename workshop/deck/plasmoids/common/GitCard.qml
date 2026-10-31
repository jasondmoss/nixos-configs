/*
    Git card — branch, ahead/behind, last commit and changed files of the
    project open in PhpStorm (GET /git). Embedded by the Deck widget and by
    the standalone Git widget; the configuration properties default to the
    embedding widget's Plasmoid.configuration keys of the same name.

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
    property int interval: Plasmoid.configuration.interval
    property bool trackPhpStorm: Plasmoid.configuration.trackPhpStorm
    property bool showUntracked: Plasmoid.configuration.showUntracked
    property bool showPath: Plasmoid.configuration.showPath
    property bool idleWhenNoProject: Plasmoid.configuration.idleWhenNoProject
    // Polling pauses while the card is hidden (a background tab of the Deck widget).
    property bool polling: root.visible

    readonly property var git: client.payload
    // PhpStorm has no project window at all (closed, or only the welcome screen).
    readonly property bool noProject: root.idleWhenNoProject && client.online
        && git !== null && !!git.work && git.work.reported === true && git.work.windows === 0
    readonly property bool ready: client.online && git !== null && git.available === true && !root.noProject
    readonly property var project: git && git.project ? git.project : null
    readonly property string projectTitle: project ? (project.title || project.name || "") : ""
    readonly property string projectPath: project && project.short ? project.short : ""
    readonly property var counts: ready ? git.counts : ({ staged: 0, unstaged: 0, untracked: 0, conflicts: 0 })

    readonly property string statusWord: {
        if (!root.ready) return "muted";
        if (root.counts.conflicts > 0) return "error";
        if (git.dirty) return "warn";
        return "ok";
    }

    readonly property string summary: {
        if (!root.ready) return "";
        const parts = [];
        if (root.counts.conflicts) parts.push(Utils.plural(root.counts.conflicts, "conflict"));
        if (root.counts.staged) parts.push(root.counts.staged + " staged");
        if (root.counts.unstaged) parts.push(root.counts.unstaged + " modified");
        if (root.counts.untracked) parts.push(root.counts.untracked + " untracked");
        return parts.length ? parts.join(" · ") : i18n("Working tree clean");
    }

    /* Conflicts first, then staged, unstaged and untracked entries. */
    readonly property var fileList: {
        if (!root.ready) return [];
        const list = [];
        const push = (items, bucket) => {
            for (const item of items || []) {
                list.push({ path: item.path, status: item.status, label: item.label, bucket: bucket });
            }
        };
        push(git.conflicts, "conflict");
        push(git.staged, "staged");
        push(git.unstaged, "unstaged");
        if (root.showUntracked) {
            push(git.untracked, "untracked");
        }
        return list;
    }

    // The project's Lando app (null without a .lando.yml): containers up, start/stop in progress.
    readonly property var lando: client.online && !root.noProject && git !== null && git.lando ? git.lando : null
    readonly property bool landoBusy: !!root.lando && root.lando.busy === true
    readonly property bool landoUp: !!root.lando && (root.lando.state === "running" || root.lando.state === "partial")
    readonly property string landoUrl: root.lando && root.lando.state === "running" && root.lando.url ? root.lando.url : ""

    readonly property string landoStatus: {
        if (!root.lando) return "muted";
        if (root.landoBusy) return "running";
        if (root.lando.failed || root.lando.state === "unknown") return "error";
        if (root.lando.state === "running") return "ok";
        if (root.lando.state === "partial") return "warn";
        return "muted";
    }

    readonly property string landoText: {
        if (!root.lando) return "";
        if (root.landoBusy) return root.lando.state === "starting" ? i18n("lando starting…") : i18n("lando stopping…");
        if (root.lando.failed) return i18n("lando %1 failed", root.lando.job.verb);
        switch (root.lando.state) {
        case "running": return i18n("lando up");
        case "partial": return i18n("lando %1/%2", root.lando.running, root.lando.total);
        case "missing": return i18n("lando not built");
        case "unknown": return i18n("lando ?");
        default: return i18n("lando off");
        }
    }

    readonly property string landoTip: {
        if (!root.lando) return "";
        const app = root.lando.app;
        if (root.landoBusy) return i18n("lando %1 · %2", root.lando.job.verb, app) + (root.lando.job.last ? "\n" + root.lando.job.last : "");
        if (root.lando.failed) return i18n("lando %1 failed (exit %2)", root.lando.job.verb, root.lando.job.exit_code) + "\n" + root.lando.job.tail.slice(-3).join("\n");
        switch (root.lando.state) {
        case "running": return i18n("%1 · %2 containers up", app, root.lando.total) + (root.landoUrl ? "\n" + i18n("Click to open %1", root.landoUrl) : "");
        case "partial": return i18n("%1 · %2 of %3 containers up", app, root.lando.running, root.lando.total);
        case "missing": return i18n("%1 has no containers yet — starting builds them", app);
        case "unknown": return root.lando.error || i18n("Docker is not answering");
        default: return i18n("%1 · stopped", app);
        }
    }

    property double now: Date.now()

    readonly property string tooltipMain: root.projectTitle || i18n("Git")
    readonly property string tooltipSub: root.ready ? (git.branch || "") + " · " + root.summary : client.error

    DeckClient {
        id: client
        active: root.polling
        port: root.port
        endpoint: "/git"
        interval: Math.max(1, root.interval) * 1000
    }

    Loader {
        active: root.trackPhpStorm
        sourceComponent: ProjectTracker { client: client }
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: root.now = Date.now()
    }

    function bucketColor(bucket)
    {
        switch (bucket) {
        case "conflict": return Utils.palette.error;
        case "staged": return Utils.palette.ok;
        case "unstaged": return Utils.palette.warn;
        default: return Utils.palette.muted;
        }
    }

    function openInIde(path)
    {
        client.post("/open", { path: path });
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Kirigami.Units.smallSpacing

        CardHeader {
            Layout.fillWidth: true
            icon: "vcs-normal"
            title: root.noProject ? i18n("Git") : (root.projectTitle || i18n("Git"))
            subtitle: root.noProject ? i18n("no project open") : (root.showPath ? root.projectPath : "")
            status: root.statusWord

            Pill {
                id: landoPill
                visible: root.lando !== null
                text: root.landoText
                tint: Utils.statusColor(root.landoStatus)
                small: true
                Layout.rightMargin: Kirigami.Units.smallSpacing

                SequentialAnimation on opacity {
                    running: root.landoBusy
                    loops: Animation.Infinite
                    alwaysRunToEnd: true
                    NumberAnimation { to: 0.45; duration: 700; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1.0; duration: 700; easing.type: Easing.InOutSine }
                }

                MouseArea {
                    id: landoMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: root.landoUrl ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: {
                        if (root.landoUrl) {
                            Qt.openUrlExternally(root.landoUrl);
                        }
                    }
                }

                PlasmaComponents3.ToolTip.text: root.landoTip
                PlasmaComponents3.ToolTip.visible: landoMouse.containsMouse
                PlasmaComponents3.ToolTip.delay: Kirigami.Units.toolTipDelay
            }

            PlasmaComponents3.ToolButton {
                visible: root.lando !== null
                enabled: !root.landoBusy && !!root.lando && root.lando.state !== "unknown"
                icon.name: root.landoUp ? "media-playback-stop" : "media-playback-start"
                onClicked: client.post("/lando/" + (root.landoUp ? "stop" : "start"), {}, () => client.refresh())
                PlasmaComponents3.ToolTip.text: root.landoUp ? i18n("lando stop") : i18n("lando start")
                PlasmaComponents3.ToolTip.visible: hovered
                PlasmaComponents3.ToolTip.delay: Kirigami.Units.toolTipDelay
            }

            PlasmaComponents3.ToolButton {
                icon.name: "view-refresh"
                enabled: root.ready
                visible: !root.noProject
                onClicked: client.post("/git/fetch", {}, () => fetchDelay.restart())
                PlasmaComponents3.ToolTip.text: i18n("Fetch")
                PlasmaComponents3.ToolTip.visible: hovered
                PlasmaComponents3.ToolTip.delay: Kirigami.Units.toolTipDelay
            }

            PlasmaComponents3.ToolButton {
                icon.name: "internet-services"
                visible: root.ready && !!root.git.web_url
                onClicked: Qt.openUrlExternally(root.git.web_url + (root.git.branch ? "/tree/" + root.git.branch : ""))
                PlasmaComponents3.ToolTip.text: i18n("Open repository in the browser")
                PlasmaComponents3.ToolTip.visible: hovered
                PlasmaComponents3.ToolTip.delay: Kirigami.Units.toolTipDelay
            }
        }

        Timer {
            id: fetchDelay
            interval: 2500
            onTriggered: client.refresh()
        }

        Offline {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.noProject
            icon: "system-suspend"
            message: i18n("No project open\nThe card wakes up with the next project in PhpStorm.")
        }

        Offline {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: !root.ready && !root.noProject
            icon: client.online ? "vcs-normal" : "network-disconnect"
            message: client.online
                ? (root.git && root.git.error ? root.git.error : i18n("Waiting for the agent…"))
                : client.error
        }

        // Branch line
        RowLayout {
            Layout.fillWidth: true
            visible: root.ready
            spacing: Kirigami.Units.smallSpacing

            Kirigami.Icon {
                source: "vcs-branch"
                Layout.preferredWidth: Kirigami.Units.iconSizes.small
                Layout.preferredHeight: Kirigami.Units.iconSizes.small
            }

            PlasmaComponents3.Label {
                text: root.ready
                    ? (root.git.branch || (root.git.detached ? i18n("detached at %1", String(root.git.oid || "").slice(0, 7)) : "—"))
                    : ""
                font.weight: Font.DemiBold
                elide: Text.ElideMiddle
                Layout.maximumWidth: root.width * 0.5
            }

            Pill {
                visible: root.ready && root.git.ahead > 0
                text: "↑ " + (root.ready ? root.git.ahead : 0)
                tint: Utils.palette.ok
                small: true
            }

            Pill {
                visible: root.ready && root.git.behind > 0
                text: "↓ " + (root.ready ? root.git.behind : 0)
                tint: Utils.palette.warn
                small: true
            }

            Pill {
                visible: root.ready && root.git.stashes > 0
                text: root.ready ? (root.git.stashes === 1 ? i18n("1 stash") : i18n("%1 stashes", root.git.stashes)) : ""
                tint: Utils.palette.hold
                small: true
            }

            Item { Layout.fillWidth: true }

            PlasmaComponents3.Label {
                text: root.ready ? (root.git.upstream || i18n("no upstream")) : ""
                font: Kirigami.Theme.smallFont
                color: Kirigami.Theme.disabledTextColor
                elide: Text.ElideMiddle
                Layout.maximumWidth: root.width * 0.4
            }
        }

        // Last commit
        RowLayout {
            Layout.fillWidth: true
            visible: root.ready && root.git.last_commit !== null
            spacing: Kirigami.Units.smallSpacing

            PlasmaComponents3.Label {
                text: root.ready && root.git.last_commit ? root.git.last_commit.hash : ""
                font.family: Kirigami.Theme.fixedWidthFont.family
                color: Utils.palette.running
            }

            PlasmaComponents3.Label {
                Layout.fillWidth: true
                text: root.ready && root.git.last_commit ? root.git.last_commit.subject : ""
                elide: Text.ElideRight
            }

            PlasmaComponents3.Label {
                text: root.ready && root.git.last_commit
                    ? Utils.relTime(root.git.last_commit.time, root.now)
                    : ""
                font: Kirigami.Theme.smallFont
                color: Kirigami.Theme.disabledTextColor
            }
        }

        PlasmaComponents3.Label {
            Layout.fillWidth: true
            visible: root.ready
            text: root.summary
            font: Kirigami.Theme.smallFont
            color: Utils.statusColor(root.statusWord)
            elide: Text.ElideRight
        }

        PlasmaComponents3.ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.ready && root.fileList.length > 0

            ListView {
                id: fileView
                model: root.fileList
                clip: true
                spacing: 1

                delegate: Item {
                    id: fileRow
                    required property var modelData
                    width: ListView.view.width
                    height: fileLayout.implicitHeight + Kirigami.Units.smallSpacing

                    Rectangle {
                        anchors.fill: parent
                        radius: 3
                        color: Kirigami.Theme.highlightColor
                        opacity: fileMouse.containsMouse ? 0.25 : 0
                    }

                    RowLayout {
                        id: fileLayout
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: Kirigami.Units.smallSpacing
                        anchors.rightMargin: Kirigami.Units.smallSpacing
                        spacing: Kirigami.Units.smallSpacing

                        Pill {
                            text: fileRow.modelData.status
                            tint: root.bucketColor(fileRow.modelData.bucket)
                            small: true
                            Layout.preferredWidth: Kirigami.Units.gridUnit * 1.6
                        }

                        PlasmaComponents3.Label {
                            Layout.fillWidth: true
                            text: {
                                const dir = Utils.dirname(fileRow.modelData.path);
                                const base = Utils.basename(fileRow.modelData.path);
                                const dim = Kirigami.Theme.disabledTextColor;
                                return (dir ? "<font color=\"" + dim + "\">" + dir + "/</font>" : "") + base;
                            }
                            textFormat: Text.StyledText
                            elide: Text.ElideMiddle
                            font: Kirigami.Theme.smallFont
                        }

                        PlasmaComponents3.Label {
                            text: fileRow.modelData.label
                            font: Kirigami.Theme.smallFont
                            color: Kirigami.Theme.disabledTextColor
                            visible: fileRow.width > Kirigami.Units.gridUnit * 20
                        }
                    }

                    MouseArea {
                        id: fileMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.openInIde(root.git.root + "/" + fileRow.modelData.path)
                    }

                    PlasmaComponents3.ToolTip.text: i18n("Open in PhpStorm")
                    PlasmaComponents3.ToolTip.visible: fileMouse.containsMouse
                    PlasmaComponents3.ToolTip.delay: Kirigami.Units.toolTipDelay
                }
            }
        }

        Item {
            Layout.fillHeight: true
            visible: root.ready && root.fileList.length === 0
        }

        PlasmaComponents3.Label {
            Layout.fillWidth: true
            visible: root.ready && root.git.fetch_enabled && !!root.git.fetched_at
            text: root.ready && root.git.fetched_at ? i18n("fetched %1", Utils.relTime(root.git.fetched_at, root.now)) : ""
            font: Kirigami.Theme.smallFont
            color: Kirigami.Theme.disabledTextColor
            horizontalAlignment: Text.AlignRight
        }
    }
}
