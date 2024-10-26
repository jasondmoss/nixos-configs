self: pkgs: with pkgs; {

    phpstorm = jetbrains.phpstorm.overrideAttrs (oldAttrs: {
        version = "2024.3";
        build = "243.21155.35";
        src = fetchurl {
            url = "https://download.jetbrains.com/webide/PhpStorm-243.21155.35.tar.gz";
            sha256 = "sha256-kFF6RU6V4MHSgv9o5igOpSeMl4MM7/ucpG2vCoyezBE=";
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
