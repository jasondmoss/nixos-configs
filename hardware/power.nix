{ config, lib, ... }: {
    hardware.cpu.amd = {
        ryzen-smu.enable = true;

        updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    };

    powerManagement.cpuFreqGovernor = lib.mkDefault "performance";

    services.power-profiles-daemon.enable = false;
}

# <> #
