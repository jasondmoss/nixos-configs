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
# Personal GitHub (Default)
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_2026_jasondmoss

# Work GitHub
Host github.com-work
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_2026_originoutside
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

                # Global aliases for identity management.
                alias = {
                    # Shows who you are in the current repo (Email/Name).
                    whoami = "!git config user.email && git config user.name";
                    check-personal = "!ssh -T git@github.com";
                    check-work = "!ssh -T git@github.com-work";

                    # Shows a summary of the remote URL and the identity.
                    id = "!echo '--- Identity ---' && git whoami && echo '--- Remote ---' && git remote -v";
                };

                # Default Identity (Personal)
                user = {
                    name = "Jason D. Moss";
                    email = "jason@jdmlabs.com";
                };

                init.defaultBranch = "main";

                includeIf."gitdir:~/Repository/origin/".path = "/etc/gitconfig.work";
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
