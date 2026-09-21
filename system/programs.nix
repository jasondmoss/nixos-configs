{ pkgs, ... }: {
    programs = {
        bash.completion.enable = true;
        command-not-found.enable = false;
        direnv.enable = true;
        gamemode.enable = true;
        kdeconnect.enable = true;
        mtr.enable = true;
        nix-ld.enable = true;
        xwayland.enable = true;

        steam = {
            enable = true;
            # No game servers are hosted here — keep 27015 closed.
            dedicatedServer.openFirewall = false;
            remotePlay.openFirewall = true;
        };

        gnupg.agent = {
            enable = true;
            pinentryPackage = pkgs.pinentry-qt;
        };

        nix-index = {
            enable = true;
            enableBashIntegration = true;
        };

        neovim = {
            enable = true;
            defaultEditor = true;
            viAlias = true;
            vimAlias = true;
            withNodeJs = true;
            withPython3 = true;
        };

        _1password.enable = true;
        _1password-gui = {
            enable = true;
            # Local unix user(s) allowed to use 1Password's polkit policy
            # (system-authentication unlock). Must be a real account here.
            polkitPolicyOwners = [ "me" ];
            package = pkgs._1password-gui;
        };
    };

    # nix-index database: download nix-community's prebuilt weekly index
    # instead of indexing all of nixpkgs locally.
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
    };
}

# <> #
