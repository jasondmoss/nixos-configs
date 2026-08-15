{
    lib, stdenv, fetchurl, autoPatchelfHook, makeWrapper,
    gnutar, zstd, coreutils,
    libsecret, glib,
}:

# Official Proton Drive CLI — a single self-contained Bun-compiled executable
# (TypeScript, built on the Proton Drive SDK). Proton publishes per-arch bare
# binaries at proton.me/download/drive/cli/<version>/<platform>/; we take the
# glibc linux-x64 build. SHA-512 of the fetched file matches Proton's published
# checksum for 0.8.0 (cf61c2…), i.e. this is the authentic release binary.
#
# Ships two commands:
#   proton-drive   — the upstream CLI (auth login / filesystem list|upload|
#                    download / trash / sharing …).
#   proton-backup  — local compress-then-upload helper (see proton-backup.sh).
#                    Needed because Drive is E2E-encrypted: uploads are never
#                    compressed server-side, so archiving locally is the only
#                    way to save Drive space.
stdenv.mkDerivation rec {
    pname = "proton-drive-cli";
    version = "0.8.0";

    src = fetchurl {
        url = "https://proton.me/download/drive/cli/${version}/linux-x64/proton-drive";
        hash = "sha256-lEPXcXGciSeQ2xfm8C7Nma18U1kzKfOmfHdnfc5XdzU=";
    };

    # `src` is a single bare executable, not an archive — nothing to unpack.
    dontUnpack = true;

    # CRITICAL: a Bun `--compile` binary stores the bundled app as a blob
    # appended after the ELF, located via a trailer at end-of-file. The default
    # fixup `strip` rewrites the ELF and drops that blob, so the binary silently
    # degrades to the bare Bun runtime (`proton-drive auth` → "reserved for Bun").
    # Never strip it. autoPatchelf's interpreter/rpath rewrite is fine.
    dontStrip = true;

    nativeBuildInputs = [ autoPatchelfHook makeWrapper ];

    # Dynamically-linked glibc executable; DT_NEEDED is only libc/pthread/dl/m,
    # all satisfied by the default glibc + the compiler's runtime libs.
    buildInputs = [ (lib.getLib stdenv.cc.cc) ];

    # Bun.secrets stores the login session in the system keyring, which the app
    # dlopen()s at runtime (libsecret + glib). autoPatchelf can't see dlopen, so
    # expose these through the wrapper — otherwise every command dies with
    # "libsecret not available".
    runtimeLibs = lib.makeLibraryPath [ libsecret glib ];

    installPhase = ''
runHook preInstall

# Upstream CLI binary (autoPatchelfHook rewrites the ELF interpreter to Nix's);
# wrap it so the keyring libs are dlopen-able.
install -Dm755 $src $out/bin/.proton-drive-unwrapped
makeWrapper $out/bin/.proton-drive-unwrapped $out/bin/proton-drive \
    --prefix LD_LIBRARY_PATH : "${runtimeLibs}"

# Compress-and-upload helper; give it tar/zstd/coreutils and proton-drive.
install -Dm755 ${./proton-backup.sh} $out/bin/proton-backup
wrapProgram $out/bin/proton-backup \
    --prefix PATH : "${lib.makeBinPath [ gnutar zstd coreutils ]}:$out/bin"

runHook postInstall
    '';

    meta = with lib; {
        description = "Official Proton Drive CLI (proton-drive) + proton-backup compress-and-upload helper";
        homepage = "https://proton.me/support/drive-cli";
        license = licenses.gpl3Only;
        maintainers = [ ];
        platforms = [ "x86_64-linux" ];
        mainProgram = "proton-drive";
    };
}

# <> #
