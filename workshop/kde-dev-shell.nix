{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
    nativeBuildInputs = with pkgs; [
        cmake
        kdePackages.extra-cmake-modules
        ninja
        pkg-config
    ];

    buildInputs = with pkgs.kdePackages; [
        qtbase
        qtdeclarative
        ki18n
        kconfig
        kcoreaddons
        kirigami
        kio

        # KWin effect development (workshop/kwin-spacial-desktop)
        kwin
        kcmutils
        kwindowsystem
        kguiaddons
    ] ++ (with pkgs; [
        libepoxy
        libdrm
        vulkan-headers
        vulkan-loader
        wayland
        wayland-protocols
    ]);

    shellHook = ''
        echo "KDE Plasma 6 Development Environment Loaded"
        export QT_LOGGING_RULES="*.debug=true"
    '';
}
