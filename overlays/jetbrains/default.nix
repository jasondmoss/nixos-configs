self: pkgs: with pkgs; {

    # phpstorm = jetbrains.phpstorm.overrideDerivation (attrs: rec {
    phpstorm = jetbrains.phpstorm.overrideAttrs (oldAttrs: {
        version = "2024.2.4";
        build = "242.23726.19";
        src = fetchurl {
            url = "https://download.jetbrains.com/webide/PhpStorm-242.23726.19.tar.gz";
            sha256 = "sha256-V6Z7+6M1M/cWFM2p1yAp+9RHJ+hWS23YomhAQdZvteA=";
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
