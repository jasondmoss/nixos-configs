{ pkgs, lib, ... }:

pkgs.buildNpmPackage rec {
    pname = "gemini-cli";
    version = "0.49.0";

    src = pkgs.fetchFromGitHub {
        owner = "google-gemini";
        repo = "gemini-cli";
        rev = "v${version}";
        hash = "sha256-C47U5nTWB0Dq2iPRujRHMDjyyrU0d6xZ3Uv7URcIcg8=";
    };

    npmDepsHash = "sha256-e3gPyBJg2TPGywpR7iqpDtcRdq6AWlvY725kIGPJmCo=";
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
