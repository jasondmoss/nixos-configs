self: pkgs: with pkgs; {

    # phpstorm = jetbrains.phpstorm.overrideDerivation (attrs: rec {
    phpstorm = jetbrains.phpstorm.overrideAttrs (oldAttrs: {
        version = "2024.2.3";
        build = "242.23339.16";
        src = fetchurl {
            url = "https://download.jetbrains.com/webide/PhpStorm-2024.2.3.tar.gz";
            sha256 = "sha256-izsboZxNXwzB1ndb/1jTgxNBTq51l2ypmRUQLAI2juo=";
        };

        # version = "2024.3";
        # build = "243.18137.7";
        # src = fetchurl {
        #     url = "https://download.jetbrains.com/webide/PhpStorm-243.18137.7.tar.gz";
        #     sha256 = "sha256-A0cs23Vs3hgusGinJQCbkcFrxiUMNfxACh6Qeh/UDRg=";
        # };

        name = "phpstorm-2024.2.3";
        wmClass = "jetbrains";


        # nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [
        #     pkgs.libGL
        #     pkgs.xorg
        #     pkgs.fontconfig
        # ];

        # buildInputs = oldAttrs.buildInputs ++ (with self; [
        #     libGL
        #     xorg
        #     fontconfig
        # ]);

        # buildInputs = attrs.buildInputs ++ (with self; [
        #     libGL
        #     xorg
        #     fontconfig
        # ]);
        # extraBinPathPackages = with self; [ libGL xorg fontconfig ];

        vmopts = ''
            -server
            -Xms4096m
            -Xmx4096m
        '';
    });

}
