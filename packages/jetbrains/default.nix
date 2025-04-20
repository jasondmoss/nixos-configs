self: pkgs: with pkgs; {
    phpstorm = jetbrains.phpstorm.overrideAttrs (oldAttrs: {
        version = "2025.1";
        build = "251.23774.436";
        src = fetchurl {
            url = "https://download.jetbrains.com/webide/PhpStorm-2025.1.tar.gz";
            sha256 = "sha256-Lq15S1vG0xvkrYhniBEOnY5ccI4uVCsg0XokB7nliZg=";
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
