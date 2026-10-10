{ lib, stdenvNoCC }:

stdenvNoCC.mkDerivation {
    pname = "deck-plasmoids";
    version = "0.1.0";

    # Local workshop project — four Plasma widgets (Git, Gulp, CircleCI,
    # Pantheon) fed by deck-agent. QML only; the files shared between them live
    # in plasmoids/common and are symlinked into each package, dereferenced
    # here.
    src = ../../workshop/deck/plasmoids;

    dontConfigure = true;
    dontBuild = true;

    installPhase = ''
        runHook preInstall
        for dir in org.jdmlabs.deck.*; do
            mkdir -p "$out/share/plasma/plasmoids/$dir"
            cp -rL "$dir"/. "$out/share/plasma/plasmoids/$dir/"
        done
        runHook postInstall
    '';

    meta = {
        description = "Deck: desktop cards for the project open in PhpStorm — git status, gulp watcher, CircleCI pipelines, Pantheon environments";
        license = lib.licenses.gpl2Plus;
        platforms = lib.platforms.linux;
    };
}

# <> #
