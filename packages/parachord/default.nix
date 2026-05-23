{ lib, appimageTools, fetchurl }:

let
    pname = "parachord";
    version = "0.9.2";

    src = fetchurl {
        url = "https://github.com/Parachord/parachord/releases/download/v${version}/Parachord-${version}.AppImage";
        hash = "sha256-YOfdYq0Rw/Ug3Sd+SXh0mEIRtNaLw0kBoNDeU+nT4OY=";
    };
in
appimageTools.wrapType2 {
    inherit pname version src;

    extraPkgs = pkgs: with pkgs; [
        libsecret
    ];

    meta = {
        description = "Multi-source desktop music player aggregating streaming services and local audio";
        homepage = "https://github.com/Parachord/parachord";
        license = lib.licenses.mit;
        sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
        platforms = [ "x86_64-linux" ];
        mainProgram = "parachord";
    };
}

# <> #
