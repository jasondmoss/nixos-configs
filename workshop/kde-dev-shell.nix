{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
    nativeBuildInputs = with pkgs; [
        cmake
        extra-cmake-modules
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
    ];

    shellHook = ''
        echo "KDE Plasma 6 Development Environment Loaded"
        export QT_LOGGING_RULES="*.debug=true"
    '';
}
