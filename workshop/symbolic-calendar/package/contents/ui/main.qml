/*
    Calendar (Symbolic) — Plasma's Calendar widget with a panel icon drawn in
    the panel's text colour instead of the stock white-page image.

    The stock applet (plasma-workspace applets/calendar) paints a full-colour
    mini-calendar SVG from its own resources and prints the day number on it in
    hard-coded black, so it ignores the Plasma Style and Panel Colorizer: on a
    light panel colour the number turns white on the white page. Here the glyph
    is plain shapes plus a label. Panel Colorizer recolours Text/Label/Icon
    items only, so every shape takes its colour from the day label.

    The popup and settings are the stock ones: MonthView with the same
    configuration keys (contents/config/main.xml and configGeneral.qml are
    copied from plasma-workspace 6.7.5).

    Popup layout derived from plasma-workspace's calendar applet:
    SPDX-FileCopyrightText: 2013 Heena Mahour <heena393@gmail.com>
    SPDX-FileCopyrightText: 2013 Sebastian Kügler <sebas@kde.org>
    SPDX-FileCopyrightText: 2016 Kai Uwe Broulik <kde@privat.broulik.de>

    SPDX-License-Identifier: GPL-2.0-or-later
*/
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.clock
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami
import org.kde.plasma.workspace.calendar

PlasmoidItem {
    id: root

    switchWidth: Kirigami.Units.gridUnit * 12
    switchHeight: Kirigami.Units.gridUnit * 12

    toolTipMainText: Qt.formatDate(clockSource.dateTime, "dddd")
    toolTipSubText: {
        // As the stock applet: drop "dddd" (always first or last in
        // LongFormat) plus its delimiter from the locale's long date.
        var format = Qt.locale().dateFormat(Locale.LongFormat);
        format = format.replace(/(^dddd.?\s)|(,?\sdddd$)/, "");
        return Qt.formatDate(clockSource.dateTime, format);
    }

    Layout.minimumWidth: Kirigami.Units.iconSizes.large
    Layout.minimumHeight: Kirigami.Units.iconSizes.large

    Clock {
        id: clockSource
    }

    // ISO 8601 week number — what QDate::weekNumber() returns for the stock
    // applet's "w" compact display.
    function isoWeek(date) {
        const d = new Date(Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()));
        const weekday = d.getUTCDay() || 7;
        d.setUTCDate(d.getUTCDate() + 4 - weekday);
        const yearStart = new Date(Date.UTC(d.getUTCFullYear(), 0, 1));
        return Math.ceil(((d - yearStart) / 86400000 + 1) / 7);
    }

    compactRepresentation: MouseArea {
        id: compact

        onClicked: root.expanded = !root.expanded

        Item {
            id: glyph

            anchors.centerIn: parent
            width: Kirigami.Units.iconSizes.roundedIconSize(Math.min(compact.width, compact.height))
            height: width

            // Everything below is drawn in the day label's colour.
            readonly property color ink: dayLabel.color
            readonly property real stroke: Math.max(1, Math.round(width / 14))

            // Binder rings, poking out above the page.
            Repeater {
                model: [0.3, 0.7]

                Rectangle {
                    required property real modelData

                    width: Math.max(2, Math.round(glyph.stroke * 1.6))
                    height: Math.round(glyph.height * 0.24)
                    x: Math.round(glyph.width * modelData - width / 2)
                    y: 0
                    radius: width / 2
                    color: glyph.ink
                }
            }

            // Page outline.
            Rectangle {
                id: page

                x: 0
                y: Math.round(glyph.height * 0.1)
                width: glyph.width
                height: glyph.height - y
                radius: Math.round(glyph.width * 0.16)
                color: "transparent"
                border.width: glyph.stroke
                border.color: glyph.ink
            }

            // Solid header band: rounded top from the first rectangle, square
            // bottom edge from the second.
            Rectangle {
                id: header

                x: page.x
                y: page.y
                width: page.width
                height: Math.round(page.height * 0.24)
                radius: page.radius
                color: glyph.ink
            }
            Rectangle {
                x: page.x
                y: header.y + header.height - page.radius
                width: page.width
                height: page.radius
                color: glyph.ink
            }

            PlasmaComponents3.Label {
                id: dayLabel

                // The page body below the header. Sized by the body height
                // rather than Text.Fit: Fit makes the whole line box (ascent +
                // descent) fit, which leaves digits — cap height only, no
                // descenders — at ~70 % of the space. At 1.1 × the body height
                // the digits fill it and the line box overflows harmlessly;
                // its centre sits within ~0.03 em of the digits' centre.
                // HorizontalFit still shrinks two-digit dates that are too wide.
                anchors {
                    top: header.bottom
                    bottom: page.bottom
                    left: page.left
                    right: page.right
                    bottomMargin: glyph.stroke
                    leftMargin: glyph.stroke
                    rightMargin: glyph.stroke
                }
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.bold: true
                font.pixelSize: Math.max(6, Math.round(height * 1.1))
                fontSizeMode: Text.HorizontalFit
                minimumPixelSize: 6
                textFormat: Text.PlainText
                text: {
                    const d = new Date(clockSource.dateTime);
                    const format = Plasmoid.configuration.compactDisplay;
                    if (format === "w") {
                        return root.isoWeek(d);
                    }
                    return Qt.formatDate(d, format);
                }
            }
        }
    }

    fullRepresentation: Item {
        // Sizing as in the stock applet (taken there from the digital clock).
        readonly property int _minimumWidth: calendar.showWeekNumbers ? Math.round(_minimumHeight * 1.75) : Math.round(_minimumHeight * 1.5)
        readonly property int _minimumHeight: Kirigami.Units.gridUnit * 14
        readonly property var appletInterface: root

        Layout.minimumWidth: _minimumWidth
        Layout.maximumWidth: Kirigami.Units.gridUnit * 80
        Layout.minimumHeight: _minimumHeight
        Layout.maximumHeight: Kirigami.Units.gridUnit * 40

        MonthView {
            id: calendar
            today: clockSource.dateTime
            showWeekNumbers: Plasmoid.configuration.showWeekNumbers
            anchors.fill: parent
        }
    }
}
