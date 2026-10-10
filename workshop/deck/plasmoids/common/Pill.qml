/*
    Compact rounded badge: a status word, a count, an environment name.
    SPDX-License-Identifier: GPL-2.0-or-later
*/
import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3

Rectangle {
    id: pill

    property alias text: label.text
    property color tint: Kirigami.Theme.disabledTextColor
    property bool filled: false
    property bool small: false

    implicitWidth: label.implicitWidth + (small ? 10 : 14)
    implicitHeight: label.implicitHeight + (small ? 3 : 5)
    radius: height / 2
    color: filled ? Qt.rgba(tint.r, tint.g, tint.b, 0.9) : Qt.rgba(tint.r, tint.g, tint.b, 0.16)
    border.width: filled ? 0 : 1
    border.color: Qt.rgba(tint.r, tint.g, tint.b, 0.45)

    PlasmaComponents3.Label {
        id: label
        anchors.centerIn: parent
        font.pixelSize: small ? Kirigami.Theme.smallFont.pixelSize : Kirigami.Theme.defaultFont.pixelSize
        font.weight: Font.DemiBold
        color: pill.filled ? "#111" : pill.tint
        elide: Text.ElideRight
    }
}
