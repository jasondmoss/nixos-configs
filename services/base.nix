{ lib, options, pkgs, ... }:

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
        fstrim.enable = true;
        irqbalance.enable = true;

        # Firmware updates via LVFS (fwupdmgr refresh && fwupdmgr update):
        # Samsung NVMe, Logitech receivers and UEFI dbx all ship there.
        fwupd.enable = true;

        # Cap the journal.
        journald.settings.Journal.SystemMaxUse = "1G";
        systembus-notify.enable = lib.mkForce true;

        earlyoom = {
            enable = true;
            enableNotifications = true;
            freeMemThreshold = 5;   # % of RAM
            freeSwapThreshold = 10; # % of swap
        };

        locate = {
            enable = true;
            interval = "daily";
            package = pkgs.plocate;
            prunePaths = options.services.locate.prunePaths.default ++ [ "/var/lib/docker" ];
        };
    };

    environment.etc = {
        "xdg/autostart/claude-desktop.desktop".text = ''
            [Desktop Entry]
            Type=Application
            Name=Claude
            Icon=claude-desktop
            Exec=claude-desktop --startup
        '';

        "xdg/autostart/1password.desktop".text = ''
            [Desktop Entry]
            Type=Application
            Name=1Password
            Icon=1password
            Exec=1password --silent
        '';

        "xdg/autostart/standard-notes.desktop".text = ''
            [Desktop Entry]
            Type=Application
            Name=Standard Notes
            Icon=standard-notes
            Exec=standardnotes --hidden
        '';
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
                    UnsetEnvironment = "QML2_IMPORT_PATH";
                    RestrictAddressFamilies = "AF_UNIX AF_INET AF_NETLINK";
                    Restart = "on-failure";
                    RestartSec = "5s";
                };
            };

            # Starts in the tray; the server it connects to comes from the
            # app's own "Connect at app startup" setting.
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
            drkonqi-coredump-pickup.enable = false;
        };

        user.sockets.drkonqi-coredump-launcher.enable = false;
    };
}

# <> #
