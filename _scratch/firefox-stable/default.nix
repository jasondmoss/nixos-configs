{ pkgs, ... }:
let
    firefoxStableDesktopItem = pkgs.makeDesktopItem rec {
        type = "Application";
        terminal = false;
        name = "firefox-stable";
        desktopName = "Firefox Stable";
        exec = "firefox-stable -P \"Stable\" %u";
        icon = "/home/me/Mega/Images/Icons/Apps/firefox.png";
        mimeTypes = [
            "application/vnd.mozilla.xul+xml"
            "application/xhtml+xml"
            "text/html"
            "text/xml"
            "x-scheme-handler/ftp"
            "x-scheme-handler/http"
            "x-scheme-handler/https"
        ];
        categories = [ "Network" "WebBrowser" ];
        actions = {
            NewWindow = {
                name = "Open a New Window";
                exec = "firefox-stable -P \"Stable\" --new-window %u";
            };
            NewPrivateWindow = {
                name = "Open a New Private Window";
                exec = "firefox-stable -P \"Stable\" --private-window %u";
            };
            ProfileSelect = {
                name = "Select a Profile";
                exec = "firefox-stable --ProfileManager";
            };
        };
    };
in {
    environment.systemPackages = (with pkgs; [
        (pkgs.runCommand "latest.firefox-bin" {
            preferLocalBuild = true;
        } ''
mkdir -p $out/bin
ln -s ${firefox-bin}/bin/firefox $out/bin/firefox-stable
        '')

        #-- Create desktop entry.
        firefoxStableDesktopItem
    ]);
}
