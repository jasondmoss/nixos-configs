# packages/grafana-pcp/default.nix
#
# grafana-pcp — the Performance Co-Pilot app plugin for Grafana
# (https://github.com/performancecopilot/grafana-pcp). Not in nixpkgs.
#
# Consumed via `services.grafana.declarativePlugins` (see pcp-grafana.nix), which
# link-farms each plugin package into Grafana's plugin dir by its `pname`. So:
#   - `pname` MUST equal the plugin id ("performancecopilot-pcp-app")
#   - `$out` MUST contain the plugin's plugin.json at its top level
#
# The upstream release zip is Grafana-signed; we copy it verbatim (no rewrites),
# so the signature stays valid and Grafana loads it without
# `allow_loading_unsigned_plugins`.
#
# Version bump: run ./update.sh (same workflow as packages/claude-desktop and
# packages/vivaldi-snapshot), which rewrites manifest.json, then rebuild. The
# recorded hash is a fetchzip hash, i.e. of the *unpacked* tree.
#
{ pkgs }:

let
  manifest = pkgs.lib.importJSON ./manifest.json;
in
pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "performancecopilot-pcp-app";

  inherit (manifest) version;

  src = pkgs.fetchzip {
    url = "https://github.com/performancecopilot/grafana-pcp/releases/download/v${finalAttrs.version}/${manifest.filename}";
    inherit (manifest) hash;
  };

  dontConfigure = true;
  dontBuild = true;

  # Copy the signed release verbatim and skip fixup entirely — patchShebangs /
  # patchELF / strip would mutate files covered by MANIFEST.txt and break the
  # Grafana signature check.
  dontFixup = true;

  installPhase = ''
    runHook preInstall
    mkdir -p "$out"
    cp -r . "$out/"
    runHook postInstall
  '';

  meta = with pkgs.lib; {
    description = "Performance Co-Pilot app plugin for Grafana";
    homepage = "https://github.com/performancecopilot/grafana-pcp";
    license = licenses.asl20;
    platforms = platforms.all;
  };
})

# <> #
