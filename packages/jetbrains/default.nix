self: pkgs: with pkgs; {
    phpstorm = jetbrains.phpstorm.overrideAttrs (oldAttrs: {
        version = "2025.2.6";
        build = "252.28539.9";
        # version = "2025.3";
        # build = "253.28294.345";
        wmClass = "jetbrains";
        name = "phpstorm-2025.2.6";
        # name = "phpstorm-2025.3";

        src = fetchurl {
            url = "https://download.jetbrains.com/webide/PhpStorm-2025.2.6.tar.gz";
            sha256 = "sha256-TdRFjmlrVxBNSGYqFxzBqtTpPJex6WKF3WkHCln5Pbk=";
            # url = "https://download.jetbrains.com/webide/PhpStorm-2025.3.tar.gz";
            # sha256 = "sha256-66aF1lrAYvFXKIx8cIOWR8SCFj35DoWTDyF6CDaSfdI=";
        };

        vmopts = ''
-server
-Xms6144m
-Xmx6144m
        '';
    });
}
