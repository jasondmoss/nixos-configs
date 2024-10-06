{ config, lib, pkgs, ... }: {

    imports = [
        ../../packages/nvidia
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

        ]) ++ (with pkgs; [

            #-- Anytype
            (pkgs.callPackage ../../packages/anytype {})

        ]);
    };

}
