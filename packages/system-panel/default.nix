{ lib, stdenvNoCC }:

stdenvNoCC.mkDerivation {
    pname = "system-panel";
    version = "0.1.0";

    # Local workshop project — a native Wayland Plasma widget replicating the
    # Conky system-information panel. QML only, no compilation.
    src = ../../workshop/system-panel;

    dontConfigure = true;
    dontBuild = true;

    installPhase = ''
        runHook preInstall
        mkdir -p "$out/share/plasma/plasmoids/org.jdmlabs.systempanel"
        cp -r package/. "$out/share/plasma/plasmoids/org.jdmlabs.systempanel/"
        runHook postInstall
    '';

    meta = {
        description = "Native Wayland Plasma widget: Conky-style system information panel (clock, host, versions, temperatures, network)";
        license = lib.licenses.gpl2Plus;
        platforms = lib.platforms.linux;
    };
}

# <> #
