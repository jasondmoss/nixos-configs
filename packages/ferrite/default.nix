{
    lib, rustPlatform, fetchFromGitHub, pkg-config, wrapGAppsHook3, gtk3,
    libxkbcommon, wayland, vulkan-loader, libGL, xorg, libxcb,
}:

rustPlatform.buildRustPackage rec {
    pname = "ferrite";
    version = "0.3.0";

    src = fetchFromGitHub {
        owner = "OlaProeis";
        repo  = "Ferrite";
        rev   = "v${version}";
        hash  = "sha256-fo5Bj5he2rFdtdjHrFcnv66IRIyLYOxPiYE0b0Jplas=";
    };

    cargoHash = "sha256-c56S8AcJgrmLptHEDDZxBoya/NaWX4cdPQoQCT8pvO0=";

    nativeBuildInputs = [
        pkg-config
        wrapGAppsHook3
    ];

    buildInputs = [
        gtk3
        libxkbcommon
        libxcb
        libGL
        wayland
        vulkan-loader
        xorg.libXcursor
        xorg.libXi
        xorg.libXrandr
    ];

    # Upstream test suite requires a display; skip.
    doCheck = false;

    # winit dlopen-s libwayland-client.so at runtime; expose it (and the other
    # graphics libs) via LD_LIBRARY_PATH so the wrapper can find them.
    preFixup = ''
        gappsWrapperArgs+=(
            --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [
                wayland
                libGL
                vulkan-loader
                libxkbcommon
            ]}"
        )
    '';

    postInstall = ''
# Desktop entry
install -Dm644 assets/linux/io.github.olaproeis.Ferrite.desktop \
 $out/share/applications/io.github.olaproeis.Ferrite.desktop

# Hicolor icons (all sizes shipped by upstream)
for size in 16x16 32x32 48x48 64x64 128x128 256x256 512x512; do
    install -Dm644 assets/icons/linux/$size/ferrite.png \
 $out/share/icons/hicolor/$size/apps/io.github.olaproeis.Ferrite.png
done
    '';

    meta = with lib; {
        description = "Fast, lightweight text editor for Markdown, JSON, YAML, and TOML files";
        longDescription = ''
            Ferrite is a native, responsive text editor built with Rust and egui.
            Features include WYSIWYG Markdown editing, executable code blocks,
            multi-cursor support, syntax highlighting, Git integration, and an
            integrated terminal workspace.
        '';
        homepage  = "https://github.com/OlaProeis/Ferrite";
        changelog = "https://github.com/OlaProeis/Ferrite/blob/v${version}/CHANGELOG.md";
        license   = licenses.mit;
        platforms = platforms.linux;
        mainProgram = "ferrite";
    };
}

# <> #
