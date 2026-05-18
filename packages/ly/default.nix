{
    lib, stdenv, fetchFromGitea, linux-pam, libxcb, makeBinaryWrapper, zig_0_16,
    nixosTests,
    x11Support ? true
}:

let
    src = fetchFromGitea {
        domain = "codeberg.org";
        owner = "fairyglade";
        repo = "ly";
        rev = "master";
        hash = "sha256-fxKkRf/joY+0aaifNdApa5/FlaDir0eqpiZ8y9j0RJo=";
    };

    deps = zig_0_16.fetchDeps {
        pname = "ly";
        version = "master";
        inherit src;
        hash = "sha256-ZTGQhsDTpWfG4giM0WsfCjlDVr4htC6WWBpSGyKZUr0=";
    };
in stdenv.mkDerivation {
    pname = "ly";
    version = "master";

    inherit src;

    nativeBuildInputs = [
        makeBinaryWrapper
        zig_0_16.hook
    ];
    buildInputs = [
        linux-pam
    ] ++ lib.optional x11Support libxcb;

    zigBuildFlags = lib.optional (!x11Support) "-Denable_x11_support=false";

    postPatch = ''
ln -s ${deps} $ZIG_GLOBAL_CACHE_DIR/p
    '';

    passthru.tests = { inherit (nixosTests) ly; };

    meta = with lib; {
        description = "TUI display manager";
        license = licenses.wtfpl;
        homepage = "https://codeberg.org/fairyglade/ly";
        maintainers = [ maintainers.vidister ];
        platforms = platforms.linux;
        mainProgram = "ly";
    };
}

# <> #
