# Perseverance — SDDM theme

Local, editable SDDM greeter theme for **atreides**. Named to match the
Perseverance KWin decoration in `configs/workshop/perseverance`.

## Provenance

Forked from **"Ocean sddm"** by *Eliver Lara* — specifically the Plasma 6
variant, `Ocean-P6`:

| | |
|---|---|
| Store listing | <https://store.kde.org/p/1430814> (item id `1430814`) |
| Upstream source | `github.com/EliverLara/Juno`, branch `ocean`, path `kde/sddm/Ocean-P6` |
| Pinned at commit | `cd7b82b01958813bcc3ee9217d00759726c94d27` |
| License | GPL-3.0-or-later; several files carry KDE's LGPL-2.0-or-later headers (David Edmundson, 2016) |

The KDE store ships `Ocean.tar.gz` (md5 `da4af723e6a1df485299e13ac562a65f`,
verified on download). Its `Ocean-P6/` directory is byte-identical to the
GitHub tree at the commit above, except that the tarball carries two extra
dead files — `__DropdownMenuStyle.qml` and `components/__VirtualKeyboard.qml`.
Both import `QtQuick.Controls 1.x` / `QtQuick.Controls.Styles`, which do not
exist in Qt 6, and neither is referenced by `Main.qml`. The GitHub tree is
used here, so they are absent.

The store's own download URL is a JWT-signed, expiring link and cannot be
pinned in Nix — which is the other reason this theme is vendored into the
repo rather than fetched.

**Do not strip the copyright headers** from the `.qml` files. This is a GPL
derivative; `metadata.desktop` credits both authors.

## Layout

```
theme/            <- the theme itself; edit freely, this is the source of truth
  Main.qml        <- entry point (MainScript in metadata.desktop)
  Login.qml
  theme.conf      <- colours, font, background
  metadata.desktop
  assets/         <- bg.jpg and the action icons
  components/     <- Clock, Battery, UserList, Input, ...
default.nix       <- copies theme/ to $out/share/sddm/themes/Perseverance
```

## Iterating

Preview in a window, straight from the working tree — no rebuild, no logout:

```bash
sddm-greeter-qt6 --test-mode \
  --theme ~/Repository/system/nixos/configs/packages/sddm-perseverance/theme
```

`--theme` is resolved against the current working directory, so a bare
`./theme` only works if you are already in this directory — otherwise you get
`file:///wherever/theme/Main.qml: No such file or directory`.

When it looks right, `sudo nixos-rebuild switch`. `src = ./theme` is a local
path, so any edit changes the derivation hash and gets rebuilt.

### Test mode does NOT report QML errors

Verified: a theme whose `Main.qml` imports a module that does not exist runs
under `--test-mode` for as long as you leave it, prints nothing to stderr, and
exits cleanly. Test mode tells you how the theme *looks*, never whether it
loaded correctly. Do not read "no output" as "no problems".

To actually validate imports, lint against the paths the greeter itself uses:

```bash
GREETER=$(readlink -f "$(command -v sddm-greeter-qt6)")
IMPORTS=$(strings -a "$GREETER" \
  | grep -oE '/nix/store/[a-z0-9]+-[^:"'"'"' ]*/lib/qt-6/qml' \
  | sort -u | sed 's/^/-I /' | tr '\n' ' ')
qmllint $IMPORTS -I ./theme ./theme/Main.qml ./theme/components/*.qml \
  | grep -E 'Failed to import|was not found\. Did you add'
```

Empty output means every import resolves. This check is known-sensitive — it
correctly flags both a bogus module name and a real import whose package is
missing from `sddm.extraPackages`.

## QML dependencies

The greeter only sees QML modules listed in
`services.displayManager.sddm.extraPackages` (see `configs/desktop/plasma.nix`).
This theme imports, beyond what `plasma6.nix` already supplies:

| Import | Package |
|---|---|
| `Qt5Compat.GraphicalEffects` | `kdePackages.qt5compat` |
| `org.kde.plasma.workspace.components` | `kdePackages.plasma-workspace` |
| `org.kde.breeze.components` | `kdePackages.plasma-workspace` |

Both were confirmed necessary: with them removed from the import path,
`Main.qml` fails on `Qt5Compat.GraphicalEffects` and `org.kde.breeze.components`
(and consequently on `GaussianBlur` and `VirtualKeyboardLoader`).

If you add an import, add its package there too, then re-run the qmllint check
above — a missing QML module makes the greeter render a blank screen with no
visible error, which is a miserable thing to debug from a TTY.

## Config overrides

SDDM merges `theme.conf.user` (same directory) over `theme.conf`. Since this
theme lives in the read-only Nix store, edit `theme/theme.conf` directly
rather than trying to drop a `.user` file next to the installed copy.
