{ pkgs, lib, ... }:
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

    nixpkgs.overlays = lib.singleton (final: prev: {
        latest.firefox-nightly-bin = prev.latest.firefox-nightly-bin.overrideAttrs (old: {
            nativeBuildInputs = (old.nativeBuildInputs or []) ++ (with prev; [
                zip
                unzip
                gnused
            ]);
            buildCommand = ''
export buildRoot="$(pwd)"
            '' + old.buildCommand + ''
pushd $buildRoot
unzip $out/lib/firefox-nightly/browser/omni.ja -d patched_omni || ret=$?
if [[ $ret && $ret -ne 2 ]]; then
echo "unzip exited with unexpected error"
exit $ret
fi
rm $out/lib/firefox-nightly/browser/omni.ja
cd patched_omni
sed -i 's/"enterprise_only"\s*:\s*true,//' modules/policies/schema.sys.mjs
zip -0DXqr $out/lib/firefox-nightly/browser/omni.ja * # potentially qr9XD
popd
            '';
        });
    });
}
