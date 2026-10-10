/*
    Deck: Git — branch, ahead/behind, last commit and changed files of the
    project open in PhpStorm. Data comes from the deck-agent service
    (GET /git); the PhpStorm project is reported through ProjectTracker.

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

PlasmoidItem {
    id: root

    readonly property var git: client.payload
    readonly property bool ready: client.online && git !== null && git.available === true
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
        if (Plasmoid.configuration.showUntracked) {
            push(git.untracked, "untracked");
        }
        return list;
    }

    property double now: Date.now()

    preferredRepresentation: fullRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.DefaultBackground | PlasmaCore.Types.ConfigurableBackground
    toolTipMainText: root.projectTitle || i18n("Git")
    toolTipSubText: root.ready ? (git.branch || "") + " · " + root.summary : client.error

    DeckClient {
        id: client
        port: Plasmoid.configuration.port
        endpoint: "/git"
        interval: Math.max(1, Plasmoid.configuration.interval) * 1000
    }

    Loader {
        active: Plasmoid.configuration.trackPhpStorm
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

    fullRepresentation: Item {
        Layout.minimumWidth: Kirigami.Units.gridUnit * 16
        Layout.minimumHeight: Kirigami.Units.gridUnit * 9
        Layout.preferredWidth: Kirigami.Units.gridUnit * 24
        Layout.preferredHeight: Kirigami.Units.gridUnit * 16

        ColumnLayout {
            anchors.fill: parent
            spacing: Kirigami.Units.smallSpacing

            CardHeader {
                Layout.fillWidth: true
                icon: "vcs-normal"
                title: root.projectTitle || i18n("Git")
                subtitle: Plasmoid.configuration.showPath ? root.projectPath : ""
                status: root.statusWord

                PlasmaComponents3.ToolButton {
                    icon.name: "view-refresh"
                    enabled: root.ready
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
                visible: !root.ready
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
                    Layout.maximumWidth: parent.width * 0.5
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
                    Layout.maximumWidth: parent.width * 0.4
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
}
