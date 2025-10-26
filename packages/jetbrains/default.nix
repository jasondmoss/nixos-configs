self: pkgs: with pkgs; {
    phpstorm = jetbrains.phpstorm.overrideAttrs (oldAttrs: {
        version = "2025.2.4";
        build = "252.27397.112";
        src = fetchurl {
            url = "https://download.jetbrains.com/webide/PhpStorm-2025.2.4.tar.gz";
            sha256 = "sha256-rSQTAGNEdi+0bcRyRumDBTsI92PfXAoroPcO3nmnbD0=";
        };

        name = "phpstorm-2025.2.4";
        wmClass = "jetbrains";
        vmopts = ''
-server
-Xms6144m
-Xmx6144m
        '';
    });
}
