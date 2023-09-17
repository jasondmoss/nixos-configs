{
    stdenv, lib, fetchurl, fetchFromGitHub, fetchpatch, substituteAll, meson,
    ninja, pkg-config, babl, gegl, gtk3, glib, gdk-pixbuf, graphviz, isocodes,
    pango, cairo, libarchive, luajit, freetype, fontconfig, lcms, libpng,
    libjpeg, libjxl, poppler, poppler_data, libtiff, libmng, librsvg, libwmf,
    zlib, libzip, ghostscript, aalib, shared-mime-info, python3, libexif,
    gettext, wrapGAppsHook, libxslt, gobject-introspection, vala, gi-docgen,
    perl, appstream-glib, desktop-file-utils, xorg, glib-networking, json-glib,
    libmypaint, gexiv2, harfbuzz, mypaint-brushes1, libwebp, libheif, gjs,
    libgudev, openexr, xvfb-run, dbus, gnome, hicolor-icon-theme, alsa-lib,
    unstableGitUpdater
}:

let
    python = python3.withPackages (pp: with pp; [
        pygobject3
    ]);
in stdenv.mkDerivation (finalAttrs: {
    pname = "gimp";
    version = "2_99_16+date=2023-07-09";

    outputs = [ "out" "dev" "devdoc" ];

    src = fetchFromGitHub rec {
        name = "gimp-dev-${rev}";
        owner = "GNOME";
        repo = "gimp";
        rev = "ad7a2e53eb72ef471566fa2d0ce9faeec929fbcf";
        sha256 = "sha256-IJMUJc817EDWIRqqkCuwAcSw7gcgCkXxPan5fEq1AO0=";
    };

    patches = [
        # to remove compiler from the runtime closure, reference was retained via
        # gimp --version --verbose output
        (substituteAll {
            src = ./remove-cc-reference.patch;
            cc_version = stdenv.cc.cc.name;
        })

        # Use absolute paths instead of relying on PATH to make sure plug-ins are
        # loaded by the correct interpreter.
        (substituteAll {
            src = ./hardcode-plugin-interpreters.patch;
            python_interpreter = python.interpreter;
        })

        # D-Bus configuration is not available in the build sandbox so we need to
        # pick up the one from the package.
        (substituteAll {
            src = ./tests-dbus-conf.patch;
            session_conf = "${dbus.out}/share/dbus-1/session.conf";
        })

        # Since we pass absolute datadirs to Meson, the path is resolved
        # incorrectly. What is more, even the assumption that iso-codes have the
        # same datadir subdirectory as GIMP is incorrect. Though, there is not a
        # way to obtain the correct directory at the moment. There is a MR against
        # isocodes to fix that:
        # @see https://salsa.debian.org/iso-codes-team/iso-codes/merge_requests/11
        ./fix-isocodes-paths.patch
    ];

    nativeBuildInputs = [
        meson
        ninja
        pkg-config
        gettext
        wrapGAppsHook
        libxslt # For xsltproc
        gobject-introspection
        perl
        vala

        # For docs
        gi-docgen

        # For tests
        desktop-file-utils
        xvfb-run
        dbus
    ];

    buildInputs = [
        appstream-glib # For library
        babl
        gegl
        gtk3
        glib
        gdk-pixbuf
        pango
        cairo
        libarchive
        gexiv2
        harfbuzz
        isocodes
        freetype
        fontconfig
        lcms
        libpng
        libjpeg
        libjxl
        poppler
        poppler_data
        libtiff
        openexr
        libmng
        librsvg
        libwmf
        zlib
        libzip
        ghostscript
        aalib
        shared-mime-info
        json-glib
        libwebp
        libheif
        python
        libexif
        xorg.libXpm
        xorg.libXmu
        glib-networking
        libmypaint
        mypaint-brushes1

        # New file dialogue crashes with "Icon 'image-missing' not present in
        # theme Symbolic" without an icon theme.
        gnome.adwaita-icon-theme

        # For Lua plug-ins
        (luajit.withPackages (pp: [
            pp.lgi
        ]))
    ] ++ lib.optionals (!stdenv.isDarwin) [
        alsa-lib

        # For JavaScript plug-ins
        gjs
    ] ++ lib.optionals stdenv.isLinux [
        libgudev
    ];

    # Needed by gimp-2.0.pc
    propagatedBuildInputs = [
        gegl
    ];

    mesonFlags = [
        "-Dbug-report-url=https://github.com/NixOS/nixpkgs/issues/new"
        "-Dicc-directory=/run/current-system/sw/share/color/icc"
        "-Dcheck-update=no"
        # Requires newer appstreamcli and not necessary
        "-Dappdata-test=disabled"
    ] ++ lib.optionals stdenv.isDarwin [
        "-Dalsa=disabled"
        "-Djavascript=false"
    ];

    # On Linux, unable to find icons
    doCheck = true;

    env = {
        # The check runs before glib-networking is registered
        GIO_EXTRA_MODULES = "${glib-networking}/lib/gio/modules";

        NIX_CFLAGS_COMPILE = lib.optionalString stdenv.isDarwin "-DGDK_OSX_BIG_SUR=16";

        # Check if librsvg was built with --disable-pixbuf-loader.
        PKG_CONFIG_GDK_PIXBUF_2_0_GDK_PIXBUF_MODULEDIR = "${librsvg}/${gdk-pixbuf.moduleDir}";
    };

    postPatch = ''
        patchShebangs \
            app/tests/create_test_env.sh \
            tools/gimp-mkenums

        # Bypass the need for downloading git archive.
        substitute app/git-version.h.in git-version.h \
            --subst-var-by GIMP_GIT_VERSION "GIMP_2.99.?-g${builtins.substring 0 10 finalAttrs.src.rev}" \
            --subst-var-by GIMP_GIT_VERSION_ABBREV "${builtins.substring 0 10 finalAttrs.src.rev}" \
            --subst-var-by GIMP_GIT_LAST_COMMIT_YEAR "${builtins.head (builtins.match ".+\+date=([0-9]{4})-[0-9]{2}-[0-9]{2}" finalAttrs.version)}"
    '';

    preCheck = ''
        # Avoid “Error retrieving accessibility bus address”
        export NO_AT_BRIDGE=1
        # Fix storing recent file list in tests
        export HOME="$TMPDIR"
        export XDG_DATA_DIRS="${glib.getSchemaDataDirPath gtk3}:$XDG_DATA_DIRS"
    '';

    checkPhase = ''
        runHook preCheck

        meson test --timeout-multiplier 4 --print-errorlogs

        runHook postCheck
    '';

    preFixup = ''
        gappsWrapperArgs+=(--prefix PATH : "${lib.makeBinPath [
            # For dot for gegl:introspect
            # (Debug » Show Image Graph, hidden by default on stable release)
            graphviz
        ]}:$out/bin")
    '';

    postFixup = ''
        # Cannot be in postInstall, otherwise _multioutDocs hook in preFixup will
        # move right back.
        moveToOutput "share/doc" "$devdoc"
    '';

    passthru = {
        # The declarations for `gimp-with-plugins` wrapper, used for determining
        # plug-in installation paths
        majorVersion = "2.99";
        targetLibDir = "lib/gimp/${finalAttrs.passthru.majorVersion}";
        targetDataDir = "share/gimp/${finalAttrs.passthru.majorVersion}";
        targetPluginDir = "${finalAttrs.passthru.targetLibDir}/plug-ins";
        targetScriptDir = "${finalAttrs.passthru.targetDataDir}/scripts";

        # Probably its a good idea to use the same gtk in plugins?
        gtk = gtk3;

        updateScript = unstableGitUpdater {
            stableVersion = true;
            tagPrefix = "GIMP_";
        };
    };

    meta = with lib; {
        description = "The GNU Image Manipulation Program";
        homepage = "https://www.gimp.org/";
        maintainers = with maintainers; [ jtojnar ];
        license = licenses.gpl3Plus;
        platforms = platforms.unix;
        mainProgram = "gimp";
    };

})
