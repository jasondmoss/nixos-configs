{ pkgs, lib, ... }:

pkgs.buildNpmPackage rec {
    pname = "gemini-cli";
    version = "0.53.1";

    src = pkgs.fetchFromGitHub {
        owner = "google-gemini";
        repo = "gemini-cli";
        rev = "v${version}";
        hash = "sha256-c/Mql3r+2c5u9hUO1x7uLRtD0nRs4kOfkabqcPfh/MA=";
    };

    npmDepsHash = "sha256-uRUUHvFiET+JIdriY4uiO1i6vigrwS+EowkhQ0vRPO4=";
    npmDepsFetcherVersion = 2;

    nativeBuildInputs = with pkgs; [
        pkg-config
        python3
        git
    ];

    buildInputs = with pkgs; [
        libsecret
        glib
    ];

    # Force the build script to use our Nix-provided python
    PYTHON = "${pkgs.python3}/bin/python3";

    # Upstream package.json pins tar 7.5.8 and clipboardy 5.2.0, but the
    # lockfile resolves tar 7.5.11 / clipboardy 5.2.1 (the pinned versions
    # were pulled from the npm registry) — align the pins so npm doesn't
    # try to re-resolve offline
    postPatch = ''
substituteInPlace packages/cli/package.json packages/a2a-server/package.json \
    --replace-fail '"tar": "7.5.8"' '"tar": "7.5.11"'
substituteInPlace packages/cli/package.json \
    --replace-fail '"clipboardy": "5.2.0"' '"clipboardy": "5.2.1"'
    '';

    preFixup = ''
        find $out/lib/node_modules/@google/gemini-cli/node_modules -type l -delete
    '';

    meta = with lib; {
        description = "Official Google Gemini CLI agent for terminal-based interaction and local file access";
        homepage = "https://github.com/google-gemini/gemini-cli";
        license = licenses.asl20;
        maintainers = [ ];
        platforms = platforms.linux;
    };
}

# <> #
