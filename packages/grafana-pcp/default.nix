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
# Version bump: change `version` + `hash`.
#
{ pkgs }:

pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "performancecopilot-pcp-app";
  version = "6.0.1";

  src = pkgs.fetchzip {
    url = "https://github.com/performancecopilot/grafana-pcp/releases/download/v${finalAttrs.version}/performancecopilot-pcp-app-${finalAttrs.version}.zip";
    hash = "sha256-FmH/GYWMOtf8eUtf2V2dgcZwaHyxvp33rVax3xk/yuc=";
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
