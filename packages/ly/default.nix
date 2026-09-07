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
        hash = "sha256-BoTKHrZgRmezdRQoJq0ntpfyRvFcPs9MkbbtsRQTTa4=";
    };

    deps = zig_0_16.fetchDeps {
        pname = "ly";
        version = "master";
        inherit src;
        # ly master pulls LuaJIT via zlua as a *lazy* Zig dependency; plain
        # `zig build --fetch` skips lazy deps, so fetchAll runs `--fetch=all`
        # to vendor the complete tree (otherwise the build tries to download
        # LuaJIT at build time, which the sandbox blocks).
        fetchAll = true;
        hash = "sha256-rBr6Zu3mUWSOdscrHh3yW54H6ap0LCV0t0KuUgUbH5s=";
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

    postConfigure = ''
        ln -s ${deps} "$ZIG_GLOBAL_CACHE_DIR/p"
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
