{ config, lib, pkgs, ... }:
{
    imports = [
        ../../custom/nvidia
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
            geeqie
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
            virtualbox
        ]) ++ (with pkgs; [
            #-- Anytype
            (pkgs.callPackage ../../custom/anytype/default.nix {})

            #-- Standard Notes
            (pkgs.callPackage ../../custom/standardnotes/default.nix {})
        ]);
    };
}
