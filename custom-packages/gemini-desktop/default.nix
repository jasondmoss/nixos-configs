{ lib, python3Packages, qt6, makeDesktopItem, copyDesktopItems }:

python3Packages.buildPythonApplication rec {
    pname = "gemini-desktop";
    version = "1.0.0";

    src = ../../workshop/gemini-desktop;

    format = "other";

    propagatedBuildInputs = with python3Packages; [
        pyqt6
        pyqt6-webengine
        dbus-python
        pygobject3
    ];

    nativeBuildInputs = [
        qt6.wrapQtAppsHook
        copyDesktopItems
    ];

    buildInputs = [
        qt6.qtbase
        qt6.qtwayland
        qt6.qtsvg
    ];

    dontConfigure = true;
    dontBuild = true;

    desktopItems = [
        (makeDesktopItem {
            name = "gemini-desktop";
            desktopName = "Gemini Desktop";
            exec = "gemini-desktop %u";
            icon = "gemini-desktop";
            comment = "Google Gemini AI PWA";
            categories = [ "Office" "Network" ];
            startupNotify = true;
        })
    ];

    installPhase = ''
runHook preInstall

mkdir -p $out/bin
cp main.py $out/bin/gemini-desktop
chmod +x $out/bin/gemini-desktop

# Copy the icon to the bin folder so the python script finds it.
cp gemini-desktop.svg $out/bin/gemini-desktop.svg

# Keep this copy for the system menu integration.
mkdir -p $out/share/icons/hicolor/scalable/apps
cp gemini-desktop.svg $out/share/icons/hicolor/scalable/apps/gemini-desktop.svg

runHook postInstall
    '';

    meta = with lib; {
        description = "Custom PWA for Google Gemini";
        license = licenses.mit;
        platforms = platforms.linux;
        mainProgram = "gemini-desktop";
    };
}
