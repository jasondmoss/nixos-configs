{ pkgs ? import <nixpkgs> {} }:
let
    protonDesktopItem = pkgs.makeDesktopItem {
        name = "proton-suite";
        desktopName = "Proton Suite";
        genericName = "Proton Mail & Drive Client";
        comment = "Multi-tab access for Proton services with shared session";
        exec = "proton-suite";
        icon = "proton-suite";
        categories = [ "Network" "Email" "Qt" ];
        startupWMClass = "nixos.local.Proton Suite";
        terminal = false;
    };
in pkgs.stdenv.mkDerivation {
    pname = "proton-suite";
    version = "1.0.0";

    src = ../../workshop/proton-suite;

    nativeBuildInputs = with pkgs; [
        cmake
        pkg-config
        qt6.wrapQtAppsHook
        kdePackages.extra-cmake-modules
        copyDesktopItems
    ];

    buildInputs = with pkgs; [
        qt6.qtbase
        qt6.qtdeclarative
        qt6.qtwebengine
        kdePackages.kirigami
        kdePackages.qqc2-desktop-style # Needed for Plasma native styling
        kdePackages.kstatusnotifieritem
    ];

    desktopItems = [ protonDesktopItem ];

    # Force QtWebEngine to look for proprietary codecs (H.264 for ProtonDrive
    # videos)
    cmakeFlags = [
        "-DQT_NO_VERSION_TAGGING=ON"
    ];

    meta = with pkgs.lib; {
        description = "Multi-tabbed Proton Suite PWA";
        license = licenses.mit;
        platforms = platforms.linux;
        mainProgram = "proton-suite";
    };
}
