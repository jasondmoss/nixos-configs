# base.nix
#
# Always-on housekeeping daemons that belong to no particular stack: D-Bus,
# removable-media mounting, TRIM, firmware updates (LVFS), journal cap,
# earlyoom, plocate, sysstat — plus the per-session user units (MEGAsync
# autostart; DrKonqi's coredump launcher switched off). Audio is in
# ../desktop/audio.nix, SMART/printing in ../hardware/peripherals.nix.
{ lib, pkgs, ... }: {
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

        # Cap the journal; it had grown to ~4 GiB.
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
            # plocate: io_uring-based, a fraction of mlocate's updatedb time and
            # near-instant queries. The binary is setgid `plocate` via
            # security.wrappers, so no group membership is needed.
            package = pkgs.plocate;
        };
    };

    systemd = {
        user.services = {
            megasync = {
                description = "MEGAsync Cloud Sync application";
                after = [ "graphical-session.target" ];
                wantedBy = [ "graphical-session.target" ];

                serviceConfig = {
                    Type = "simple";
                    ExecStart = "${pkgs.megasync}/bin/megasync";
                    Restart = "on-failure";
                    RestartSec = "5s";
                };
            };

            "drkonqi-coredump-launcher@".enable = false;
        };
    };
}

# <> #
