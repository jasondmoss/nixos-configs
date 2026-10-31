{ lib, stdenvNoCC }:

stdenvNoCC.mkDerivation {
    pname = "deck-plasmoids";
    version = "0.1.0";

    # Local workshop project — the Deck widget (Git | Gulp and CircleCI |
    # Pantheon as two tabbed pairs) and the four cards as standalone widgets,
    # all fed by deck-agent. QML only; the card components and everything else
    # shared live in plasmoids/common and are symlinked into each package,
    # dereferenced here.
    src = ../../workshop/deck/plasmoids;

    dontConfigure = true;
    dontBuild = true;

    installPhase = ''
        runHook preInstall
        for dir in org.jdmlabs.deck org.jdmlabs.deck.*; do
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
