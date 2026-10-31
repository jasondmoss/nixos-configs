/*
    Deck: Gulp — standalone widget around the shared GulpCard.
    Its settings (contents/config/main.xml) are read by the card through
    Plasmoid.configuration; the card body lives in ../../../common.

    SPDX-License-Identifier: GPL-2.0-or-later
*/
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    preferredRepresentation: fullRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.DefaultBackground | PlasmaCore.Types.ConfigurableBackground

    fullRepresentation: GulpCard {
        id: card
        Layout.minimumWidth: Kirigami.Units.gridUnit * 16
        Layout.minimumHeight: Kirigami.Units.gridUnit * 8
        Layout.preferredWidth: Kirigami.Units.gridUnit * 28
        Layout.preferredHeight: Kirigami.Units.gridUnit * 16

        Binding { target: root; property: "toolTipMainText"; value: card.tooltipMain }
        Binding { target: root; property: "toolTipSubText"; value: card.tooltipSub }
    }
}
