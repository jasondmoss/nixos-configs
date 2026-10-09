{ lib, pkgs, ... }:

let
    # Proton VPN only looks for a tray (org.kde.StatusNotifierWatcher, hosted
    # by kded6 under Plasma) once, at startup; without one it ignores
    # --start-minimized and opens its window. Wait up to 30 s for the watcher.
    waitForTray = pkgs.writeShellScript "wait-for-tray" ''
        for _ in {1..60}; do
            ${pkgs.systemd}/bin/busctl --user status org.kde.StatusNotifierWatcher >/dev/null 2>&1 && exit 0
            sleep 0.5
        done
        exit 1
    '';
in {
    services = {
        dbus.enable = true;
        devmon.enable = true;
        fstrim.enable = true;
        gnome.gcr-ssh-agent.enable = false;
        gnome.gnome-keyring.enable = true;
        irqbalance.enable = true;
        pcscd.enable = true;

        # Firmware updates via LVFS (fwupdmgr refresh && fwupdmgr update):
        # Samsung NVMe, Logitech receivers and UEFI dbx all ship there.
        fwupd.enable = true;

        # Cap the journal.
        journald.settings.Journal.SystemMaxUse = "1G";
        sysstat.enable = true;
        systembus-notify.enable = lib.mkForce true;

        earlyoom = {
            enable = true;
            enableNotifications = true;
            freeMemThreshold = 5;   # % of RAM
            freeSwapThreshold = 10; # % of swap
        };

        locate = {
            enable = true;
            interval = "hourly";
            package = pkgs.plocate;
        };
    };

    systemd = {
        user.services = {
            megasync = {
                description = "MEGAsync Cloud Sync application";
                after = [ "graphical-session.target" ];
                partOf = [ "graphical-session.target" ];  # stop at logout, not crash-loop without a display
                wantedBy = [ "graphical-session.target" ];

                serviceConfig = {
                    Type = "simple";
                    ExecStart = "${pkgs.megasync}/bin/megasync";
                    # MEGAsync is Qt 5. The session's QML2_IMPORT_PATH also lists
                    # Plasma's qt-6/qml trees, whose qmldirs Qt 5 rejects ("invalid
                    # version auto"), so its QML dialogs never build and opening one
                    # segfaults in QmlDialogWrapperBase::show. The wrapper's
                    # NIXPKGS_QT5_QML_IMPORT_PATH already carries its own modules.
                    UnsetEnvironment = "QML2_IMPORT_PATH";
                    # IPv4 only: over the Proton VPN, MEGA's API never answers on its
                    # IPv6 addresses and libcurl does not fall back, so MEGAsync hangs
                    # at "logging in". Without AF_INET6 every IPv6 attempt fails at once.
                    RestrictAddressFamilies = "AF_UNIX AF_INET AF_NETLINK";
                    Restart = "on-failure";
                    RestartSec = "5s";
                };
            };

            # Starts in the tray; the server it connects to comes from the
            # app's own "Connect at app startup" setting
            # (~/.config/Proton/VPN/app-config.json), not from here.
            protonvpn = {
                description = "Proton VPN";
                after = [ "graphical-session.target" "plasma-kded6.service" "plasma-plasmashell.service" ];
                partOf = [ "graphical-session.target" ];
                wantedBy = [ "graphical-session.target" ];

                serviceConfig = {
                    Type = "simple";
                    ExecStartPre = "-${waitForTray}";  # "-": start anyway if no tray shows up
                    ExecStart = "${pkgs.proton-vpn}/bin/protonvpn-app --start-minimized";
                    Restart = "on-failure";
                    RestartSec = "5s";
                };
            };

            "drkonqi-coredump-launcher@".enable = false;
        };
    };
}

# <> #
