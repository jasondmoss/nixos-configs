{ pkgs, ... }: {
    programs = {
        kdeconnect.enable = true;
        mtr.enable = true;
        xwayland.enable = true;
        bash.completion.enable = true;

        ssh = {
#            startAgent = true;
            askPassword = pkgs.lib.mkForce "${pkgs.kdePackages.ksshaskpass.out}/bin/ksshaskpass";
        };

        gnupg.agent = {
            enable = true;
            pinentryPackage = pkgs.pinentry-qt;
        };

        git = {
            enable = true;

            config = {
                user.name = "jasondmoss";
                user.email = "jason@jdmlabs.com";
                credential.helper = "cache --timeout=86400";
            };

            lfs.enable = true;
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
            package = pkgs._1password-gui-beta;
        };
    };
}

# <> #
