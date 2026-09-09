/**
 * SPDX-License-Identifier: GPL-2.0-or-late[r
 *
 * System Panel — a native Wayland Plasma widget replicating the Conky
 * system-information panel (clock, host, v]ersions, temperatures, network).
 */

import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasma5support as P5Support

PlasmoidItem {
    id: root

    readonly property int cfgColorMode: Plasmoid.configuration.colorMode
    readonly property color cfgCustom: Plasmoid.configuration.customColor
    readonly property bool cfgShadow: Plasmoid.configuration.textShadow
    readonly property string cfgIface: Plasmoid.configuration.netInterface
    readonly property int cfgInterval: Plasmoid.configuration.updateInterval

    readonly property string sep: String.fromCharCode(1)

    // Auto-detected background luminance (0 dark .. 1 light); -1 = unknown.
    property real autoLuma: -1
    readonly property color txtColor: {
        switch (cfgColorMode) {
            case 1: return "white";
            case 2: return "black";
            case 3: return cfgCustom;
            default: return autoLuma < 0
                ? "white"
                : (autoLuma < 0.5 ? "white" : "black");
        }
    }
    readonly property color shadowColor: txtColor.hslLightness > 0.5
        ? Qt.rgba(0, 0, 0, 0.7)
        : Qt.rgba(1, 1, 1, 0.6)
    readonly property int textStyle: cfgShadow ? Text.Outline : Text.Normal

    // Live data.
    property string vHost: ""
    property string vNixFull: ""
    property string vNix: ""
    property string vKernel: ""
    property string vNvidia: ""
    property string vPlasma: ""
    property string vFrameworks: ""
    property string vQt: ""
    property string vPlatform: ""
    property string sCpu: "—"
    property string sGpu: "—"
    property string sUptime: "—"
    property string sDown: "0.0"
    property string sVanc: ""
    property double _lastRx: -1
    property double _lastT: 0

    preferredRepresentation: fullRepresentation

    /**
     * Show a standard widget background, toggleable via the hover toolbar's
     * "Show Background" button (like the monitor widgets).
     */
    Plasmoid.backgroundHints: PlasmaCore.Types.DefaultBackground
        | PlasmaCore.Types.ConfigurableBackground

    P5Support.DataSource {
        id: exec
        engine: "executable"
        connectedSources: []
        onNewData: (source, data) => {
            const out = (data["stdout"] || "").trim();
            disconnectSource(source);
            if (source.indexOf("#versions") !== -1) {
                const f = out.split(root.sep);
                if (f.length >= 9) {
                    root.vHost = f[0];
                    root.vNixFull = f[1];
                    root.vNix = f[2];
                    root.vKernel = f[3];
                    root.vNvidia = f[4];
                    root.vPlasma = f[5];
                    root.vFrameworks = f[6];
                    root.vQt = f[7];
                    root.vPlatform = f[8];
                }
            } else if (source.indexOf("#sensors") !== -1) {
                const f = out.split(root.sep);
                if (f.length >= 4) {
                    root.sCpu = f[0] || "—";
                    root.sGpu = f[1] || "—";
                    root.sUptime = f[2] || "—";

                    const rx = parseFloat(f[3]);
                    const t = Date.now() / 1000;
                    if (root._lastRx >= 0 && t > root._lastT) {
                        const kbps = (rx - root._lastRx) / 1024 / (t - root._lastT);
                        root.sDown = (kbps < 0 ? 0 : kbps).toFixed(1);
                    }
                    root._lastRx = rx; root._lastT = t;
                }
            } else if (source.indexOf("#luma") !== -1) {
                const v = parseFloat(out);
                if (!isNaN(v) && v >= 0) {
                    root.autoLuma = v;
                }
            } else if (source.indexOf("#vanc") !== -1) {
                root.sVanc = out;
            }
        }
    }

    function refreshVersions()
    {
        exec.connectSource(
            "printf '%s\\001%s\\001%s\\001%s\\001%s\\001%s\\001%s\\001%s\\001%s'" +
            " \"$(hostname)\"" +
            " \"$(nixos-version)\"" +
            " \"$(nixos-version | grep -oP '^[0-9]+\\.[0-9]+')\"" +
            " \"$(uname -r)\"" +
            " \"$(nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null)\"" +
            " \"$(plasmashell --version | cut -d' ' -f2)\"" +
            " \"$(kded6 --version 2>/dev/null | grep -oP '6\\.[0-9]+\\.[0-9]+')\"" +
            " \"$(qmake6 -query QT_VERSION 2>/dev/null)\"" +
            " \"$(echo ${XDG_SESSION_TYPE^})\" #versions");
    }

    function refreshSensors()
    {
        /**
         * Fields are SOH-delimited: CPU temp, GPU temp, uptime, rx bytes. Uses
         * shell arithmetic instead of awk to avoid nested-quote escaping
         * through the executable engine (awk format strings were the failure).
         */
        exec.connectSource(
            "printf '%s\\001%s\\001%s\\001%s'" +
            " \"$(d=$(dirname $(grep -lx k10temp /sys/class/hwmon/hwmon*/name 2>/dev/null | head -1) 2>/dev/null); [ -n \\\"$d\\\" ] && echo $(($(cat $d/temp1_input)/1000)))\"" +
            " \"$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader 2>/dev/null)\"" +
            " \"$(u=$(cut -d. -f1 /proc/uptime); echo $((u/3600))h $((u/60%60))m)\"" +
            " \"$(cat /sys/class/net/" + cfgIface + "/statistics/rx_bytes 2>/dev/null || echo 0)\"" +
            " #sensors" + Date.now());
    }

    function refreshLuma()
    {
        exec.connectSource(
            "p=$(grep -m1 '^Image=' ~/.config/plasma-org.kde.plasma.desktop-appletsrc | cut -d= -f2- | sed 's#^file://##'); " +
            "[ -f \"$p\" ] && magick \"$p\" -gravity NorthEast -crop 22%x55%+0+3% +repage -resize 1x1 -colorspace Gray -format '%[fx:mean]' info: 2>/dev/null || echo -1" +
            " #luma" + Date.now());
    }

    /**
     * Qt's QML toLocaleTimeString ignores the timeZone option, so a second
     * timezone is fetched from the shell (correct across DST).
     */
    function refreshVanc()
    {
        exec.connectSource(
            "TZ='America/Vancouver' date '+%-I:%M %p' #vanc" + Date.now()
        );
    }

    Component.onCompleted: {
        refreshVersions();
        refreshSensors();
        refreshLuma();
        refreshVanc();
    }

    Timer {
        interval: root.cfgInterval * 1000;
        running: true;
        repeat: true;
        onTriggered: root.refreshSensors()
    }

    Timer {
        interval: 3600000;
        running: true;
        repeat: true;
        onTriggered: root.refreshVersions()
    }

    Timer {
        interval: 30000;
        running: true;
        repeat: true;
        onTriggered: root.refreshLuma()
    }

    Timer {
        interval: 15000;
        running: true;
        repeat: true;
        onTriggered: root.refreshVanc()
    }

    property var now: new Date()
    Timer {
        interval: 1000;
        running: true;
        repeat: true;
        onTriggered: root.now = new Date()
    }

    // 12-hour clock, no AM/PM, no locale punctuation.
    function clock12(d)
    {
        let h = d.getHours() % 12; if (h === 0) h = 12;

        return h + ":" + String(d.getMinutes()).padStart(2, "0");
    }

    fullRepresentation: Item {
        id: rep
        implicitWidth: 300
        implicitHeight: column.implicitHeight
        Layout.minimumWidth: 160
        Layout.minimumHeight: column.implicitHeight
        Layout.preferredWidth: 300
        Layout.preferredHeight: column.implicitHeight

        component InfoLine: RowLayout {
            Layout.fillWidth: true
            property alias label: l.text
            property alias value: v.text
            property int fs: 11

            PlasmaComponents.Label {
                id: l
                color: root.txtColor
                font.pointSize: fs
                style: root.textStyle
                styleColor: root.shadowColor
            }

            Item {
                Layout.fillWidth: true
            }

            PlasmaComponents.Label {
                id: v
                color: root.txtColor
                font.pointSize: fs
                horizontalAlignment: Text.AlignRight
                style: root.textStyle
                styleColor: root.shadowColor
            }
        }

        ColumnLayout {
            id: column
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            spacing: 0

            PlasmaComponents.Label {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignRight
                text: root.clock12(root.now)
                color: root.txtColor
                font.pixelSize: 72
                font.weight: Font.Light
                style: root.textStyle
                styleColor: root.shadowColor
            }

            PlasmaComponents.Label {
                Layout.fillWidth: true
                Layout.topMargin: 6
                horizontalAlignment: Text.AlignRight
                text: root.sVanc
                visible: root.sVanc !== ""
                color: root.txtColor
                font.pixelSize: 20
                style: root.textStyle
                styleColor: root.shadowColor
            }

            PlasmaComponents.Label {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignRight
                text: root.now.toLocaleDateString("en-CA", {
                    weekday: "long",
                    month: "long",
                    day: "numeric"
                })
                color: root.txtColor
                font.pixelSize: 14
                style: root.textStyle
                styleColor: root.shadowColor
            }

            Item {
                Layout.preferredHeight: 18
            }

            InfoLine {
                label: "Host:";
                value: root.vHost
            }

            PlasmaComponents.Label {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignRight
                text: root.vNixFull
                color: root.txtColor
                font.pixelSize: 11
                elide: Text.ElideLeft
                style: root.textStyle
                styleColor: root.shadowColor
            }

            Item {
                Layout.preferredHeight: 10
            }

            InfoLine {
                label: "NixOS:";
                value: root.vNix
            }

            InfoLine {
                label: "Kernel:";
                value: root.vKernel + " (64-bit)"
            }

            InfoLine {
                label: "NVIDIA Driver:";
                value: root.vNvidia
            }

            InfoLine {
                label: "KDE Plasma:";
                value: root.vPlasma
            }

            InfoLine {
                label: "KDE Frameworks:";
                value: root.vFrameworks
            }

            InfoLine {
                label: "Qt:";
                value: root.vQt
            }

            InfoLine {
                label: "Platform:";
                value: root.vPlatform
            }

            Item {
                Layout.preferredHeight: 14
            }

            InfoLine {
                label: "AMD Ryzen 9 3900X:";
                value: root.sCpu + "°C";
                fs: 13
            }

            InfoLine {
                label: "RTX 5060 Ti:";
                value: root.sGpu + "°C";
                fs: 13
            }

            InfoLine {
                label: "Uptime:";
                value: root.sUptime;
                fs: 13
            }

            InfoLine {
                label: "Download:";
                value: root.sDown + " Kb/sec";
                fs: 13
            }
        }
    }
}
