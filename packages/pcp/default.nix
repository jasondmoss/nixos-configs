# packages/pcp/default.nix
#
# Performance Co-Pilot (https://pcp.io) — custom package for atreides.
#
# PCP is not in nixpkgs (the `pcp` attribute there is a removed alias for an
# unrelated, archived parallel-copy tool). This derivation adapts the PCP
# project's own Nix packaging (github.com/performancecopilot/pcp build/nix/)
# into a flake-less callPackage for this repo.
#
# Version bump: run ./update.sh (same workflow as packages/claude-desktop and
# packages/vivaldi-snapshot), which rewrites manifest.json, then rebuild. It
# dry-runs the four vendored patches in patches/ against the candidate tag and
# refuses to bump past a release they no longer apply to. The package version
# itself is read from VERSION.pcp inside the source, so the manifest's version
# is only the git tag to fetch.
#
{ pkgs }:

let
  manifest = pkgs.lib.importJSON ./manifest.json;
in
import ./package.nix {
  inherit pkgs;

  src = pkgs.fetchFromGitHub {
    owner = "performancecopilot";
    repo = "pcp";
    tag = manifest.version;
    inherit (manifest) hash;
  };
}

# <> #
