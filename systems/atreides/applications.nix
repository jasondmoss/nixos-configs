{ config, lib, pkgs, ... }:
{
    environment = {
        systemPackages = (with pkgs; [

            #-- EDITORS
            blender
            darktable

            #-- MULTIMEDIA
            audacity
            audible-cli
            cuetools
            easytag

        ]);
    };
}
