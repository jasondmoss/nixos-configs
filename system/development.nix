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

    systemd.user.services.ssh-key-pollen = {
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
}

# <> #
