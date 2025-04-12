{ pkgs, ... }:
let
    firefoxNightlyDesktopItem = pkgs.makeDesktopItem {
        type = "Application";
        terminal = false;
        name = "firefox-nightly";
        desktopName = "Firefox Nightly";
        exec = "firefox-nightly -P \"Nightly\" %u";
        icon = "/home/me/Mega/Images/Icons/Apps/firefox-developer-edition-alt.png";
        mimeTypes = [
            "application/pdf"
            "application/rdf+xml"
            "application/rss+xml"
            "application/xhtml+xml"
            "application/xhtml_xml"
            "application/xml"
            "image/gif"
            "image/jpeg"
            "image/png"
            "image/webp"
            "text/html"
            "text/xml"
            "x-scheme-handler/http"
            "x-scheme-handler/https"
        ];
        categories = [ "Network" "WebBrowser" ];
        actions = {
            NewWindow = {
                name = "Open a New Window";
                exec = "firefox-nightly -P \"Nightly\" --new-window %u";
            };

            NewPrivateWindow = {
                name = "Open a New Private Window";
                exec = "firefox-nightly -P \"Nightly\" --private-window %u";
            };

            ProfileSelect = {
                name = "Select a Profile";
                exec = "firefox-nightly --ProfileManager";
            };
        };
    };
in {
    environment.systemPackages = (with pkgs; [
        #-- Rename executable.
        (pkgs.runCommand "latest.firefox-nightly-bin" {
            preferLocalBuild = true;
        } ''
mkdir -p $out/bin
ln -s ${latest.firefox-nightly-bin}/bin/firefox-nightly $out/bin/firefox-nightly
        '')

        #-- Create desktop entry.
        firefoxNightlyDesktopItem
    ]);
}
