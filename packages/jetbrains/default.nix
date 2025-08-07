self: pkgs: with pkgs; {
    phpstorm = jetbrains.phpstorm.overrideAttrs (oldAttrs: {
        version = "2025.2";
        build = "252.23892.419";
        src = fetchurl {
            url = "https://download.jetbrains.com/webide/PhpStorm-2025.2.tar.gz";
            sha256 = "sha256-0NPmGq7XxHZbSUeoQQqIXPfhEjxIg0BYXtchUfjAU1A=";
        };

        name = "phpstorm-2025.2";
        wmClass = "jetbrains";
        vmopts = ''
-server
-Xms4096m
-Xmx4096m
        '';
    });
}
