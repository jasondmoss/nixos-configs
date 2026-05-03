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

    services = {
        power-profiles-daemon.enable = false;

        tlp = {
            enable = true;
            settings = {
                CPU_SCALING_GOVERNOR_ON_AC = "powersave";
                CPU_ENERGY_PERF_POLICY_ON_AC = "performance";

                CPU_MIN_PERF_ON_AC = 0;
                CPU_MAX_PERF_ON_AC = 100;
            };
        };
    };
}

# <> #
