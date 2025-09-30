{ lib, ... }:
let
    # Determine current hostname from the running system.
    hostFromEtc = if builtins.pathExists /etc/hostname then
        lib.removeSuffix "\n" (builtins.readFile /etc/hostname)
    else
        null;

    hostFromEnv = let h = builtins.getEnv "HOSTNAME"; in
        if h != "" then h
        else null;

    hostname = if hostFromEtc != null then hostFromEtc
        else if hostFromEnv != null then hostFromEnv
        else "unknown";

    machines = {
        atreides = ./machines/atreides.nix;
        icarus = ./machines/icarus.nix;
    };

    machineModule = machines.${hostname} or null;
in {
    # Automatically import the machine-specific configuration based on hostname.
    imports = lib.optional (machineModule != null) machineModule;

    # Provide a default hostname if the machine module doesn't set it.
    networking.hostName = lib.mkDefault hostname;
}
