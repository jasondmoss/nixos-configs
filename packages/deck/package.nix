{
    lib,
    stdenvNoCC,
    python3,
    makeWrapper,
    git,
    openssh,
    terminus,
}:

stdenvNoCC.mkDerivation {
    pname = "deck-agent";
    version = "0.1.0";

    # Local workshop project — the data hub behind the Deck Plasma cards
    # (active PhpStorm project, git status, gulp watcher, CircleCI, Pantheon).
    # One Python file, standard library only.
    src = ../../workshop/deck/agent;

    nativeBuildInputs = [ makeWrapper ];

    dontConfigure = true;
    dontBuild = true;

    installPhase = ''
        runHook preInstall
        install -Dm755 deck-agent.py "$out/libexec/deck-agent.py"
        # NixOS gives user services a minimal PATH (coreutils, grep, sed…), so
        # the system profile is appended: node (the same one PhpStorm runs),
        # phpstorm and op come from there. git/ssh/terminus are pinned.
        makeWrapper ${python3.interpreter} "$out/bin/deck-agent" \
            --add-flags "$out/libexec/deck-agent.py" \
            --prefix PATH : ${lib.makeBinPath [ git openssh terminus ]} \
            --suffix PATH : /run/wrappers/bin:/run/current-system/sw/bin
        runHook postInstall
    '';

    meta = {
        description = "Local data hub for the Deck Plasma cards: PhpStorm project, git, gulp watcher, CircleCI, Pantheon";
        license = lib.licenses.gpl2Plus;
        platforms = lib.platforms.linux;
        mainProgram = "deck-agent";
    };
}

# <> #
