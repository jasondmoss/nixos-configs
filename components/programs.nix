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

        neovim = {
            enable = true;
            defaultEditor = true;
            viAlias = true;
            vimAlias = true;
            withNodeJs = true;
            withPython3 = true;
        };

#         firefox = {
#             enable = true;
#             package = pkgs.firefox;
#             policies.SearchEngines = {
#                 Default = "DuckDuckGo";
#                 Remove = [ "Bing" "Google" "Amazon.ca" "eBay" ];
#             };
#             preferences = {
#                 "widget.use-xdg-desktop-portal.file-picker" = 1;
#             };
#         };

        _1password.enable = true;
        _1password-gui = {
            enable = true;
            polkitPolicyOwners = [ "team-originoutside" ];
            package = pkgs._1password-gui-beta;
        };
    };

}
