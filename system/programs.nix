{ pkgs, ... }: {
    programs = {
        bash.completion.enable = true;
        command-not-found.enable = false;
        direnv.enable = true;
        kdeconnect.enable = true;
        mtr.enable = true;
        xwayland.enable = true;

        # The module's base set (systemd + nix deps) is merged in automatically;
        # these extras let Playwright's prebuilt Chromium in ~/.cache/ms-playwright
        # start — needed by the Axe MCP Server (npx axe-mcp-server, Claude Code
        # axe-accessibility plugin) and any other npx/Playwright tooling.
        nix-ld = {
            enable = true;
            libraries = with pkgs; [
                alsa-lib at-spi2-core cairo cups dbus expat glib libgbm
                libx11 libxcb libxcomposite libxdamage libxext libxfixes
                libxkbcommon libxrandr nspr nss pango
            ];
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
            polkitPolicyOwners = [ "me" ];
            package = pkgs._1password-gui;
        };
    };

    systemd = {
        services.nix-index-database-update = {
            description = "Update nix-index database";
            serviceConfig = {
                Type = "oneshot";
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
                Persistent = true;
            };

            wantedBy = [ "timers.target" ];
        };
    };
}

# <> #
