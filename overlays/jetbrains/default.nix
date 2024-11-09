self: pkgs: with pkgs; {

    phpstorm = jetbrains.phpstorm.overrideAttrs (oldAttrs: {
        version = "2024.3";
        build = "243.21565.133";
        src = fetchurl {
            url = "https://download.jetbrains.com/webide/PhpStorm-243.21565.133.tar.gz";
            sha256 = "sha256-EzRupewKp/6kARttXdfUjHLpTJ6/c2J2BBLGmURL3jw=";
        };

        name = "phpstorm-2024.3";
        wmClass = "jetbrains";

        vmopts = ''
-server
-Xms4096m
-Xmx4096m
        '';
    });

}
