self: pkgs: with pkgs; {
    phpstorm = jetbrains.phpstorm.overrideAttrs (oldAttrs: {
        version = "2024.3.5";
        build = "243.26053.13";
        src = fetchurl {
            url = "https://download.jetbrains.com/webide/PhpStorm-2024.3.5.tar.gz";
            sha256 = "sha256-4S77WE65tjJwPRvumYbZWsCazq92ykDpGI2CtxP/D8E=";
        };

        name = "phpstorm-2024.3.5";
        wmClass = "jetbrains";
        vmopts = ''
-server
-Xms4096m
-Xmx4096m
        '';
    });
}
