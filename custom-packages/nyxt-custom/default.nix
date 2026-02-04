{ pkgs, ... }:

pkgs.symlinkJoin {
    name = "nyxt-custom";
    paths = [ pkgs.nyxt ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
wrapProgram $out/bin/nyxt \
 --set WEBKIT_DISABLE_DMABUF_RENDERER 1 \
 --set GDK_BACKEND wayland
    '';
}
