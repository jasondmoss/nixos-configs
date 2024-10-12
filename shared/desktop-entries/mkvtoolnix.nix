{ pkgs, ... }:
let
    mkvToolNixDesktopItem = pkgs.makeDesktopItem rec {
        type = "Application";
        terminal = false;
        name = "mkvtoolnix-gui";
        desktopName = "MKVToolNix GUI";
        genericName = "Matroska files creator and tools";
        exec = "mkvtoolnix-gui --edit-headers %F";
        icon = "mkvtoolnix-gui";
        mimeTypes = [
            "application/x-mkvtoolnix-gui-settings"
            "video/x-matroska-3d"
            "video/x-matroska"
            "audio/x-matroska"
            "video/webm"
            "audio/webm"
        ];
        categories = [ "AudioVideo" "AudioVideoEditing" ];
    };
in {
    environment = {
        systemPackages = (with pkgs; [

            #-- Create desktop entry.
            mkvToolNixDesktopItem

        ]);
    };
}
