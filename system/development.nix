# development.nix
#
# Source-control identity routing. Each repository tree under ~/Repository
# maps to a git identity (includeIf → /etc/gitconfig.<profile>, e-mail
# addresses from ../identity.nix) and to one SSH key per remote host alias;
# ssh-key-pollen loads those keys into the agent at login, with passphrases
# coming from KWallet through ksshaskpass.
{ lib, pkgs, identity, ... }: {
    programs = {
        git = {
            enable = true;
            lfs.enable = true;

            config = {
                credential.helper = "libsecret";
                init.defaultBranch = "main";

                # Global aliases for identity management.
                alias = {
                    whoami = "!git config user.email && git config user.name";
                    id = "!echo '--- Identity ---' && git whoami && echo '--- Remote ---' && git remote -v";
                };

                includeIf = {
                    # GitHub
                    "gitdir/i:/home/me/Repository/work/origin/" .path = "/etc/gitconfig.work";
                    "gitdir/i:/home/me/Repository/work/mmgy/" .path = "/etc/gitconfig.bitbucket";
                    "gitdir/i:/home/me/Repository/personal/" .path = "/etc/gitconfig.personal";
                    # Fallback for your main config repo if it's not in the personal folder.
                    "gitdir/i:/home/me/Repository/system/" .path = "/etc/gitconfig.personal";

                    # GitLab
                    "gitdir/i:/home/me/Repository/work/cyan-solutions/" .path = "/etc/gitconfig.gitlab";
                };
            };
        };

        ssh = {
            startAgent = true;
            askPassword = pkgs.lib.mkForce "${pkgs.kdePackages.ksshaskpass.out}/bin/ksshaskpass";

            extraConfig = ''
AddKeysToAgent yes

Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_2026_jasondmoss
    IdentitiesOnly yes

Host github.com-work
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_2026_originoutside
    IdentitiesOnly yes

Host gitlab.com-gitlab
    HostName gitlab.com
    User git
    IdentityFile ~/.ssh/id_ed25519_2026_gitlab
    IdentitiesOnly yes

Host bitbucket.org
    HostName bitbucket.org
    User git
    IdentityFile ~/.ssh/id_ed25519_2026_bitbucket
    IdentitiesOnly yes

Host pantheon.io *.pantheon.io
    IdentityFile ~/.ssh/id_rsa
    IdentitiesOnly yes

            '';
        };
    };

    # Per-tree identities referenced by programs.git.config.includeIf above.
    environment.etc = {
        "gitconfig.work".text = ''
[user]
    name = Jason D. Moss
    email = ${identity.emailOrigin}
        '';

        "gitconfig.personal".text = ''
[user]
    name = Jason D. Moss
    email = ${identity.emailPersonal}
        '';

        "gitconfig.gitlab".text = ''
[user]
    name = Jason D. Moss
    email = ${identity.emailWork}
        '';

        "gitconfig.bitbucket".text = ''
[user]
    name = Jason D. Moss
    email = ${identity.emailOrigin}
        '';
    };

    environment.variables = {
        SSH_ASKPASS = lib.mkForce "ksshaskpass";
        SSH_ASKPASS_REQUIRE = "prefer";
    };

    # Each key is added on its own, so one failure does not skip the rest; any
    # failure fails the unit, which retries (the session's WAYLAND_DISPLAY can
    # reach the user manager after graphical-session.target starts). Fixed
    # 2026-11-14 — it had never succeeded: ExecStart is not run by a shell (the
    # old `&&` chain only ever ran the first ssh-add), and the unit's minimal
    # service PATH could not resolve the bare SSH_ASKPASS=ksshaskpass, so no
    # passphrase ever came from KWallet. Also replaces the old ~/Mega
    # 1_addssh.sh / 0_ksshaskpass.sh autostart scripts.
    systemd.user.services.ssh-key-pollen = {
        description = "Load SSH keys into agent via KWallet";
        wantedBy = [ "graphical-session.target" ];
        partOf = [ "graphical-session.target" ];
        after = [ "graphical-session.target" ];

        environment = {
            SSH_ASKPASS = "${pkgs.kdePackages.ksshaskpass}/bin/ksshaskpass";
            SSH_ASKPASS_REQUIRE = "prefer";
        };

        script = ''
            failed=0
            for key in \
                id_ed25519_2026_jasondmoss \
                id_ed25519_2026_originoutside \
                id_ed25519_2026_bitbucket \
                id_ed25519_2026_gitlab \
                id_development_cyan \
                id_development_global \
                id_rsa
            do
                ${pkgs.openssh}/bin/ssh-add "$HOME/.ssh/$key" < /dev/null || failed=1
            done
            exit $failed
        '';

        serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            Restart = "on-failure";
            RestartSec = "10s";
        };

        unitConfig = {
            StartLimitIntervalSec = "5min";
            StartLimitBurst = 10;
        };
    };
}

# <> #
