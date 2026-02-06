{ pkgs, ... }: {
    programs = {
        kdeconnect.enable = true;
        mtr.enable = true;
        xwayland.enable = true;
        bash.completion.enable = true;

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
    IdentityFile /home/me/.ssh/id_ed25519_2026_gitlab
    IdentitiesOnly yes

Host pantheon.io *.pantheon.io
    IdentityFile ~/.ssh/id_rsa
    IdentitiesOnly yes
            '';
        };

        gnupg.agent = {
            enable = true;
            pinentryPackage = pkgs.pinentry-qt;
        };

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
                    "gitdir/i:/home/me/Repository/personal/" .path = "/etc/gitconfig.personal";
                    # Fallback for your main config repo if it's not in the personal folder.
                    "gitdir/i:/home/me/Repository/system/" .path = "/etc/gitconfig.personal";

                    # GitLab
                    "gitdir/i:/home/me/Repository/work/cyan-solutions/" .path = "/etc/gitconfig.gitlab";
                };
            };
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
            polkitPolicyOwners = [ "team-originoutside" ];
            package = pkgs._1password-gui;
        };
    };
}

# <> #
