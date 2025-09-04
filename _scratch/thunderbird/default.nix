{ config, pkgs, ... }:
let
    thunderbirdDesktopItem = pkgs.makeDesktopItem rec {
        type = "Application";
        terminal = false;
        name = "thunderbird";
        desktopName = "Thunderbird";
        exec = "thunderbird -P \"Me\"";
        icon = "${config.users.users.me.home}/Mega/Images/Icons/Apps/thunderbird-daily.png";
        mimeTypes = [
            "message/rfc822"
            "x-scheme-handler/mailto"
        ];
        startupNotify = true;
        categories = [ "Network" "Email" ];
    };
in {
    environment.systemPackages = (with pkgs; [
        thunderbird-latest

        #-- Create desktop entry.
        thunderbirdDesktopItem
    ]);
}
