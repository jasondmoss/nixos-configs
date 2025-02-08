self: pkgs: with pkgs; {

    phpstorm = jetbrains.phpstorm.overrideAttrs (oldAttrs: {
        version = "2024.3.2.1";
        build = "243.23654.168";
        src = fetchurl {
            url = "https://download.jetbrains.com/webide/PhpStorm-2024.3.2.1.tar.gz";
            sha256 = "sha256-1vfnxgZZ+0IV2jKsfa6uUgKoa7sulxljCB7kpW5XloU=";
        };

        name = "phpstorm-2024.3.2.1";
        wmClass = "jetbrains";
        vmopts = ''
-server
-Xms4096m
-Xmx4096m
        '';
    });

}
