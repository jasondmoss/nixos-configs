{ config, lib, pkgs, ... }:
{
    environment = {
        systemPackages = (with pkgs; [

            #-- EDITORS
            blender
            darktable
            steam
            tor-browser-bundle-bin

            #-- MULTIMEDIA
            audacity
            audible-cli
            cuetools
            easytag
            vlc

        ]) ++ (with pkgs; [

            #-- Anytype
            (pkgs.callPackage ../../custom/anytype/default.nix {})

            #-- Standard Notes
            (pkgs.callPackage ../../custom/standardnotes/default.nix {})

#            (pkgs.writeShellScriptBin "qemu-system-x86_64-uefi" ''
#qemu-system-x86_64 -bios ${pkgs.OVMF.fd}/FV/OVMF.fd "$@"
#            '')

        ]);
    };
}
