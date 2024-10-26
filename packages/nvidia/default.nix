{ config, lib, ... }: {

    imports = [
        ./vaapi.nix
    ];

    hardware.nvidia = {
        # Beta branch.
        #package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
        #    version = "565.57.01";
        #    sha256_aarch64 = "";
        #    openSha256 = "";
        #    settingsSha256 = "";
        #    persistencedSha256 = "";
        #};

        # New feature branch.
        package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
            version = "560.35.03";
            sha256_64bit = "sha256-8pMskvrdQ8WyNBvkU/xPc/CtcYXCa7ekP73oGuKfH+M=";
            openSha256 = "sha256-/32Zf0dKrofTmPZ3Ratw4vDM7B+OgpC4p7s+RHUjCrg=";
            settingsSha256 = "sha256-kQsvDgnxis9ANFmwIwB7HX5MkIAcpEEAHc8IBOLdXvk=";
            persistencedSha256 = "sha256-E2J2wYYyRu7Kc3MMZz/8ZIemcZg68rkzvqEwFAL3fFs=";
        };

        vaapi = {
            enable = true;
            firefox.enable = true;
        };
    };

    boot = {
        extraModprobeConfig = "options nvidia " + lib.concatStringsSep " " [
            "NVreg_UsePageAttributeTable=1"
            "NVreg_EnablePCIeGen3=1"
            "NVreg_PreserveVideoMemoryAllocations=1"
            "NVreg_RegistryDwords=RMUseSwI2c=0x01;RMI2cSpeed=100"
        ];
    };

}
