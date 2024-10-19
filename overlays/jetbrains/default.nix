self: pkgs: with pkgs; {

    # phpstorm = jetbrains.phpstorm.overrideDerivation (attrs: rec {
    phpstorm = jetbrains.phpstorm.overrideAttrs (oldAttrs: {
        version = "2024.2.4";
        build = "242.23726.55";
        src = fetchurl {
            url = "https://download.jetbrains.com/webide/PhpStorm-242.23726.55.tar.gz";
            sha256 = "sha256-I/u0eppvbBbPywO7xi3fPtdm7YlyYT7h6xVbY4br+YU=";
        };

        name = "phpstorm-2024.2.4";
        wmClass = "jetbrains";

        vmopts = ''
            -server
            -Xms4096m
            -Xmx4096m
        '';
    });

}
