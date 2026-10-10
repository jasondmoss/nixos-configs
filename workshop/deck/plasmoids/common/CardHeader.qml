/*
    Title row shared by every card: icon, title, subtitle, status dot and
    tool buttons (declared as children of `actions`).
    SPDX-License-Identifier: GPL-2.0-or-later
*/
import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3

RowLayout {
    id: header

    property string icon: "applications-development"
    property bool maskIcon: false
    property string title: ""
    property string subtitle: ""
    property string status: "muted"
    property bool showDot: true
    default property alias actions: actionRow.data

    spacing: Kirigami.Units.smallSpacing

    Kirigami.Icon {
        source: header.icon
        isMask: header.maskIcon
        color: Kirigami.Theme.textColor
        Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
        Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 0

        PlasmaComponents3.Label {
            Layout.fillWidth: true
            text: header.title
            font.weight: Font.Bold
            elide: Text.ElideRight
        }

        PlasmaComponents3.Label {
            Layout.fillWidth: true
            visible: text.length > 0
            text: header.subtitle
            font: Kirigami.Theme.smallFont
            color: Kirigami.Theme.disabledTextColor
            elide: Text.ElideMiddle
        }
    }

    StatusDot {
        visible: header.showDot
        status: header.status
        Layout.rightMargin: Kirigami.Units.smallSpacing
    }

    RowLayout {
        id: actionRow
        spacing: 0
    }
}
