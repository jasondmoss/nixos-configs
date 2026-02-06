{
    lib, stdenv, cmake, extra-cmake-modules, qt6, kdePackages,
    copyDesktopItems, makeDesktopItem
}:

stdenv.mkDerivation {
    pname = "gemini-desktop";
    version = "1.0.0";

    src = ../../workshop/gemini-desktop;

    nativeBuildInputs = [
        cmake
        extra-cmake-modules
        qt6.wrapQtAppsHook
        copyDesktopItems
    ];

    buildInputs = [
        qt6.qtbase
        qt6.qtdeclarative
        qt6.qtwebengine
        kdePackages.kstatusnotifieritem
        kdePackages.kirigami
    ];

    desktopItems = [
        (makeDesktopItem {
            name = "gemini-desktop";
            desktopName = "Gemini Desktop";
            genericName = "AI Assistant";
            exec = "gemini-desktop";
            icon = "google-gemini";
            categories = [ "Network" "Utility" "Qt" "KDE" ];
            keywords = [ "ai" "gemini" "google" "chat" ];
            comment = "Native Gemini wrapper for Plasma";
        })
    ];

    # We remove installPhase entirely.
    # CMake handles the binary installation automatically.
    # We only keep postInstall for the custom icon.
    postInstall = ''
        install -Dm644 $src/google-gemini.svg $out/share/icons/hicolor/scalable/apps/google-gemini.svg
    '';

    meta = with lib; {
        description = "KDE-native Google Gemini wrapper";
        license = licenses.mit;
        platforms = platforms.linux;
        mainProgram = "gemini-desktop";
    };
}
