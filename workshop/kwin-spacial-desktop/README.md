# kwin-spacial-desktop

A KWin effect plugin (Plasma 6, Wayland) implementing the core mechanic of Scott Jenson's
[Desktop5](https://github.com/scottjenson/Desktop5) spatial desktop concept:

> The center of the screen is a full-scale focus area. Windows **shrink smoothly along a
> warp curve as you drag them toward the screen edges**, so the periphery becomes a place
> to park live work-in-progress at a glance.

## How it works

- **During a drag** the shrink is a cosmetic paint transform — the window's rendering scales
  down under your cursor as it enters the flank zones, exactly like the web prototype.
  (Pointer input is captive to the move operation, so no input remapping is needed.)
- **On release in a flank** the window parks at the nearest of two columns per side, at the
  warp-derived scale. Two park modes (KCM toggle):
  - **Live miniatures** (default) — the window is really minimized while a visible-ref keeps
    its scene item painted, so the client stays unsuspended and the miniature is a *live,
    photographic* scale-down of the full-size layout (the Desktop5 look). Clicking a
    miniature (or its taskbar entry, or alt-tab) restores it to its untouched natural
    geometry — and **dragging a miniature grabs it back into a real drag**: it slides out
    along the warp curve, growing as it approaches the center; release re-parks or restores.
  - **Real resize** — the window is genuinely resized small and stays directly interactive
    (scroll, type, click), at the cost of the app re-layouting to the small size.
- **Drag a resize-parked window back** past the dead-zone boundary and release: it restores
  to its remembered natural geometry.
- **Shake-to-stash**: while dragging a window, wiggle it horizontally (4 direction reversals
  of ≥20 px within 500 ms) — every *other* full-size window sweeps into the parking columns,
  split by which half of the screen it occupied, recent windows in the inner (larger)
  columns. The dragged window stays under your cursor.
- **Drag rails**: while a window is dragged, the horizontal grid lines passing behind it
  brighten (×1.6) and thicken (×2.2) across the full screen width — a live readout of where
  the window sits on the curve. Fades in 150 ms, out 250 ms.
- **The warped grid background** renders over the wallpaper (under all windows): vertical
  lines live in warped space and compress toward the flanks at exactly the rate windows
  shrink; horizontal lines converge toward the screen equator by the curve's local scale.
  Lines are a crisp core + soft glow with edge fading, straight out of Desktop5's shader.
  Modes: always visible, only-while-dragging (200 ms fade), or off; color, cell size,
  brightness, and an optional wallpaper-dimming backdrop are configurable.

The warp math is a faithful port of Desktop5's `js/warp.js`: the window scale is the
analytical derivative of the background grid warp curve
(`f(x) = x + sign(x)·flankDist^power·strength`), with the grab offset held constant in
logical (warped) space so the grabbed point stays under the cursor as the window shrinks.

## Configuration

All dials are in System Settings → Desktop Effects → Spacial Desktop (gear icon):

| Dial | Default | Meaning |
|---|---|---|
| Park zone left / right | on / off | Per-side park zones; a disabled side has normal geometry |
| Live miniatures | on | Park as painted miniatures (off = real resize) |
| Shake to stash | on | Wiggle a dragged window to park all others |
| Drag rails | on | Highlight grid lines behind a dragged window |
| Grid | always | Warped grid background: off / always / only while dragging |
| Grid color / cell / brightness | #5a6acf / 86 px / 0.5 | Grid line look |
| Dim wallpaper behind grid | 0.0 | 0 = untouched wallpaper, 1 = black backdrop |
| Dead zone | 0.72 | Fraction of the half-screen that stays full scale before a park zone |
| Warp power | 3.0 | Curve exponent (3 = C²-smooth cubic bend) |
| Warp strength | 1.33 | Edge compression |
| Min scale | 0.20 | Scale floor during a drag |
| Inner/outer column | 0.35 / 0.75 | Parking column positions as fractions of the park zone |
| Animations | on, 250 ms | Crossfade + size/position blend on park/restore |

Config group: `[Effect-spacialdesktop]` in `kwinrc`.

## Building

Standard KDE CMake project. Requires KWin dev headers matching the **exact** running KWin
version (the effect plugin ABI is version-locked; rebuild on every KWin upgrade — automatic
under NixOS via the `configs/packages/kwin-spacial-desktop` derivation).

```sh
cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DKDE_INSTALL_USE_QT_SYS_PATHS=ON
cmake --build build
```

### Fast iteration without touching your session

```sh
cmake --build build
env QT_PLUGIN_PATH="$PWD/build/bin:$QT_PLUGIN_PATH" dbus-run-session bash -c '
  kwin_wayland --width 1920 --height 1080 --socket spacial-test --xwayland &
  sleep 3
  qdbus org.kde.KWin /Effects org.kde.kwin.Effects.loadEffect spacialdesktop
  WAYLAND_DISPLAY=spacial-test konsole & wait'
```

## Design notes

KWin effects can paint a window scaled anywhere, but hit-testing always uses the real
window geometry — there is **no API to remap input** to a transformed window (verified
against KWin 6.7.3 source; the modal Overview effect grabs *all* input instead). Hence the
two park modes: miniatures are photographic but display-only (clicks pass through to the
desktop beneath; we observe them via `EffectsHandler::mouseChanged` and restore), while
real-resize keeps windows directly interactive. The miniature mode stays *live* because
KWin only suspends a client when its scene item is invisible, and our
`EffectWindowVisibleRef` keeps it visible. Squash/Magic Lamp minimize animations are
suppressed for our own park/restore by briefly claiming the active-fullscreen-effect slot
around the synchronous `setMinimized()` call; on external unminimizes their animation
plays and ours yields. Still deferred: warped grid background, shake-to-stash, drag rails,
exposé, multi-screen.

## License

GPL-2.0-or-later (links against KWin).
