/*
    Deck: Pantheon — environments and recent workflows of one Pantheon site:
    by default the site your latest CircleCI pipeline deploys to, or the
    project open in PhpStorm, or a pinned site. Data from deck-agent
    (GET /pantheon, via terminus); "Clear caches" posts
    /pantheon/clear-cache after a second click.

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

    readonly property var pan: client.payload
    readonly property bool configured: client.online && pan !== null && pan.configured === true
    readonly property var site: root.configured && pan.site ? pan.site : null
    readonly property var envs: root.configured && pan.envs ? pan.envs : []
    readonly property var workflows: root.configured && pan.workflows
        ? pan.workflows.slice(0, Math.max(1, Plasmoid.configuration.maxWorkflows))
        : []
    readonly property bool offWork: Plasmoid.configuration.idleWhenOffWork && client.online
        && pan !== null && !!pan.work && pan.work.enabled === true && pan.work.active === false
    readonly property bool hasData: !root.offWork && root.site !== null && root.envs.length > 0
    property string selectedEnv: "dev"
    readonly property var env: {
        for (const e of root.envs) {
            if (e.id === root.selectedEnv) return e;
        }
        return root.envs.length ? root.envs[0] : null;
    }
    property double now: Date.now()
    property bool confirmClear: false
    property string actionMessage: ""

    readonly property string statusWord: {
        if (!root.configured || root.offWork) return "muted";
        // "Waiting for a pipeline" is not an error; a failing terminus call for a known site is.
        if (root.pan.error) return root.site ? "error" : "muted";
        for (const wf of root.workflows) {
            if (/running|queued|pending/i.test(wf.status || "")) return "running";
        }
        if (root.workflows.length && /fail|error/i.test(root.workflows[0].status || "")) return "warn";
        return root.hasData ? "ok" : "muted";
    }

    readonly property var followWords: ["pipeline", "phpstorm", "pinned"]

    preferredRepresentation: fullRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.DefaultBackground | PlasmaCore.Types.ConfigurableBackground
    toolTipMainText: root.site ? root.site.label : i18n("Pantheon")
    toolTipSubText: root.configured ? (root.pan.error || root.followText) : client.error

    readonly property string followText: {
        if (!root.configured) return "";
        const source = root.pan.source || {};
        switch (root.pan.follow) {
        case "phpstorm": return i18n("Following the PhpStorm project");
        case "pinned": return i18n("Pinned site");
        default: return source.repo ? i18n("Following your latest pipeline (%1)", source.repo) : i18n("Following your latest pipeline");
        }
    }

    DeckClient {
        id: client
        port: Plasmoid.configuration.port
        endpoint: "/pantheon"
        interval: Math.max(3, Plasmoid.configuration.interval) * 1000
        onOnlineChanged: if (online) root.pushFollow()
    }

    Loader {
        active: Plasmoid.configuration.trackPhpStorm
        sourceComponent: ProjectTracker { client: client }
    }

    function pushFollow()
    {
        client.post("/pantheon/follow", {
            follow: root.followWords[Plasmoid.configuration.follow] || "pipeline",
            site: Plasmoid.configuration.pinnedSite,
        }, () => refreshDelay.restart());
    }

    Connections {
        target: Plasmoid.configuration
        function onFollowChanged() { root.pushFollow(); }
        function onPinnedSiteChanged() { root.pushFollow(); }
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: root.now = Date.now()
    }

    Timer {
        id: refreshDelay
        interval: 4000
        onTriggered: client.refresh()
    }

    Timer {
        id: confirmTimer
        interval: 4000
        onTriggered: root.confirmClear = false
    }

    Timer {
        id: messageTimer
        interval: 6000
        onTriggered: root.actionMessage = ""
    }

    function clearCaches()
    {
        if (!root.env) return;
        if (!root.confirmClear) {
            root.confirmClear = true;
            confirmTimer.restart();
            return;
        }
        root.confirmClear = false;
        root.actionMessage = i18n("Clearing caches on %1…", root.env.id);
        client.post("/pantheon/clear-cache", { env: root.env.id }, (reply) => {
            root.actionMessage = reply && reply.ok ? i18n("Caches cleared on %1", root.env.id) : i18n("Clear caches failed: %1", reply ? reply.error : "?");
            messageTimer.restart();
        });
    }

    fullRepresentation: Item {
        id: rep
        Layout.minimumWidth: Kirigami.Units.gridUnit * 18
        Layout.minimumHeight: Kirigami.Units.gridUnit * 10
        Layout.preferredWidth: Kirigami.Units.gridUnit * 28
        Layout.preferredHeight: Kirigami.Units.gridUnit * 20

        ColumnLayout {
            anchors.fill: parent
            spacing: Kirigami.Units.smallSpacing

            CardHeader {
                Layout.fillWidth: true
                icon: Qt.resolvedUrl("../icons/pantheon.svg")
                maskIcon: true
                title: root.site && !root.offWork ? root.site.label : i18n("Pantheon")
                subtitle: root.offWork ? i18n("off the clock") : root.site
                    ? [root.site.plan, root.site.organization_name
                        || (/^[0-9a-f-]{36}$/.test(root.site.organization || "") ? "" : root.site.organization)]
                        .filter(Boolean).join(" · ")
                    : ""
                status: root.statusWord

                PlasmaComponents3.ToolButton {
                    icon.name: "view-refresh"
                    enabled: client.online
                    onClicked: client.post("/pantheon/refresh", {}, () => refreshDelay.restart())
                    PlasmaComponents3.ToolTip.text: i18n("Refresh now")
                    PlasmaComponents3.ToolTip.visible: hovered
                    PlasmaComponents3.ToolTip.delay: Kirigami.Units.toolTipDelay
                }

                PlasmaComponents3.ToolButton {
                    icon.name: "internet-services"
                    visible: !!(root.site && root.site.dashboard_url)
                    onClicked: Qt.openUrlExternally(root.env && root.env.dashboard_url ? root.env.dashboard_url : root.site.dashboard_url)
                    PlasmaComponents3.ToolTip.text: i18n("Open the Pantheon dashboard")
                    PlasmaComponents3.ToolTip.visible: hovered
                    PlasmaComponents3.ToolTip.delay: Kirigami.Units.toolTipDelay
                }
            }

            Offline {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.offWork
                icon: "system-suspend"
                message: i18n("Off the clock\nThe site shows up again when a work project is open in PhpStorm or Chrome is running.")
            }

            Offline {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: !root.hasData && !root.offWork
                icon: client.online ? (root.configured && root.pan.error && root.site ? "dialog-warning" : "network-server") : "network-disconnect"
                message: client.online
                    ? (root.pan ? (root.pan.error || i18n("Waiting for terminus…")) : i18n("Waiting for the agent…"))
                    : client.error
            }

            // Environment tabs
            Flow {
                Layout.fillWidth: true
                visible: root.hasData
                spacing: Kirigami.Units.smallSpacing

                Repeater {
                    model: root.envs
                    delegate: Pill {
                        id: envPill
                        required property var modelData
                        readonly property bool selected: root.env && root.env.id === modelData.id
                        text: modelData.id + (modelData.locked ? " 🔒" : "")
                        filled: selected
                        tint: selected ? Kirigami.Theme.highlightColor : (modelData.multidev ? Utils.palette.hold : Kirigami.Theme.disabledTextColor)
                        opacity: modelData.initialized ? 1 : 0.5

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.selectedEnv = envPill.modelData.id;
                                root.confirmClear = false;
                            }
                        }
                    }
                }
            }

            // Selected environment
            GridLayout {
                Layout.fillWidth: true
                visible: root.hasData && root.env !== null
                columns: 4
                columnSpacing: Kirigami.Units.largeSpacing
                rowSpacing: 2

                component Key: PlasmaComponents3.Label {
                    font: Kirigami.Theme.smallFont
                    color: Kirigami.Theme.disabledTextColor
                }
                component Value: PlasmaComponents3.Label {
                    font: Kirigami.Theme.smallFont
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Key { text: i18n("Mode") }
                Pill {
                    text: root.env ? String(root.env.connection_mode || "—").toUpperCase() : ""
                    tint: root.env && root.env.connection_mode === "sftp" ? Utils.palette.warn : Utils.palette.ok
                    small: true
                }
                Key { text: i18n("Created") }
                Value { text: root.env ? Utils.relTime(root.env.created, root.now) : "" }

                Key { text: i18n("PHP"); visible: !!(root.env && root.env.php_version) }
                Value { text: root.env ? (root.env.php_version || "") : ""; visible: !!(root.env && root.env.php_version) }
                Key { text: i18n("Drush"); visible: !!(root.env && root.env.drush_version) }
                Value { text: root.env ? (root.env.drush_version || "") : ""; visible: !!(root.env && root.env.drush_version) }

                Key { text: i18n("Domain") }
                PlasmaComponents3.Label {
                    Layout.columnSpan: 3
                    Layout.fillWidth: true
                    text: root.env ? "<a href=\"" + root.env.url + "\">" + root.env.domain + "</a>" : ""
                    textFormat: Text.StyledText
                    font: Kirigami.Theme.smallFont
                    linkColor: Utils.palette.running
                    elide: Text.ElideMiddle
                    onLinkActivated: (link) => Qt.openUrlExternally(link)
                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.NoButton
                        cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                visible: root.hasData && root.env !== null
                spacing: Kirigami.Units.smallSpacing

                PlasmaComponents3.ToolButton {
                    icon.name: "internet-web-browser"
                    text: i18n("Site")
                    onClicked: Qt.openUrlExternally(root.env.url)
                }

                PlasmaComponents3.ToolButton {
                    icon.name: "user-identity"
                    text: i18n("Admin")
                    onClicked: Qt.openUrlExternally(root.env.admin_url)
                }

                PlasmaComponents3.ToolButton {
                    icon.name: root.confirmClear ? "dialog-warning" : "edit-clear-history"
                    text: root.confirmClear ? i18n("Click again to confirm") : i18n("Clear caches")
                    onClicked: root.clearCaches()
                }

                Item { Layout.fillWidth: true }

                PlasmaComponents3.Label {
                    text: root.actionMessage
                    visible: text.length > 0
                    font: Kirigami.Theme.smallFont
                    color: Kirigami.Theme.disabledTextColor
                    elide: Text.ElideLeft
                    Layout.maximumWidth: rep.width * 0.5
                }
            }

            Kirigami.Separator {
                Layout.fillWidth: true
                visible: root.hasData && root.workflows.length > 0
            }

            PlasmaComponents3.ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.hasData && root.workflows.length > 0

                ListView {
                    model: root.workflows
                    clip: true
                    spacing: 2

                    delegate: RowLayout {
                        id: wfRow
                        required property var modelData
                        width: ListView.view.width
                        spacing: Kirigami.Units.smallSpacing

                        StatusDot {
                            status: wfRow.modelData.status
                            implicitWidth: 8
                            implicitHeight: 8
                        }

                        PlasmaComponents3.Label {
                            Layout.fillWidth: true
                            text: wfRow.modelData.workflow || ""
                            font: Kirigami.Theme.smallFont
                            elide: Text.ElideRight
                        }

                        Pill {
                            visible: !!wfRow.modelData.env
                            text: wfRow.modelData.env || ""
                            small: true
                        }

                        PlasmaComponents3.Label {
                            // "jmoss@example.com" → "jmoss"; "Pantheon" / "CI Bot" stay as they are.
                            text: String(wfRow.modelData.user || "").replace(/@.*$/, "")
                            font: Kirigami.Theme.smallFont
                            color: Kirigami.Theme.disabledTextColor
                            elide: Text.ElideRight
                            Layout.maximumWidth: rep.width * 0.25
                        }

                        PlasmaComponents3.Label {
                            text: {
                                const when = Utils.relTime(wfRow.modelData.finished_at || wfRow.modelData.started_at, root.now);
                                const took = wfRow.modelData.time && wfRow.modelData.time !== "0s" ? wfRow.modelData.time : "";
                                return [when, took].filter(Boolean).join(" · ");
                            }
                            font: Kirigami.Theme.smallFont
                            color: Kirigami.Theme.disabledTextColor
                        }
                    }
                }
            }

            Item {
                Layout.fillHeight: true
                visible: root.hasData && root.workflows.length === 0
            }

            PlasmaComponents3.Label {
                Layout.fillWidth: true
                visible: root.configured && !root.offWork
                text: root.followText + (root.site && root.site.guessed ? i18n(" · site name guessed from the repository") : "")
                font: Kirigami.Theme.smallFont
                color: Kirigami.Theme.disabledTextColor
                elide: Text.ElideRight
            }
        }
    }
}
