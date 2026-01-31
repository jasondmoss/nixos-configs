{ pkgs, lib, ... }:

pkgs.buildNpmPackage rec {
    pname = "gemini-cli";
    version = "0.26.0";

    src = pkgs.fetchFromGitHub {
        owner = "google-gemini";
        repo = "gemini-cli";
        rev = "v${version}";
        hash = "sha256-wvCSYr5BUS5gggTFHfG+SRvgAyRE63nYdaDwH98wurI=";
    };

    npmDepsHash = "sha256-nfmIt+wUelhz3KiW4/pp/dGE71f2jsPbxwpBRT8gtYc=";

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
