{ config, lib, ... }: {
    hardware.cpu.amd = {
        ryzen-smu.enable = true;

        # Disabled 2026-06-19: AMD SEV is an EPYC/datacenter feature; the Ryzen 9
        # 3900X (Zen 2 consumer) has no SEV, so this just exposed a device group
        # for nothing. ryzen-smu above is the legit consumer-Ryzen driver.
        # sev = {
        #     enable = true;
        #     mode = "0660";
        #     group = "sev";
        #     user = "root";
        # };

        updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    };

    powerManagement.cpuFreqGovernor = lib.mkDefault "performance";

    # No TLP/power-profiles-daemon — static performance governor (above) manages
    # CPU scaling directly. Desktop is always on AC; nothing to power-profile.
    services.power-profiles-daemon.enable = false;
}

# <> #
