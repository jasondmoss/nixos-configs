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

        pipewire = {
            enable = true;
            audio.enable = true;
            jack.enable = true;
            pulse.enable = true;

            alsa = {
                enable = true;
                support32Bit = true;
            };
        };
    };

    systemd = {
        services.nix-index-database-update = {
            description = "Update nix-index database";
            serviceConfig = {
                Type = "oneshot";
                # Run as your user so database is available in ~/.cache/nix-index
                User = "me";
                Environment = "HOME=/home/me";
                # Download nix-community's prebuilt weekly index instead of
                # indexing all of nixpkgs locally (~20–30 min of CPU and a
                # narinfo fetch per store path, every week).
                ExecStart = pkgs.writeShellScript "nix-index-fetch" ''
set -euo pipefail
dir="$HOME/.cache/nix-index"
mkdir -p "$dir"
${pkgs.curl}/bin/curl -fsSL --retry 3 --retry-delay 10 -o "$dir/files.tmp" \
    https://github.com/nix-community/nix-index-database/releases/latest/download/index-x86_64-linux
mv "$dir/files.tmp" "$dir/files"
                '';
            };
        };

        timers.nix-index-database-update = {
            description = "Weekly update of nix-index database";

            timerConfig = {
                OnCalendar = "weekly";
                Persistent = true; # Run immediately if the system was off during scheduled time
            };

            wantedBy = [ "timers.target" ];
        };

        user.services = {
            ssh-key-pollen = {
                description = "Load SSH keys into agent via KWallet";
                wantedBy = [ "graphical-session.target" ];
                partOf = [ "graphical-session.target" ];

                serviceConfig = {
                    ExecStart = lib.concatStringsSep " && " [
                        "${pkgs.bash}/bin/bash -c '${pkgs.openssh}/bin/ssh-add %h/.ssh/id_ed25519_2026_jasondmoss'"
                        "${pkgs.bash}/bin/bash -c '${pkgs.openssh}/bin/ssh-add %h/.ssh/id_ed25519_2026_originoutside'"
                        "${pkgs.bash}/bin/bash -c '${pkgs.openssh}/bin/ssh-add %h/.ssh/id_ed25519_2026_bitbucket'"
                        "${pkgs.bash}/bin/bash -c '${pkgs.openssh}/bin/ssh-add %h/.ssh/id_ed25519_2026_gitlab < /dev/null'"
                    ];
                    Type = "oneshot";
                    RemainAfterExit = "yes";
                };
            };

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
