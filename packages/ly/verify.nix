## Post-refresh build check for nxmanifest (same contract as packages/krema):
## `nix-build verify.nix` must succeed before a manifest bump is accepted.
## update.sh also builds `-A deps` from here to learn the Zig dependency hash.
##
## Evaluates the system configuration instead of a bare <nixpkgs>, for two
## reasons: `ly` is then the exact derivation the rebuild needs (the module
## applies `.override { x11Support = …; }`), and `config` can run the new
## binary's `--validate-config` on the config.ini the NixOS module generates.
## A greeter that builds but cannot read its config is the failure worth
## catching here: Ly reads /etc/ly/config.lua first and only falls back to
## the ini.
let
    nixos = import <nixpkgs/nixos> { };
    inherit (nixos) pkgs;
    inherit (pkgs) lib;

    cfg = nixos.config.services.displayManager.ly;

    package = pkgs.callPackage ./. { };
    ly = package.override { inherit (cfg) x11Support; };

    ## Option names set in this repo (desktop/plasma.nix), without the ones
    ## the nixpkgs module adds: those include fields upstream has already
    ## removed and migrates on its own (`tty`, `shutdown_cmd`, …).
    ownKeys = lib.unique (lib.concatMap (d: lib.attrNames d.value) (lib.filter
        (d: !lib.hasPrefix builtins.storeDir (toString d.file))
        nixos.options.services.displayManager.ly.settings.definitionsWithLocations));
in {
    inherit ly;
    inherit (package) deps;
}
## Only while Ly is the configured greeter; with it commented out in
## desktop/plasma.nix there is no generated config to check.
// lib.optionalAttrs cfg.enable {
    config = pkgs.runCommand "ly-config-check" { } ''
# --validate-config exits 0 on a value it could not convert and only logs
# it, so look at the log as well as the exit status.
if ! ${lib.getExe ly} --validate-config ${nixos.config.environment.etc."ly/config.ini".source} > log 2>&1; then
    cat log
    exit 1
fi
cat log
if grep -qE '^(error|err)' log; then
    exit 1
fi

# The ini parser ignores a key it does not know, so a renamed option would
# pass the validation above and silently fall back to its default — for
# `waylandsessions` that is a greeter with no Plasma session to start. Every
# option set in desktop/plasma.nix must still be a field somewhere in the
# source (normally src/config/Config.zig).
for key in ${lib.escapeShellArgs ownKeys}; do
    if ! grep -rqE --include='*.zig' "^[[:space:]]*$key[[:space:]]*:" ${package.src}; then
        echo "error: '$key' is set in desktop/plasma.nix but is no longer a Ly config field" | tee -a log
        exit 1
    fi
done
cp log $out
    '';
}

# <> #
