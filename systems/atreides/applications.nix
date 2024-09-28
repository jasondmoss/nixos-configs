{ config, lib, pkgs, ... }:
{
    environment = {
        systemPackages = (with pkgs; [
            #-- EDITORS
            blender
            geeqie
            steam
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
            # vlc
        ]) ++ (with pkgs; [
            #-- Anytype
            # (pkgs.callPackage ../../custom/anytype/default.nix {})

            #-- Standard Notes
            (pkgs.callPackage ../../custom/standardnotes/default.nix {})
        ]);
    };
}
