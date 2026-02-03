self: pkgs: with pkgs; {
    phpstorm = jetbrains.phpstorm.overrideAttrs (oldAttrs: {
        version = "2025.3.2";
        build = "253.30387.85";
        wmClass = "jetbrains";
        name = "phpstorm-2025.3.2";

        src = fetchurl {
            url = "https://download.jetbrains.com/webide/PhpStorm-2025.3.2.tar.gz";
            sha256 = "sha256-W9O2DYzJAEtgFb79xYGMUNvi8yMmH+oRhNeoKyHtYO8=";
        };

        vmopts = ''
-server
-Xms6144m
-Xmx6144m
        '';
    });
}
