# packages/pcp/default.nix
#
# Performance Co-Pilot (https://pcp.io) — custom package for atreides.
#
# PCP is not in nixpkgs (the `pcp` attribute there is a removed alias for an
# unrelated, archived parallel-copy tool). This derivation adapts the PCP
# project's own Nix packaging (github.com/performancecopilot/pcp build/nix/)
# into a flake-less callPackage for this repo.
#
# Version bump: change `tag` + `hash` below. The package version itself is read
# from VERSION.pcp inside the source, so nothing else needs updating.
#
{ pkgs }:

import ./package.nix {
  inherit pkgs;

  src = pkgs.fetchFromGitHub {
    owner = "performancecopilot";
    repo = "pcp";
    tag = "7.1.5";
    hash = "sha256-M+19Xj6G84JTwMpopL+Y1Dztvqf9s+ZG3ZZbvbRwMe0=";
  };
}

# <> #
