self: pkgs: with pkgs; {
    phpstorm = jetbrains.phpstorm.overrideAttrs (oldAttrs: {
        version = "2025.1";
        build = "251.23774.209";
        src = fetchurl {
            url = "https://download.jetbrains.com/webide/PhpStorm-251.23774.209.tar.gz";
            sha256 = "sha256-O6ryW0OMdYS50kVIlbZaJVkuDwklWdiWFp/G0x/YSSU=";
        };

        name = "phpstorm-2025.1";
        wmClass = "jetbrains";
        vmopts = ''
-server
-Xms4096m
-Xmx4096m
        '';
    });
}
