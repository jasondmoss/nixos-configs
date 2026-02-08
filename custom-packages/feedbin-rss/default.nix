{ stdenv, lib, qt6, kdePackages, cmake, makeDesktopItem, copyDesktopItems }:

stdenv.mkDerivation rec {
    pname = "feedbin-rss";
    version = "1.0.0";

    src = ../../workshop/feedbin-rss;

    nativeBuildInputs = [
        cmake
        qt6.wrapQtAppsHook
        kdePackages.extra-cmake-modules
        copyDesktopItems # Automatically handles the installation of desktopItems
    ];

    buildInputs = [
        qt6.qtwebengine
        kdePackages.kstatusnotifieritem
        kdePackages.kglobalaccel
        kdePackages.knotifications
        kdePackages.kconfig
        kdePackages.kio
        kdePackages.ki18n
        kdePackages.kjobwidgets
    ];

    desktopItems = [
        (makeDesktopItem {
            name = "feedbin-rss";
            exec = "feedbin-rss %u";
            icon = "feedbin-rss";
            desktopName = "Feedbin RSS";
            genericName = "RSS Reader";
            categories = [ "Network" "News" ];
            startupNotify = true;
            terminal = false;
            extraConfig = {
                StartupWMClass = "feedbin-rss";
            };
        })
    ];

    postInstall = ''
# Install the custom SVG icon to the standard location
install -Dm644 $src/feedbin-rss.svg $out/share/icons/hicolor/scalable/apps/feedbin-rss.svg
    '';

    meta = with lib; {
        description = "Feedbin is a web-based RSS reader designed to provide a clean and efficient experience for consuming content from various online sources";
        license = licenses.gpl3Plus;
        platforms = platforms.linux;
        mainProgram = "feedbin-rss";
    };
}
