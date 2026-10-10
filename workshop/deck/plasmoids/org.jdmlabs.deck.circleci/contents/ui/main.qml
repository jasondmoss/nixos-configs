/*
    Deck: CircleCI — the pipelines you triggered across the organisation,
    with their workflows and (for anything not green) their jobs. Data from
    deck-agent (GET /circleci), which polls the CircleCI API v2 with
    `mine=true`.

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

    readonly property var ci: client.payload
    readonly property bool configured: client.online && ci !== null && ci.configured === true
    readonly property var pipelines: root.configured && ci.pipelines
        ? ci.pipelines.slice(0, Math.max(1, Plasmoid.configuration.maxPipelines))
        : []
    readonly property int runningCount: root.configured ? (ci.running || 0) : 0
    // Off the clock: no work project open in PhpStorm, no work-only program running.
    readonly property bool offWork: Plasmoid.configuration.idleWhenOffWork && client.online
        && ci !== null && !!ci.work && ci.work.enabled === true && ci.work.active === false
    property double now: Date.now()

    readonly property string statusWord: {
        if (!root.configured || root.offWork) return "muted";
        if (root.ci.error) return "error";
        if (root.runningCount > 0) return "running";
        return root.pipelines.length ? root.pipelines[0].status : "muted";
    }

    preferredRepresentation: fullRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.DefaultBackground | PlasmaCore.Types.ConfigurableBackground
    toolTipMainText: i18n("CircleCI")
    toolTipSubText: root.configured
        ? (root.runningCount ? i18np("%1 pipeline running", "%1 pipelines running", root.runningCount) : i18n("Nothing running"))
        : (client.online && root.ci ? root.ci.error : client.error)

    DeckClient {
        id: client
        port: Plasmoid.configuration.port
        endpoint: "/circleci"
        interval: Math.max(2, Plasmoid.configuration.interval) * 1000
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

    Timer {
        id: refreshDelay
        interval: 3000
        onTriggered: client.refresh()
    }

    fullRepresentation: Item {
        Layout.minimumWidth: Kirigami.Units.gridUnit * 18
        Layout.minimumHeight: Kirigami.Units.gridUnit * 9
        Layout.preferredWidth: Kirigami.Units.gridUnit * 28
        Layout.preferredHeight: Kirigami.Units.gridUnit * 20

        ColumnLayout {
            anchors.fill: parent
            spacing: Kirigami.Units.smallSpacing

            CardHeader {
                Layout.fillWidth: true
                icon: Qt.resolvedUrl("../icons/circleci.svg")
                maskIcon: true
                title: i18n("CircleCI")
                subtitle: root.offWork ? i18n("off the clock") : root.configured
                    ? i18n("%1 · your pipelines · %2", String(root.ci.org || "").replace(/^gh\//, ""), Utils.relTime(root.ci.updated_at, root.now))
                    : ""
                status: root.statusWord

                PlasmaComponents3.ToolButton {
                    icon.name: "view-refresh"
                    enabled: client.online
                    onClicked: client.post("/circleci/refresh", {}, () => refreshDelay.restart())
                    PlasmaComponents3.ToolTip.text: i18n("Refresh now")
                    PlasmaComponents3.ToolTip.visible: hovered
                    PlasmaComponents3.ToolTip.delay: Kirigami.Units.toolTipDelay
                }

                PlasmaComponents3.ToolButton {
                    icon.name: "internet-services"
                    visible: root.configured && !!root.ci.url
                    onClicked: Qt.openUrlExternally(root.ci.url)
                    PlasmaComponents3.ToolTip.text: i18n("Open CircleCI in the browser")
                    PlasmaComponents3.ToolTip.visible: hovered
                    PlasmaComponents3.ToolTip.delay: Kirigami.Units.toolTipDelay
                }
            }

            Offline {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.offWork
                icon: "system-suspend"
                message: i18n("Off the clock\nPipelines show up again when a work project is open in PhpStorm or Chrome is running.")
            }

            Offline {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: !root.offWork && (!root.configured || (root.ci.error && root.pipelines.length === 0))
                icon: client.online ? "dialog-password" : "network-disconnect"
                message: client.online ? (root.ci ? (root.ci.error || i18n("Waiting for pipelines…")) : i18n("Waiting for the agent…")) : client.error
            }

            PlasmaComponents3.Label {
                Layout.fillWidth: true
                visible: !root.offWork && root.configured && !!root.ci.error && root.pipelines.length > 0
                text: root.configured && root.ci.error ? root.ci.error : ""
                font: Kirigami.Theme.smallFont
                color: Utils.palette.error
                wrapMode: Text.WordWrap
            }

            PlasmaComponents3.ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: !root.offWork && root.configured && root.pipelines.length > 0

                ListView {
                    id: pipelineView
                    model: root.pipelines
                    clip: true
                    spacing: Kirigami.Units.smallSpacing

                    delegate: Item {
                        id: row
                        required property var modelData
                        readonly property var p: modelData
                        width: ListView.view.width
                        height: rowLayout.implicitHeight + Kirigami.Units.smallSpacing * 2

                        Rectangle {
                            anchors.fill: parent
                            radius: 4
                            color: Kirigami.Theme.highlightColor
                            opacity: rowMouse.containsMouse ? 0.18 : 0.06
                        }

                        Rectangle {
                            // Status stripe
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            anchors.margins: 1
                            width: 3
                            radius: 2
                            color: Utils.statusColor(row.p.status)
                        }

                        MouseArea {
                            id: rowMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Qt.openUrlExternally(row.p.url)
                        }

                        ColumnLayout {
                            id: rowLayout
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.leftMargin: Kirigami.Units.smallSpacing * 2 + 3
                            anchors.rightMargin: Kirigami.Units.smallSpacing
                            spacing: 2

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Kirigami.Units.smallSpacing

                                StatusDot {
                                    status: row.p.status
                                    implicitWidth: 9
                                    implicitHeight: 9
                                }

                                PlasmaComponents3.Label {
                                    text: row.p.repo
                                    font.weight: Font.Bold
                                    elide: Text.ElideRight
                                    Layout.maximumWidth: row.width * 0.45
                                }

                                PlasmaComponents3.Label {
                                    text: "#" + row.p.number
                                    color: Kirigami.Theme.disabledTextColor
                                    font: Kirigami.Theme.smallFont
                                }

                                Pill {
                                    visible: !!(row.p.branch || row.p.tag)
                                    text: row.p.branch || row.p.tag || ""
                                    small: true
                                    Layout.maximumWidth: row.width * 0.3
                                }

                                Item { Layout.fillWidth: true }

                                PlasmaComponents3.Label {
                                    text: Utils.relTime(row.p.created, root.now)
                                    font: Kirigami.Theme.smallFont
                                    color: Kirigami.Theme.disabledTextColor
                                }
                            }

                            PlasmaComponents3.Label {
                                Layout.fillWidth: true
                                visible: Plasmoid.configuration.showSubject && !!(row.p.subject || row.p.actor)
                                text: (row.p.subject || "") + (row.p.actor ? "  <font color=\"" + Kirigami.Theme.disabledTextColor + "\">· " + row.p.actor + "</font>" : "")
                                textFormat: Text.StyledText
                                font: Kirigami.Theme.smallFont
                                elide: Text.ElideRight
                            }

                            Flow {
                                Layout.fillWidth: true
                                spacing: Kirigami.Units.smallSpacing

                                Repeater {
                                    model: row.p.workflows || []
                                    delegate: Pill {
                                        id: wfPill
                                        required property var modelData
                                        text: modelData.name + " · " + Utils.titleCase(modelData.status)
                                            + (modelData.duration ? " · " + Utils.duration(modelData.duration) : "")
                                        tint: Utils.statusColor(modelData.status)
                                        small: true

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: Qt.openUrlExternally(wfPill.modelData.url)
                                        }
                                    }
                                }
                            }

                            // Jobs of workflows that need a look.
                            Flow {
                                Layout.fillWidth: true
                                spacing: Kirigami.Units.smallSpacing
                                visible: Plasmoid.configuration.showJobs && jobRepeater.count > 0

                                Repeater {
                                    id: jobRepeater
                                    model: {
                                        if (!Plasmoid.configuration.showJobs) return [];
                                        const jobs = [];
                                        for (const wf of row.p.workflows || []) {
                                            if (wf.status === "success") continue;
                                            for (const job of wf.jobs || []) {
                                                jobs.push(job);
                                            }
                                        }
                                        return jobs;
                                    }
                                    delegate: PlasmaComponents3.Label {
                                        id: jobLabel
                                        required property var modelData
                                        text: "↳ " + modelData.name + " · " + Utils.titleCase(modelData.status)
                                            + (modelData.duration ? " · " + Utils.duration(modelData.duration) : "")
                                        font: Kirigami.Theme.smallFont
                                        color: Utils.statusColor(modelData.status)

                                        MouseArea {
                                            anchors.fill: parent
                                            enabled: !!jobLabel.modelData.url
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: Qt.openUrlExternally(jobLabel.modelData.url)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
