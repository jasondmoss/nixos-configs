self: pkgs: with pkgs.kdePackages; {
    libquotient = pkgs.kdePackages.libquotient.overrideAttrs (old: {
        patches = [
            (fetchpatch2 {
                url = "https://github.com/quotient-im/libQuotient/commit/ea83157eed37ff97ab275a5d14c971f0a5a70595.patch";
            })
        ];
    });
}
