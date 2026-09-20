{
    lib, stdenv, stdenvNoCC, fetchFromGitHub, bun, nodejs, python3, jq, cacert
}:

let
    ## Upstream publishes no store listing, release or tag — only source on
    ## `main` — so this pins a commit. Everything in manifest.json comes from
    ## ./update.sh (run by nxmanifest before every nxup): the commit, its
    ## fetchFromGitHub hash, the bun node_modules hash, and the extension
    ## version. That version is `<package.json version>.<commit count>`: both
    ## browsers only replace an installed extension when the manifest version
    ## grows, and upstream commits without bumping package.json.
    manifest = lib.importJSON ./manifest.json;

    ## Firefox add-on ID from upstream's wxt.config.ts. Fixed there; the
    ## Nightly wrapper names the distribution XPI after it.
    geckoId = "unclutter@kitze.io";

    ## Seed for the CRX signing key (see crx3.py for why it is derived rather
    ## than stored). Changing it changes the Chrome extension ID, which makes
    ## Chrome treat the next build as a different extension: saved rules and
    ## the API key stay behind with the old ID.
    crxSeed = "unclutter@kitze.io/atreides";

    src = fetchFromGitHub {
        owner = "kitze";
        repo = "unclutter";
        inherit (manifest) rev hash;
    };

    python = python3.withPackages (p: [ p.cryptography ]);

    ## Vendored node_modules as a fixed-output derivation: `bun install
    ## --frozen-lockfile` against upstream's bun.lock is byte-reproducible
    ## with the copyfile backend (nixpkgs has no bun fetcher yet). The output
    ## *is* the node_modules tree, so the hash equals `nix hash path
    ## node_modules` of a local install — update.sh recomputes it from the
    ## mismatch error after a bump.
    deps = stdenvNoCC.mkDerivation {
        pname = "unclutter-node-modules";
        inherit (manifest) version;
        inherit src;

        nativeBuildInputs = [ bun ];

        dontConfigure = true;
        dontFixup = true;

        buildPhase = ''
runHook preBuild
export HOME="$TMPDIR/home"
export BUN_INSTALL_CACHE_DIR="$TMPDIR/bun-cache"
export SSL_CERT_FILE="${cacert}/etc/ssl/certs/ca-bundle.crt"
bun install --frozen-lockfile --ignore-scripts --no-progress --no-summary --backend=copyfile
runHook postBuild
        '';

        installPhase = ''
runHook preInstall
cp -r node_modules "$out"
runHook postInstall
        '';

        impureEnvVars = lib.fetchers.proxyImpureEnvVars;
        outputHashAlgo = "sha256";
        outputHashMode = "recursive";
        outputHash = manifest.depsHash;
    };
in
stdenv.mkDerivation {
    pname = "unclutter";
    inherit (manifest) version;
    inherit src;

    nativeBuildInputs = [ bun nodejs python jq ];

    # WXT/Vite write caches under node_modules, so the vendored tree is
    # copied rather than symlinked. `bun run build` execs node_modules/.bin/wxt,
    # whose `#!/usr/bin/env node` has no /usr/bin/env in the sandbox.
    configurePhase = ''
runHook preConfigure
export HOME="$TMPDIR/home"
cp -r ${deps} node_modules
chmod -R u+w node_modules
patchShebangs node_modules/wxt/bin
runHook postConfigure
    '';

    buildPhase = ''
runHook preBuild

bun run build            # .output/chrome-mv3 (MV3 build, also for Edge/Vivaldi)
bun run build:firefox    # .output/firefox-mv2

# Monotonic version (see manifest comment). Chrome shows version_name in
# chrome://extensions; Firefox has no such key, so it only gets the version.
jq --arg v "${manifest.version}" \
   --arg vn "${manifest.upstreamVersion} (git ${lib.substring 0 7 manifest.rev}, ${manifest.date})" \
   '.version = $v | .version_name = $vn' \
   .output/chrome-mv3/manifest.json > manifest.tmp
mv manifest.tmp .output/chrome-mv3/manifest.json
jq --arg v "${manifest.version}" '.version = $v' \
   .output/firefox-mv2/manifest.json > manifest.tmp
mv manifest.tmp .output/firefox-mv2/manifest.json

# CRX3 for Chrome (also stamps the matching `key` into chrome-mv3/manifest.json)
# and a plain XPI for Firefox — both from reproducible zips.
python3 ${./crx3.py} pack .output/chrome-mv3 unclutter.crx \
    --seed ${lib.escapeShellArg crxSeed} --id-file chrome-id
python3 ${./crx3.py} zip .output/firefox-mv2 unclutter.xpi

runHook postBuild
    '';

    installPhase = ''
runHook preInstall

install -d "$out/share/unclutter"
cp -r .output/chrome-mv3 "$out/share/unclutter/chrome-mv3"
install -m644 unclutter.crx unclutter.xpi chrome-id "$out/share/unclutter/"

# Chrome "external extensions" descriptor: a directory Chrome reads
# <id>.json files from (its <install dir>/extensions/, see nixpkgs.nix), each
# pointing at a local CRX. external_version must match the CRX manifest;
# Chrome reinstalls when it grows.
id="$(cat chrome-id)"
install -d "$out/share/unclutter/chrome-external"
cat > "$out/share/unclutter/chrome-external/$id.json" <<EOF
{
  "external_crx": "$out/share/unclutter/unclutter.crx",
  "external_version": "${manifest.version}"
}
EOF

runHook postInstall
    '';

    passthru = {
        inherit deps geckoId;
        updateScript = ./update.sh;
    };

    meta = with lib; {
        description = "Browser extension that hides page clutter with reusable, AI-classified template rules";
        homepage = "https://github.com/kitze/unclutter";
        license = licenses.mit;
        platforms = platforms.linux;
    };
}

# <> #
