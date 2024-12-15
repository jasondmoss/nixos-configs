self: pkgs: with pkgs; {

    phpstorm = jetbrains.phpstorm.overrideAttrs (oldAttrs: {
        version = "2024.3.1";
        build = "243.22562.164";
        src = fetchurl {
            url = "https://download.jetbrains.com/webide/PhpStorm-2024.3.1.tar.gz";
            sha256 = "sha256-rL0q3aeYF8vlCOibikMb0Ow5DEqxmnjgTh7xAYQ93fE=";
        };

        name = "phpstorm-2024.3.1";
        wmClass = "jetbrains";

        vmopts = ''
-server
-Xms4096m
-Xmx4096m
        '';
    });

}
