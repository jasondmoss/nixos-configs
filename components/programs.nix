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
                # Default Identity (Personal)
                user = {
                    name = "Jason D. Moss";
                    email = "jason@jdmlabs.com";
                };

                init.defaultBranch = "main";

                includeIf."gitdir:~/Repository/origin/".path = "/etc/gitconfig.work";
            };
        };

#        mpv= {
#            enable = true;
#
#            package = (
#                pkgs.mpv-unwrapped.wrapper {
#                    scripts = with pkgs.mpvScripts; [
#                        autosub
#                        sponsorblock
#                        uosc
#                    ];
#
#                    mpv = pkgs.mpv-unwrapped.override {
#                        waylandSupport = true;
#
#                        ffmpeg = pkgs.ffmpeg-full;
#                    };
#                }
#            );
#
#            config = {
#                profile = "high-quality";
#                ytdl-format = "bestvideo+bestaudio";
#                cache-default = 4000000;
#            };
#        };

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
