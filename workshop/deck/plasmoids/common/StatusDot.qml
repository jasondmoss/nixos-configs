/*
    A small status disc; pulses while something is running.
    SPDX-License-Identifier: GPL-2.0-or-later
*/
import QtQuick
import "Utils.js" as Utils

Rectangle {
    id: dot

    property string status: "muted"
    property bool pulse: Utils.statusKey(status) === "running"

    implicitWidth: 10
    implicitHeight: 10
    radius: width / 2
    color: Utils.statusColor(status)
    border.width: 1
    border.color: Qt.rgba(1, 1, 1, 0.18)

    SequentialAnimation on opacity {
        running: dot.pulse
        loops: Animation.Infinite
        alwaysRunToEnd: true
        NumberAnimation { to: 0.35; duration: 700; easing.type: Easing.InOutSine }
        NumberAnimation { to: 1.0; duration: 700; easing.type: Easing.InOutSine }
    }
}
