{
    lib, stdenv, cmake, pkg-config, kdePackages, qt6, makeDesktopItem,
    copyDesktopItems
}:

stdenv.mkDerivation rec {
    pname = "proton-suite";
    version = "1.0.2";

    src = ../../workshop/proton-suite;

    nativeBuildInputs = [
        cmake
        pkg-config
        kdePackages.wrapQtAppsHook
        kdePackages.extra-cmake-modules
        copyDesktopItems
    ];

    buildInputs = [
        qt6.qtbase
        qt6.qtdeclarative
        qt6.qtwebengine
        kdePackages.kirigami
        kdePackages.kcoreaddons
        kdePackages.ki18n
        kdePackages.kstatusnotifieritem
        kdePackages.kglobalaccel
        kdePackages.kwindowsystem
        kdePackages.kdbusaddons
    ];

    desktopItems = [
        (makeDesktopItem {
            name = "proton-suite";
            desktopName = "Proton Suite";
            genericName = "Encrypted Workspace";
            exec = "proton-suite";
            icon = "proton-suite";
            comment = "Proton Mail, Drive, Calendar, and Pass";
            categories = [ "Office" "Network" "Email" ];
            startupNotify = true;
            extraConfig = {
                StartupWMClass = "proton-suite";
            };
        })
    ];

    meta = with lib; {
        description = "Proton Suite PWA for KDE Plasma";
        license = licenses.mit;
        platforms = platforms.linux;
        maintainers = [ "Jason D. Moss" ];
        mainProgram = "proton-suite";
    };
}
