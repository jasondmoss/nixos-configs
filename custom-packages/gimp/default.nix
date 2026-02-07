{ pkgs, ... }: {
    nixpkgs.overlays = [
        (final: prev: {
            babl = prev.babl.overrideAttrs (oldAttrs: {
                version = "0.1.118";
                src = final.fetchurl {
                    url = "https://download.gimp.org/pub/babl/0.1/babl-0.1.114.tar.xz";
                    hash = "sha256-vLt3hsHkR3A9s7x/o01i0NLRF7IvBNiDTHstXe1FZIc=";
                };
            });

            gegl = prev.gegl.overrideAttrs (oldAttrs: {
                version = "0.4.66";
                src = final.fetchurl {
                    url = "https://download.gimp.org/pub/gegl/0.4/gegl-0.4.62.tar.xz";
                    hash = "sha256-WIdXY3Hr8dnpB5fRDkuafxZYIo1IJ1g+eeHbPZRQXGw=";
                };
            });
        })
    ];

    environment.systemPackages = (with pkgs; [
        babl
        gegl

        # Stable version
#        gimp3

        # Development version (currently RC2)
        (pkgs.callPackage ../gimp-devel {})
    ]) ++ (with pkgs.gimp3Plugins; [
#        bimp
#        exposureBlend
#        fourier
#        gap
#        gimplensfun
        gmic
        lightning
#        lqrPlugin
#        resynthesizer
#        texturize
#        waveletSharpen
    ]);
}
