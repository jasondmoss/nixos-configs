{ pkgs, ... }:
let
    googleChromeDesktopItem = pkgs.makeDesktopItem rec {
        type = "Application";
        terminal = false;
        name = "google-chrome-stable";
        desktopName = "Google Chrome (Stable)";
        exec = "google-chrome-stable --use-gl=desktop --enable-features=VaapiVideoDecoder %U";
        icon = "/home/me/Mega/Images/Icons/Apps/google-chrome.png";
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
        startupNotify = true;
        categories = [ "Network" "WebBrowser" ];
        actions = {
            NewWindow = {
                name = "Open a New Window";
                exec = "google-chrome-stable --use-gl=desktop --enable-features=VaapiVideoDecoder --new-window %U";
            };

            NewPrivateWindow = {
                name = "Open a New Private Window";
                exec = "google-chrome-stable --use-gl=desktop --enable-features=VaapiVideoDecoder --incognito %U";
            };
        };
    };
in {
    environment.systemPackages = (with pkgs; [

        #-- Create desktop entry.
        googleChromeDesktopItem

    ]);
}
