self: pkgs: with pkgs; {
    phpstorm = jetbrains.phpstorm.overrideAttrs (oldAttrs: {
        version = "2025.3.1.1";
        build = "253.29346.257";
        wmClass = "jetbrains";
        name = "phpstorm-2025.3.1.1";

        src = fetchurl {
            url = "https://download.jetbrains.com/webide/PhpStorm-2025.3.1.1.tar.gz";
            sha256 = "sha256-u5b/elgB4/kMrgkgyqhz4L2BZqsNqt6Fwb+JIC1eSEk=";
        };

        vmopts = ''
-server
-Xms6144m
-Xmx6144m
        '';
    });
}
