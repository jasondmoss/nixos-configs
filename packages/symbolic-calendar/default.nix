{ lib, stdenvNoCC }:

stdenvNoCC.mkDerivation {
    pname = "symbolic-calendar";
    version = "0.1.0";

    # Local workshop project — Plasma's Calendar widget with a panel icon drawn
    # in the panel's text colour (follows panel-contrast's light/dark presets).
    # QML only, no compilation.
    src = ../../workshop/symbolic-calendar;

    dontConfigure = true;
    dontBuild = true;

    installPhase = ''
        runHook preInstall
        mkdir -p "$out/share/plasma/plasmoids/org.jdmlabs.symboliccalendar"
        cp -r package/. "$out/share/plasma/plasmoids/org.jdmlabs.symboliccalendar/"
        runHook postInstall
    '';

    meta = {
        description = "Plasma Calendar widget with a symbolic panel icon in the panel's text colour";
        license = lib.licenses.gpl2Plus;
        platforms = lib.platforms.linux;
    };
}

# <> #
