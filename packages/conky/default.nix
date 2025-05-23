self: pkgs: with pkgs; {
    conky = pkgs.conky.overrideAttrs (old: {
#        version = "1.22.1";
        version = "master";

        src = pkgs.fetchFromGitHub {
            owner = "brndnmtthws";
            repo = "conky";
#            rev = "v1.22.1";
#            sha256 = "sha256-tEJQWZBaiX/bONPZEuGcvbGidktcvxUZtLvcGjz71Lk=";
            rev = "main";
            sha256 = "sha256-lwYfltqKh60hf4k8tYIrOMT5FS5G7GLF3fLLV5FbI5I=";
        };

        # Remove patches.
        patches = [ ];

        nativeBuildInputs = old.nativeBuildInputs ++ [
            pkgs.cairo
            pkgs.clang-tools
            pkgs.expat
            pkgs.glib
            pkgs.gperf
            pkgs.iw
            pkgs.libmicrohttpd
            pkgs.libsysprof-capture
            pkgs.mount
            pkgs.pcre2
            pkgs.sccache
            pkgs.xorg.libXdmcp
        ];

        cmakeFlags = old.cmakeFlags ++ [
            "-DMAINTAINER_MODE=OFF"
            "-DBUILD_WAYLAND=ON"
            "-DBUILD_HTTP=ON"
        ];
    });
}
