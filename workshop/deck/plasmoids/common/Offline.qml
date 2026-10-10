/*
    Shown instead of a card body while the agent cannot be reached.
    SPDX-License-Identifier: GPL-2.0-or-later
*/
import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3

ColumnLayout {
    id: offline

    property string message: ""
    property string icon: "network-disconnect"

    spacing: Kirigami.Units.smallSpacing

    Item { Layout.fillHeight: true }

    Kirigami.Icon {
        Layout.alignment: Qt.AlignHCenter
        source: offline.icon
        Layout.preferredWidth: Kirigami.Units.iconSizes.large
        Layout.preferredHeight: Kirigami.Units.iconSizes.large
        opacity: 0.6
    }

    PlasmaComponents3.Label {
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
        text: offline.message
        wrapMode: Text.WordWrap
        color: Kirigami.Theme.disabledTextColor
    }

    Item { Layout.fillHeight: true }
}
