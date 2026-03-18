{ pkgs ? import <nixpkgs> {} }:
pkgs.mkShell {
  buildInputs = with pkgs; [
    cmake
    qt6.qtbase
    qt6.qtwayland
    qt6.qtdeclarative
    kdePackages.extra-cmake-modules
    kdePackages.kwindowsystem
    kdePackages.kservice
    kdePackages.layer-shell-qt
    kdePackages.kiconthemes
    kdePackages.breeze-icons
    wayland
    wayland-scanner
    mesa
  ];

  # Nix store files have future timestamps which confuse make's dependency
  # tracking — it thinks object files are already up-to-date.
  # Reset all source timestamps to "now" on every shell entry.
  shellHook = ''
    find "$PWD/src" "$PWD/qml" "$PWD/protocols" -type f \
      \( -name "*.cpp" -o -name "*.h" -o -name "*.qml" -o -name "*.xml" \) \
      -exec touch {} +
    echo "[shell] source timestamps reset"
  '';
}
