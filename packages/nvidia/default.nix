{ config, lib, ... }: {

    imports = [
        ./vaapi.nix
    ];

    hardware.nvidia = {
        # Beta branch.
        package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
            version = "560.31.02";
            sha256_64bit = "sha256-0cwgejoFsefl2M6jdWZC+CKc58CqOXDjSi4saVPNKY0=";
            sha256_aarch64 = "sha256-BDtdpH5f9/PutG3Pv9G4ekqHafPm3xgDYdTcQumyMtg=";
            openSha256 = "sha256-X5UzbIkILvo0QZlsTl9PisosgPj/XRmuuMH+cDohdZQ=";
            settingsSha256 = "sha256-X5UzbIkILvo0QZlsTl9PisosgPj/XRmuuMH+cDohdZQ=";
            persistencedSha256 = "sha256-BDtdpH5f9/PutG3Pv9G4ekqHafPm3xgDYdTcQumyMtg=";
        };

        # New feature branch.
        # package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
        #     version = "560.35.03";
        #     sha256_64bit = "sha256-8pMskvrdQ8WyNBvkU/xPc/CtcYXCa7ekP73oGuKfH+M=";
        #     sha256_aarch64 = "sha256-s8ZAVKvRNXpjxRYqM3E5oss5FdqW+tv1qQC2pDjfG+s=";
        #     openSha256 = "sha256-/32Zf0dKrofTmPZ3Ratw4vDM7B+OgpC4p7s+RHUjCrg=";
        #     settingsSha256 = "sha256-kQsvDgnxis9ANFmwIwB7HX5MkIAcpEEAHc8IBOLdXvk=";
        #     persistencedSha256 = "sha256-E2J2wYYyRu7Kc3MMZz/8ZIemcZg68rkzvqEwFAL3fFs=";
        # };

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
