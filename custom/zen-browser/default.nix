{ lib, stdenv, pnpm, nodejs, fetchurl, fetchFromGitHub }:
let
    # firefox-version = "129.0.2";
    firefox-version = "131.0b1";
    firefox-src = fetchurl {
        url = "mirror://mozilla/firefox/releases/${firefox-version}/source/firefox-${firefox-version}.source.tar.xz";
        hash = "sha512-4tFw7QW+55JIA2jTrdQRVjsMv4petOAAHbG6/v7ZKefkJK+MLWJ5Mo35QUAmEfYpT9t2bttk7J/nD5DQV6v6Ww==";
    };
in
stdenv.mkDerivation rec {
    pname = "zen-browser";
    version = "1.0.0-a.34";

    nativeBuildInputs = [
        pnpm.configHook
        nodejs
    ];

    src = fetchFromGitHub {
        owner = "zen-browser";
        repo = "desktop";
        rev = version;
        hash = "sha256-W/BCfZ2KvYdX6+l8W80fXVo+RMjVy02szIqMsL7mX+A=";
        fetchSubmodules = true;
    };

    pnpmDeps = pnpm.fetchDeps {
        pname = "${pname}-pnpm-deps";
        inherit src version;
        hash = "sha256-pZWpreT55dJFUaNBE7VL/wehk3xxL5+vI2P0HDyMqck=";
    };


    # Provides Firefox source required to build
    preBuild = ''
        mkdir -p .surfer/engine
        cp -r ${firefox-src} .surfer/engine/firefox-${firefox-version}.source.tar.xz
        pnpm run bootstrap && pnpm run import
    '';

    buildPhase = ''
        #TODO: Lanaguage Pack support
        # Build language Packs

        # Build Zen Browser TODO: Issue #2
        exit 1
        pnpm build
    '';

    installPhase = ''
        #TODO: Find out where zen builds to.
    '';

    meta = with lib; {
        description = "A browser for the future";
        homepage = "";
        license = licenses.mpl20;
        platforms = platforms.all;
    };
}
