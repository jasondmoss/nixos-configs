{ pkgs, ... }: {
    environment.systemPackages = (with pkgs; [

        gegl
        gimp

    ]) ++ (with pkgs.gimpPlugins; [

        bimp
        exposureBlend
        fourier
        gap
        gimplensfun
        gmic
        lightning
        lqrPlugin
        resynthesizer
        texturize
        waveletSharpen

    ]);
}
