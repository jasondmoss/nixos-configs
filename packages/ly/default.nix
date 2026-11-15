{
    lib, stdenv, fetchFromGitea, linux-pam, libxcb, makeBinaryWrapper, pkgs,
    nixosTests,
    x11Support ? true
}:

let
    ## Tracks upstream `master`, pinned to a commit. Everything in manifest.json
    ## comes from ./update.sh (run by nxmanifest before every nxup): the
    ## commit, its date, its fetchFromGitea hash, the `<date>.<rev>` version,
    ## the hash of the vendored Zig dependencies and the Zig series the commit
    ## asks for (`minimum_zig_version` in build.zig.zon, "0.17.0" -> "0_17").
    ##
    ## Until 2026-11-15 this was `rev = "master"` with a fixed hash, which only
    ## held while the source stayed in the store: a refetch after a GC got the
    ## moved branch head and failed the hash check.
    ##
    ## update.sh refuses a commit whose Zig series nixpkgs does not have or
    ## that no longer falls back to /etc/ly/config.ini (Ly reads config.lua
    ## first; the NixOS module only writes the ini). verify.nix then builds it
    ## and validates the system's generated config.ini with the new binary.
    manifest = lib.importJSON ./manifest.json;

    zig = pkgs."zig_${manifest.zig}";

    src = fetchFromGitea {
        domain = "codeberg.org";
        owner = "fairyglade";
        repo = "ly";
        inherit (manifest) rev hash;
    };

    deps = zig.fetchDeps {
        pname = "ly";
        # The version is part of the derivation name on purpose: a
        # fixed-output path depends only on name + hash, so with a constant
        # name a bump whose dependencies changed would silently reuse the old
        # tree instead of reporting the new hash.
        inherit (manifest) version;
        inherit src;
        # ly master pulls LuaJIT via zlua as a *lazy* Zig dependency; plain
        # `zig build --fetch` skips lazy deps, so fetchAll runs `--fetch=all`
        # to vendor the complete tree (otherwise the build tries to download
        # LuaJIT at build time, which the sandbox blocks).
        fetchAll = true;
        hash = manifest.depsHash;
    };
in stdenv.mkDerivation {
    pname = "ly";
    inherit (manifest) version;

    inherit src;

    nativeBuildInputs = [
        makeBinaryWrapper
        zig.hook
    ];
    buildInputs = [
        linux-pam
    ] ++ lib.optional x11Support libxcb;

    zigBuildFlags = lib.optional (!x11Support) "-Denable_x11_support=false";

    postConfigure = ''
        ln -s ${deps} "$ZIG_GLOBAL_CACHE_DIR/p"
    '';

    passthru = {
        # update.sh builds `verify.nix -A deps` to learn the dependency hash.
        inherit deps;
        tests = { inherit (nixosTests) ly; };
    };

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
