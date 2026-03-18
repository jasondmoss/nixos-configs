# plasma-dock

A macOS-style application dock for KDE Plasma 6, built with Qt6/QML and the
`zwlr_layer_shell_v1` Wayland protocol.

## Project layout

```
plasma-dock/
├── CMakeLists.txt          Build configuration
├── package.nix             Nix derivation (drop into custom-packages/)
├── protocols/
│   └── wlr-layer-shell-unstable-v1.xml   Protocol spec → C bindings via wayland-scanner
├── src/
│   ├── main.cpp            App entry, WaylandRegistry init, QML engine setup
│   ├── waylandregistry.h/cpp   Walks wl_registry to grab zwlr_layer_shell_v1
│   └── layershellwindow.h/cpp  QQuickWindow subclass with layer shell plumbing
└── qml/
    ├── main.qml            Root window (LayerShellWindow), dock body
    └── DockIconPlaceholder.qml   Icon + magnify + running indicator scaffold
```

## Phase 1 goal (this skeleton)

Validate that the window pins to the screen bottom, reserves an exclusive zone,
has no titlebar, and survives compositor configure events.  Everything else
(real icons, KService, magnification, drag-drop) builds on top of this.

## Build (manual, outside Nix)

```bash
mkdir build && cd build
cmake .. \
  -DCMAKE_BUILD_TYPE=Debug \
  -DCMAKE_PREFIX_PATH="/path/to/qt6;/path/to/kf6"
make -j$(nproc)
QT_QPA_PLATFORM=wayland ./plasma-dock
```

## Build (Nix)

Copy `package.nix` to `~/Repository/system/nixos/configs/custom-packages/plasma-dock.nix`.
Add to your overlay or `pkgs.callPackage` directly:

```nix
# In your packages.nix or an overlay:
plasma-dock = pkgs.callPackage ./custom-packages/plasma-dock.nix {};
```

Then `sudo nixos-rebuild switch` and run `plasma-dock`.

## What to test first

1. Does the dock window appear at the bottom without a titlebar? ✓ layer shell working
2. Does a maximised terminal stop at the dock edge? ✓ exclusive zone working
3. Try changing `edge: LayerShellWindow.Top` in main.qml and rebuild — it should move.

## Next phases

- Phase 2: AppModel (QAbstractListModel backed by KSycoca), real icon images
- Phase 3: Magnification effect driven by Row MouseArea + distance function
- Phase 4: KWindowSystem window tracking → isRunning indicator
- Phase 5: Right-click context menu with KServiceAction jump lists
- Phase 6: Drag-and-drop reordering + drop from Dolphin/launcher
- Phase 7: KConfig persistence (pinned apps, edge preference, dock size)
- Phase 8: Multi-monitor support, per-screen dock instances
