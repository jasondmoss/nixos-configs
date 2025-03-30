{ pkgs, ... }:
let
    floorpDesktopItem = pkgs.makeDesktopItem rec {
        type = "Application";
        terminal = false;
        name = "floorp";
        desktopName = "Floorp";
        exec = "floorp -P \"Floorp\" %u";
        icon = "/home/me/Mega/Images/Icons/Apps/floorp.png";
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
                exec = "floorp -P \"Floorp\" --new-window %u";
            };

            NewPrivateWindow = {
                name = "Open a New Private Window";
                exec = "floorp -P \"Floorp\" --private-window %u";
            };

            ProfileSelect = {
                name = "Select a Profile";
                exec = "floorp --ProfileManager";
            };
        };
    };
in {
    environment.systemPackages = (with pkgs; [

        #-- Rename executable.
        (pkgs.runCommand "floorp-unwrapped" {
            preferLocalBuild = true;
        } ''
mkdir -p $out/bin
ln -s ${floorp-unwrapped}/bin/floorp $out/bin/floorp
        '')

        #-- Create desktop entry.
        floorpDesktopItem

    ]);
}
