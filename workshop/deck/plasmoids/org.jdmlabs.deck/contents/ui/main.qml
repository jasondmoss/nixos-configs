/*
    Deck — the four cards as two tabbed pairs in one widget:
    Git | Gulp, then CircleCI | Pantheon. The cards are the shared components
    in ../../../common; only the Git card reports PhpStorm's windows to the
    agent (one tracker is enough). A card on the hidden tab stops polling
    until it is shown again. The tab buttons carry a status dot summarising
    their two cards, so a failed pipeline or build shows through.

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

    preferredRepresentation: fullRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.DefaultBackground | PlasmaCore.Types.ConfigurableBackground
    toolTipMainText: i18n("Deck")

    /* The more urgent of two card statuses, for the tab dots. */
    function worst(a, b)
    {
        const rank = { error: 4, warn: 3, running: 2, hold: 2, ok: 1, muted: 0 };
        const ka = Utils.statusKey(a), kb = Utils.statusKey(b);
        return (rank[ka] || 0) >= (rank[kb] || 0) ? ka : kb;
    }

    fullRepresentation: Item {
        id: rep
        Layout.minimumWidth: Kirigami.Units.gridUnit * 36
        Layout.minimumHeight: Kirigami.Units.gridUnit * 12
        Layout.preferredWidth: Kirigami.Units.gridUnit * 58
        Layout.preferredHeight: Kirigami.Units.gridUnit * 21

        component DeckTab: PlasmaComponents3.TabButton {
            id: tab
            property string status: "muted"
            rightPadding: Kirigami.Units.gridUnit + Kirigami.Units.smallSpacing

            StatusDot {
                anchors.right: parent.right
                anchors.rightMargin: Kirigami.Units.smallSpacing * 1.5
                anchors.verticalCenter: parent.verticalCenter
                status: tab.status
                opacity: Utils.statusKey(tab.status) === "muted" ? 0.35 : 1
            }
        }

        component Pane: RowLayout {
            spacing: Kirigami.Units.largeSpacing
        }

        component Divider: Kirigami.Separator {
            Layout.fillHeight: true
            Layout.topMargin: Kirigami.Units.smallSpacing
            Layout.bottomMargin: Kirigami.Units.smallSpacing
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: Kirigami.Units.smallSpacing

            PlasmaComponents3.TabBar {
                id: tabs
                Layout.fillWidth: true
                currentIndex: Plasmoid.configuration.currentTab
                onCurrentIndexChanged: Plasmoid.configuration.currentTab = currentIndex

                DeckTab {
                    text: i18n("Git · Gulp")
                    status: root.worst(gitCard.statusWord, gulpCard.statusWord)
                }

                DeckTab {
                    text: i18n("CircleCI · Pantheon")
                    status: root.worst(ciCard.statusWord, pantheonCard.statusWord)
                }
            }

            StackLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: tabs.currentIndex

                Pane {
                    GitCard {
                        id: gitCard
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredWidth: 1
                        port: Plasmoid.configuration.port
                        interval: Plasmoid.configuration.gitInterval
                        trackPhpStorm: Plasmoid.configuration.trackPhpStorm
                        showUntracked: Plasmoid.configuration.showUntracked
                        showPath: Plasmoid.configuration.showPath
                        idleWhenNoProject: Plasmoid.configuration.idleWhenNoProject
                        // Keep reporting PhpStorm's windows while the other tab is shown.
                        polling: true
                    }

                    Divider {}

                    GulpCard {
                        id: gulpCard
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredWidth: 1
                        port: Plasmoid.configuration.port
                        trackPhpStorm: false
                        fontSize: Plasmoid.configuration.fontSize
                        wrapLines: Plasmoid.configuration.wrapLines
                        maxLines: Plasmoid.configuration.maxLines
                        idleWhenNoProject: Plasmoid.configuration.idleWhenNoProject
                    }
                }

                Pane {
                    CircleCiCard {
                        id: ciCard
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredWidth: 1
                        port: Plasmoid.configuration.port
                        interval: Plasmoid.configuration.ciInterval
                        trackPhpStorm: false
                        maxPipelines: Plasmoid.configuration.maxPipelines
                        showJobs: Plasmoid.configuration.showJobs
                        showSubject: Plasmoid.configuration.showSubject
                        idleWhenOffWork: Plasmoid.configuration.idleWhenOffWork
                        // Keep the tab dot current while the other tab is shown.
                        polling: true
                    }

                    Divider {}

                    PantheonCard {
                        id: pantheonCard
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredWidth: 1
                        port: Plasmoid.configuration.port
                        interval: Plasmoid.configuration.pantheonInterval
                        trackPhpStorm: false
                        follow: Plasmoid.configuration.follow
                        pinnedSite: Plasmoid.configuration.pinnedSite
                        maxWorkflows: Plasmoid.configuration.maxWorkflows
                        idleWhenOffWork: Plasmoid.configuration.idleWhenOffWork
                    }
                }
            }
        }
    }
}
