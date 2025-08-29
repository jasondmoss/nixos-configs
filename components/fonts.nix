{ config, pkgs, ... }: {

	fonts = {
        fontDir = {
            enable = true;
            decompressFonts = config.programs.xwayland.enable;
        };

        fontconfig = {
            enable = true;
            antialias = true;

            hinting = {
                enable = true;
                style = "slight";
            };
        };

        packages = with pkgs; [
            dotcolon-fonts
            freefont_ttf
            google-fonts
            jetbrains-mono
            liberation_ttf
            paratype-pt-sans
            paratype-pt-mono
            profont
            terminus_font
            unifont
        ];
    };

}
