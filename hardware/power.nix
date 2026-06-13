    { config, lib, ... }: {
    hardware.cpu.amd = {
        ryzen-smu.enable = true;

        sev = {
            enable = true;
            mode = "0660";
            group = "sev";
            user = "root";
        };

        updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    };

    powerManagement.cpuFreqGovernor = lib.mkDefault "performance";

    # No TLP/power-profiles-daemon — static performance governor (above) manages
    # CPU scaling directly. Desktop is always on AC; nothing to power-profile.
    services.power-profiles-daemon.enable = false;
}

# <> #
