{
    alsa-lib, autoPatchelfHook, fetchurl, gtk3, gtk4, libdrm, libnotify, qt6,
    makeDesktopItem, makeWrapper, nss, lib, mesa, stdenv, udev, xdg-utils, xorg
}:
with lib;
let
    bits = "x86_64";
    version = "10.135.15-3";
    tarball = "Wavebox_${version}.tar.gz";

    src = fetchurl {
        url = "https://download.wavebox.app/beta/linux/tar/${tarball}";
        sha256 = "sha256-6vVfgv6qp1k4nySzje72xTWDGMjqTw3ZRyVCPkAB9wM=";
    };

    desktopItem = makeDesktopItem rec {
        type = "Application";
        terminal = false;
        name = "Wavebox";
        desktopName = name;
        exec = "wavebox";
        icon = "wavebox";
        mimeTypes = [ "x-scheme-handler/mailto" "text/calendar" ];
        categories = [ "Network" "WebBrowser" ];
    };

    meta = with lib; {
        description = "Wavebox messaging application";
        homepage = "https://wavebox.io";
        maintainers = with maintainers; [ rawkode ];
        platforms = platforms.linux;
        sourceProvenance = with sourceTypes; [ binaryNativeCode ];
        license = licenses.mpl20;
    };
in stdenv.mkDerivation rec {
    pname = "wavebox";
    inherit version;
    inherit meta;
    inherit src;

    # Ignore missing QT5 dependencies.
    autoPatchelfIgnoreMissingDeps = [ "libQt5Widgets.so.5" "libQt5Gui.so.5" "libQt5Core.so.5" ];
    dontPatchELF = true;

    nativeBuildInputs = [ autoPatchelfHook makeWrapper qt6.wrapQtAppsHook ];

    buildInputs = with xorg; [
        libXdmcp
        libXcomposite
        libXScrnSaver
        libXtst
        libxshmfence
        libXdamage
    ] ++ [
        alsa-lib
        gtk3
        nss
        libdrm
        mesa
        gtk4
        qt6.qtbase
    ];

    runtimeDependencies = [ (getLib udev) libnotify gtk4 ];

    installPhase = ''
mkdir -p $out/bin $out/opt/wavebox
cp -r * $out/opt/wavebox

# provide desktop item and icon
mkdir -p $out/share/applications $out/share/icons/hicolor/128x128/apps
ln -s ${desktopItem}/share/applications/* $out/share/applications
ln -s $out/opt/wavebox/product_logo_128.png $out/share/icons/hicolor/128x128/apps/wavebox.png
    '';

    postFixup = ''
makeWrapper $out/opt/wavebox/wavebox-launcher $out/bin/wavebox --prefix PATH : ${xdg-utils}/bin
    '';
}
