{
    lib, stdenv, fetchurl, autoPatchelfHook, makeWrapper,
    libsecret, glib,
}:

let
    ## Upstream GitHub releases. Version + checksum come from manifest.json —
    ## refresh it with ./update.sh (same workflow as packages/claude-desktop
    ## and packages/vivaldi-snapshot), then rebuild.
    baseUrl = "https://github.com/google-antigravity/antigravity-cli/releases/download";
    manifest = lib.importJSON ./manifest.json;
in stdenv.mkDerivation rec {
    ## `rec` is still needed: installPhase interpolates runtimeLibs below.
    pname = "antigravity-cli";

    inherit (manifest) version;

    src = fetchurl {
        url = "${baseUrl}/${manifest.version}/${manifest.filename}";
        inherit (manifest) sha256;
    };

    # Tarball holds a single bare `antigravity` binary with no top-level dir.
    sourceRoot = ".";

    nativeBuildInputs = [ autoPatchelfHook makeWrapper ];

    # The binary is a dynamically-linked (cgo) glibc executable; libgcc/libstdc++
    # from the compiler's lib output plus glibc cover its DT_NEEDED entries.
    buildInputs = [
        (lib.getLib stdenv.cc.cc)
    ];

    # Google Sign-In stashes OAuth tokens in the system keyring, which the
    # binary dlopen()s at runtime — autoPatchelf can't see dlopen, so expose
    # libsecret/glib through the wrapper.
    runtimeLibs = lib.makeLibraryPath [ libsecret glib ];

    installPhase = ''
runHook preInstall

install -Dm755 antigravity $out/bin/.agy-unwrapped
makeWrapper $out/bin/.agy-unwrapped $out/bin/agy \
    --prefix LD_LIBRARY_PATH : "${runtimeLibs}"
ln -s agy $out/bin/antigravity

runHook postInstall
    '';

    meta = with lib; {
        description = "Google Antigravity CLI (agy) — agentic terminal successor to Gemini CLI";
        homepage = "https://github.com/google-antigravity/antigravity-cli";
        license = licenses.unfree;
        maintainers = [ ];
        platforms = [ "x86_64-linux" ];
        mainProgram = "agy";
    };
}

# <> #
