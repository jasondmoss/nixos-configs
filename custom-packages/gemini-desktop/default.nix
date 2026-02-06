{
    lib, stdenv, cmake, extra-cmake-modules, qt6, kdePackages,
    makeDesktopItem, copyDesktopItems
}:

stdenv.mkDerivation rec {
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
        kdePackages.kglobalaccel
    ];

    # CRITICAL: We inject the sandbox disable flag here.
    # This guarantees it reaches the subprocesses.
    qtWrapperArgs = [
        "--set QTWEBENGINE_DISABLE_SANDBOX 1"
        "--set QML_DISABLE_DISK_CACHE 1" # Optional: forces fresh QML load
    ];

    desktopItems = [
        (makeDesktopItem {
            name = "gemini-desktop";
            desktopName = "Gemini Desktop";
            genericName = "AI Assistant";
            exec = "gemini-desktop";
            icon = "google-gemini";
            categories = [ "Network" "Utility" "Qt" "KDE" ];
        })
    ];

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
