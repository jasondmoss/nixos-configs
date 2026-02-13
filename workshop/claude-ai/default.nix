{ stdenv, lib, qt6, kdePackages, cmake, makeDesktopItem, copyDesktopItems }:

stdenv.mkDerivation rec {
    pname = "claude-ai";
    version = "1.0.0";

    src = ./.;

    nativeBuildInputs = [
        cmake
        qt6.wrapQtAppsHook
        kdePackages.extra-cmake-modules
        copyDesktopItems
    ];

    buildInputs = [
        qt6.qtwebengine
        kdePackages.kglobalaccel
        kdePackages.knotifications
        kdePackages.kstatusnotifieritem
    ];

    desktopItems = [
        (makeDesktopItem {
            name = "claude-ai";
            exec = "claude-ai %u";
            icon = "claude-ai";
            desktopName = "Claude AI";
            genericName = "AI Assistant";
            categories = [ "Network" "Utility" ];
            startupNotify = true;
            terminal = false;
            extraConfig = {
                StartupWMClass = "claude-ai";
            };
        })
    ];

    postInstall = ''
        install -Dm644 $src/claude-ai.svg $out/share/icons/hicolor/scalable/apps/claude-ai.svg
    '';

    meta = with lib; {
        description = "Claude AI PWA wrapper for KDE Plasma";
        license = licenses.gpl3Plus;
        platforms = platforms.linux;
        mainProgram = "claude-ai";
    };
}
