self: pkgs: with pkgs; {

    phpstorm = jetbrains.phpstorm.overrideAttrs (oldAttrs: {
        version = "2024.3.1";
        build = "243.22562.233";
        src = fetchurl {
            url = "https://download.jetbrains.com/webide/PhpStorm-2024.3.1.1.tar.gz";
            sha256 = "sha256-i7kJtjIvKW1ORCZSI8/8omSeQ0TRIztnD3UcWy165pg=";
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
