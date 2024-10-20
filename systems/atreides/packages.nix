{ pkgs, ... }: {
    imports = [
        # ../../packages/nvidia
        ../../shared/desktop-entries/mkvtoolnix.nix
    ];

    nixpkgs = {
        config = {
            allowUnfreePredicate = pkg: builtins.elem (pkgs.lib.getName pkg) [
                "steam"
                "steam-run"
                "steam-original"
            ];
        };
    };

    environment = {
        systemPackages = (with pkgs; [

            #-- EDITORS
            blender
            notes
            # standardnotes

            # -- INTERNET
            tor-browser-bundle-bin

            #-- MULTIMEDIA
            audacity
            audible-cli
            cuetools
            easytag
            haruna
            mkvtoolnix
            taglib-sharp
            taglib_extras
            vlc
            kdePackages.phonon-vlc

        ]);
    };
}
