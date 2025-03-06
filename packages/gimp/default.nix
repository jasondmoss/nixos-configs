{ pkgs, ... }: {
    nixpkgs.overlays = [
        (final: prev: {
            babl = prev.babl.overrideAttrs (oldAttrs: {
                version = "0.1.110";
                src = final.fetchurl {
                    url = "https://download.gimp.org/pub/babl/0.1/babl-0.1.110.tar.xz";
                    hash = "sha256-v0e+dUDWJ1OJ9mQx7wMGTfU3YxXiQ9C6tEjGqnE/V0M=";
                };
            });

            gegl = prev.gegl.overrideAttrs (oldAttrs: {
                version = "0.4.52";
                src = final.fetchurl {
                    url = "https://download.gimp.org/pub/gegl/0.4/gegl-0.4.52.tar.xz";
                    hash = "sha256-yiEqD8PgRIxQWMUcpqDTD9+wKXHyHyiCDaK0kBOWAAo=";
                };
            });
        })
    ];

    environment.systemPackages = (with pkgs; [
        babl
        gegl

        # Stable version
        gimp

        # Development version (currently RC2)
        #(pkgs.callPackage ./gimp-devel {})
    ]) ++ (with pkgs.gimpPlugins; [
        #bimp
        exposureBlend
        fourier
        #gap
        gimplensfun
        gmic
        lightning
        lqrPlugin
        resynthesizer
        texturize
        waveletSharpen
    ]);
}
