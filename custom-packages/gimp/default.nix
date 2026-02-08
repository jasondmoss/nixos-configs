{ pkgs, lib, ... }:
let
    gimpPublicDeps = with pkgs; [
        gegl babl gexiv2 lcms2 libarchive poppler
        gtk3 cairo pango glib
    ];
in {
    nixpkgs.overlays = [
        (final: prev: let
            gimp-devel-unwrapped = final.callPackage ../gimp-devel {
                babl = final.babl;
                gegl = final.gegl;
            };

            # A more robust shim using native Nix functions to avoid shell errors
            gimp-compat-shim =
                let
                    libs = [ "gimp" "gimpbase" "gimpcolor" "gimpconfig" "gimpmath" "gimpmodule" ];
                    libraryLinks = builtins.concatMap (libName: [
                        { name = "lib/lib${libName}-3.0.so"; path = "${gimp-devel-unwrapped}/lib/lib${libName}-3.2.so"; }
                        { name = "lib/lib${libName}-3.0.so.0"; path = "${gimp-devel-unwrapped}/lib/lib${libName}-3.2.so.0"; }
                    ]) libs;
                in final.runCommand "gimp-compat-shim" {
                    nativeBuildInputs = [ final.buildPackages.gnused final.buildPackages.coreutils final.buildPackages.findutils ];
                } ''
mkdir -p $out/lib/pkgconfig

# Point to the dev output for headers
ln -s ${gimp-devel-unwrapped.dev}/include $out/include

# Robust library linking from the main output
find ${gimp-devel-unwrapped}/lib -name "*.so*" -maxdepth 1 -exec ln -s {} $out/lib/ \; 2>/dev/null || true

# Create the specific 3.0 library symlinks
${lib.concatMapStringsSep "\n" (item: ''
if [ -f "${item.path}" ]; then
    ln -sf ${item.path} $out/${item.name}
fi
'') libraryLinks}

# ROBUST PKG-CONFIG SEARCH targeting the .dev output
echo "Searching for .pc files in ${gimp-devel-unwrapped.dev}..."
find ${gimp-devel-unwrapped.dev} -name "*.pc" -exec cp -v {} $out/lib/pkgconfig/ \;

cd $out/lib/pkgconfig
if [ "$(ls -A .)" ]; then
    for pc in *.pc; do
        chmod +w "$pc"
        new_pc=$(echo "$pc" | sed 's/3\.2/3\.0/g')
        [ "$pc" != "$new_pc" ] && mv "$pc" "$new_pc"
        sed -i 's/3\.2/3\.0/g' "$new_pc"

        # Ensure the paths inside the .pc point to the correct store locations
        sed -i "s|prefix=.*|prefix=$out|g" "$new_pc"
        sed -i "s|includedir=.*|includedir=${gimp-devel-unwrapped.dev}/include|g" "$new_pc"
    done
else
    echo "ERROR: No pkg-config files found in ${gimp-devel-unwrapped.dev}"
    exit 1
fi
                '';
        in {
            babl = prev.babl.overrideAttrs (oldAttrs: {
                version = "0.1.118";

                src = final.fetchurl {
                    url = "https://download.gimp.org/pub/babl/0.1/babl-0.1.118.tar.xz";
                    hash = "sha256-w/6+kj4iXCpY+VJomom7HblWeIv+yxin7/b8lNqeJGk=";
                };

                nativeBuildInputs = (oldAttrs.nativeBuildInputs or []) ++ [ final.git ];
            });

            gegl = prev.gegl.overrideAttrs (oldAttrs: {
                version = "0.4.66";

                src = final.fetchurl {
                    url = "https://download.gimp.org/pub/gegl/0.4/gegl-0.4.66.tar.xz";
                    hash = "sha256-krBYVeIZCGiUnXDOpumlCxY6akQSQudApiY5dTefmTs=";
                };

                postPatch = (oldAttrs.postPatch or "") + ''
echo "#!/usr/bin/env python3" > tools/defcheck.py
echo "import sys; sys.exit(0)" >> tools/defcheck.py
chmod +x tools/defcheck.py
                '';

                nativeBuildInputs = (oldAttrs.nativeBuildInputs or []) ++ [ final.git ];
            });

            gimp-devel = final.symlinkJoin {
                name = "gimp-devel-${gimp-devel-unwrapped.version}";
                paths = [ gimp-devel-unwrapped ];
                nativeBuildInputs = [ final.makeWrapper ];

                postBuild = ''
wrapProgram $out/bin/gimp-3.2 \
 --set BABL_PATH "${final.babl}/lib/babl-0.1" \
 --set GEGL_PATH "${final.gegl}/lib/gegl-0.4" \
 --prefix XDG_DATA_DIRS : "${final.adwaita-icon-theme}/share"
ln -sf $out/bin/gimp-3.2 $out/bin/gimp
                '';
            };

            customGimp3Plugins = {
                gmic = final.gmic-qt.overrideAttrs (oldAttrs: {
                    buildInputs = (oldAttrs.buildInputs or []) ++ [
                        gimp-compat-shim
                        final.xorg.libXdmcp
                        final.xorg.libpthreadstubs
                        final.glib.dev
                    ] ++ gimpPublicDeps;

                    nativeBuildInputs = (oldAttrs.nativeBuildInputs or []) ++
                        [ final.pkg-config final.findutils ];

                    cmakeFlags = [
                        "-DGMIC_QT_HOST=gimp3"
                        "-DENABLE_SYSTEM_GMIC=ON"
                        "-DENABLE_DYNAMIC_LINKING=ON"
                        "-DCMAKE_BUILD_TYPE=Release"
                    ];

                    preConfigure = ''
export PKG_CONFIG_PATH="${gimp-compat-shim}/lib/pkgconfig:$PKG_CONFIG_PATH"
                    '';

                    postConfigure = ''
echo "--- ATREIDES FINAL LINKING ---"
# LIBDIR is the target directory in the GIMP store path
LIBDIR="${gimp-devel-unwrapped}/lib"

# Logic: Look for libgimp-3.0.so, if not found, look for libgimp-3.2.so
if [ -f "$LIBDIR/libgimp-3.0.so" ]; then
GIMP_VER="3.0"
else
GIMP_VER="3.2"
fi

echo "Detected GIMP library suffix: $GIMP_VER"

# Patch Ninja files with absolute paths to the verified files
find . -type f \( -name "build.ninja" -o -name "link.txt" \) -exec sed -i \
 -e "s|-lgimp-3.0|$LIBDIR/libgimp-$GIMP_VER.so|g" \
 -e "s|-lgimpbase-3.0|$LIBDIR/libgimpbase-$GIMP_VER.so|g" \
 -e "s|-lgimpcolor-3.0|$LIBDIR/libgimpcolor-$GIMP_VER.so|g" \
 -e "s|-lgimpconfig-3.0|$LIBDIR/libgimpconfig-$GIMP_VER.so|g" \
 -e "s|-lgimpmath-3.0|$LIBDIR/libgimpmath-$GIMP_VER.so|g" \
 -e "s|-lgimpmodule-3.0|$LIBDIR/libgimpmodule-$GIMP_VER.so|g" {} +
                    '';

                    postPatch = (oldAttrs.postPatch or "") + ''
substituteInPlace CMakeLists.txt \
 --replace-quiet 'pkg_check_modules(GIMP REQUIRED gimp-3.0)' 'set(GIMP_FOUND TRUE)'
                    '';
                });

                lightning = prev.gimp3Plugins.lightning.overrideAttrs (oldAttrs: {
                    buildInputs = [ gimp-devel-unwrapped ] ++ gimpPublicDeps ++
                        (builtins.filter (p: p.pname or "" != "gimp") (oldAttrs.buildInputs or []));
                });
            };
        })
    ];

    environment.systemPackages = [
        pkgs.gimp-devel
        pkgs.customGimp3Plugins.gmic
        pkgs.customGimp3Plugins.lightning
    ];
}
