# NixOS Configurations

NixOS 25.11 desktop configuration for **atreides** — an AMD Ryzen 9 3900X workstation
with an NVIDIA RTX 2060, 32 GiB RAM, running KDE Plasma 6 on Wayland.

This is a **traditional NixOS module system** configuration — no flakes, channel-based
nixpkgs only. The entry point is `configuration.nix`.

---

## System Profile

| Component       | Details                              |
|-----------------|--------------------------------------|
| CPU             | AMD Ryzen 9 3900X                    |
| GPU             | NVIDIA RTX 2060                      |
| RAM             | 32 GiB                               |
| Kernel          | Linux (xanmod-latest)                |
| Bootloader      | systemd-boot (EFI)                   |
| Display server  | Wayland                              |
| Desktop         | KDE Plasma 6                         |
| Display manager | Ly (TTY-based)                       |
| Audio           | PipeWire (ALSA + PulseAudio + JACK)  |
| NixOS channel   | unstable (25.11)                     |

---

## Filesystems

| Mount point         | Device       | FS    | Notes                          |
|---------------------|--------------|-------|--------------------------------|
| `/`                 | nvme0n1p2    | ext4  | Root (NVMe)                    |
| `/home`             | nvme1n1p1    | Btrfs | zstd:1, Snapper snapshots      |
| `~/Repository`      | sdb2         | Btrfs | zstd:1, Snapper snapshots      |
| `~/Mega`            | sdb2         | ext4  | MEGAsync storage               |
| `~/Music`           | sdc1         | ext4  | Music library                  |
| `~/Videos/Movies`   | sda1         | ext4  | Movie library                  |
| `~/Videos/Television` | sdd        | ext4  | TV library                     |
| `/boot/efi`         | vfat         | vfat  | EFI partition                  |
| (swapfile)          | /swapfile    | —     | 16 GiB                         |

---

## Module Structure

### Hardware (`hardware/`)

| File             | Purpose                                                               |
|------------------|-----------------------------------------------------------------------|
| `boot.nix`       | xanmod kernel, systemd initrd, systemd-boot, filesystem mounts, swap |
| `gpu.nix`        | NVIDIA proprietary driver, VAAPI, Vulkan, DRM modesetting             |
| `peripherals.nix`| Bluetooth, QMK keyboard firmware, printing, SMART monitoring, udev   |
| `power.nix`      | AMD CPU microcode, `amd_pstate=active`, TLP power management          |

**Kernel params:** `amd_iommu=on`, `amd_pstate=active`, `nvidia-drm.modeset=1`, `nvidia-drm.fbdev=1`. nouveau and `i2c-nvidia_gpu` are blacklisted.

**Kernel hardening:** `kptr_restrict=2`, `unprivileged_bpf_disabled=1`, `bpf_jit_harden=2`, `yama.ptrace_scope=1`.

---

### Desktop (`desktop/`)

| File        | Purpose                                                                    |
|-------------|----------------------------------------------------------------------------|
| `plasma.nix`| KDE Plasma 6, Ly display manager, XDG portals, Wayland/Qt session vars    |
| `fonts.nix` | Font packages and fontconfig rules                                         |
| `theme.nix` | 16-color terminal palette (plain Nix value, imported by `configuration.nix`) |

**Plasma 6** is configured with Qt 6 only (`enableQt5Integration = false`), RHI
rendering backend (`QT_QUICK_BACKEND = rhi`), and XDG portal delegation for KDE/GTK.

**Input method:** fcitx5 with Wayland frontend and Chinese add-ons.

---

### System

| File             | Purpose                                                                  |
|------------------|--------------------------------------------------------------------------|
| `nixpkgs.nix`    | Host platform, unfree allowlist, overlays (Firefox Nightly, PhpStorm, libQuotient) |
| `identity.nix`   | User identity values — plain Nix value, not a module (see below)         |
| `networking.nix` | iptables firewall (TCP 22/80/443), NetworkManager + OpenVPN, CoreDNS (local resolver), OpenSSH (key-only, root disabled) |
| `security.nix`   | PAM, polkit rules, sudo configuration                                    |
| `users.nix`      | User account and group memberships                                       |
| `environment.nix`| Session/env vars, XDG base dirs, GStreamer paths, per-host git configs, 1Password browser allowlist |
| `programs.nix`   | git (LFS, conditional identity includes), neovim, SSH agent, GnuPG (pinentry-qt), 1Password, Steam, direnv, KDE Connect, nix-index |
| `packages.nix`   | Central package manifest, organized by category (see below)              |
| `services.nix`   | PipeWire, Snapper (Btrfs snapshots on `/home` and `~/Repository`), earlyoom, mlocate, systemd user units (megasync, notes, ssh-key-pollen) + system timer (nix-index weekly update) |

**Networking:** CoreDNS runs locally on `127.0.0.1` as the system resolver, forwarding
to Cloudflare and Google. A `local` zone resolves all `*.local` names to `127.0.0.1`.
NetworkManager inserts `127.0.0.1` as the sole nameserver.

**Nix store:** auto-optimise enabled, GC runs weekly (deletes generations older than
2 days), `experimental-features = nix-command` only (no flakes).

---

### Development (`development.nix`)

Docker (overlay2 storage driver) with weekly auto-prune, docker-compose,
docker-buildx. PHP/Apache stack via `packages/php`.

---

### AI (`ai.nix`)

| Component   | Details                                                                    |
|-------------|----------------------------------------------------------------------------|
| Ollama      | Local LLM server, CUDA-accelerated, single-GPU, 8 parallel slots, model storage at `~/Repository/ollama/models` |
| Open WebUI  | Web interface for Ollama (custom package build via `packages/open-webui`)  |
| CUDA        | `cudatoolkit` + `cudnn`, `CUDA_PATH` exported                              |
| claude-code | Anthropic Claude CLI                                                        |
| claude-monitor | Usage monitor for Claude Code                                           |

---

## Package Categories (`packages.nix`)

Packages are organized into named category lists, flattened into
`environment.systemPackages` at build time via `lib.flatten (builtins.attrValues pkgsByCategories)`.

| Category              | Contents                                                          |
|-----------------------|-------------------------------------------------------------------|
| `nixos`               | fastfetch, nixos-icons, nixos-rebuild-ng, nix-prefetch-github, nh |
| `system-tools`        | btrfs-progs, htop, lsd, inxi, pciutils, smartmontools, dysk, fwupd, etc. |
| `graphics-multimedia` | FFmpeg, mpv, Inkscape, Audacity, Shotcut, GStreamer plugins, MKVToolNix |
| `development`         | GCC, Rust/Cargo, Node.js, CMake, Qt/KDE dev tools, PhpStorm, Valgrind, Android tools |
| `kde-plasma-core`     | Plasma workspace, Baloo, KWallet, Breeze, NetworkManager-Qt, layer-shell-qt, etc. |
| `kde-applications`    | Dolphin, Kate, Kdenlive, KTorrent, Okular, Ark, KDevelop, etc.   |
| `kde-pim`             | Akonadi stack (calendar, contacts, search, MIME)                  |
| `gnome-stack`         | Nautilus, GNOME Tweaks, Adwaita icons (for GTK app compatibility) |
| `network-web`         | Firefox Nightly, Mullvad Browser, Tor Browser, ProtonVPN, megatools, Google Chrome, Microsoft Edge |
| `office`              | LibreOffice (Qt/fresh), Notes, Standard Notes                     |
| `utilities`           | Wezterm, fuzzel, rofi, quickemu, p7zip, rar, conky                |
| `theming-compat`      | adwaita-qt6, Kvantum, qt6ct, Materia KDE, comixcursors            |
| `custom`              | All local package derivations (see below)                         |

KDE excluded packages: `elisa`, `itinerary`. GNOME excluded packages: decibels, geary, gnome-calculator, gnome-calendar, gnome-console, gnome-contacts, gnome-maps, gnome-music, gnome-tour, gnome-weather.

---

## Custom Packages (`packages/`)

Local derivations for software not in nixpkgs or requiring customization.

**`customPkgs` attrset** (integrated via `pkgs.callPackage` in `packages.nix`, included via `builtins.attrValues customPkgs`):

| Package                | Attrset key      |
|------------------------|------------------|
| `gemini-nix-assistant` | `gemini-nix`     |
| `gemini-cli/wrapper`   | `gemini-wrapped` |
| `gh-clone`             | `gh-clone`       |
| `kde-darkly`           | `kde-darkly`     |
| `kde-klassy`           | `kde-klassy`     |
| `nyxt-custom`          | `nyxt-custom`    |
| `strawberry-master`    | `strawberry`     |
| `vivaldi-snapshot`     | `vivaldi`        |
| `wavebox-beta`         | `wavebox`        |

**Module imports** (imported as full NixOS modules, not via `customPkgs`):

| Package          | Where imported      |
|------------------|---------------------|
| `firefox-stable` | `packages.nix`      |
| `gimp`           | `packages.nix`      |

**Overlay-based** (registered in `nixpkgs.nix` or `overlays/`):

| Package          | Mechanism                                      |
|------------------|------------------------------------------------|
| `firefox-nightly`| `overlays/nixpkgs-mozilla/firefox-overlay.nix` |
| `jetbrains` (PhpStorm) | Inline overlay in `nixpkgs.nix`          |
| `libquotient`    | Inline overlay in `nixpkgs.nix` (upstream patch) |

**Inline callPackage** in category lists:

| Package      | Location                    |
|--------------|-----------------------------|
| `mkvtoolnix` | `graphics-multimedia` list  |
| `open-webui` | `ai.nix` services block     |

---

## Workshop (`workshop/`)

In-development KDE applications built locally.

| Project             | Description                                             |
|---------------------|---------------------------------------------------------|
| `plasma-dock/`      | Custom KDE Wayland dock using wlr-layer-shell           |
| `kde-dev-shell.nix` | Nix shell environment for KDE/Qt development            |

---

## Overlays (`overlays/`)

| Overlay              | Purpose                                          |
|----------------------|--------------------------------------------------|
| `nixpkgs-mozilla/`   | Mozilla overlay providing `firefox-nightly`      |
| `default.nix`        | Top-level overlay aggregator                     |

Additional inline overlays in `nixpkgs.nix`: PhpStorm (OpenGL/font deps),
libQuotient (upstream patch).

---

## Key Conventions

- **No flakes** — traditional NixOS module system with channel-based nixpkgs only.
- **Plain Nix values** — `desktop/theme.nix` (color palette) and `identity.nix` (user
  identity) are imported with `import`, not as NixOS modules. Access their attrs
  directly (e.g. `identity.userHandle`, `theme.colors16`).
- **`identity.nix` fields** — `userName`, `userHandle`, `userHome`, `emailPersonal`,
  `emailWork`. See `identity.nix.example` for the template. This file is not committed.
- **File endings** — all `.nix` files close with a `# <> #` comment marker.
- **Adding a package** — add it to the appropriate category list in `packages.nix`. For
  a new custom derivation, add a `pkgs.callPackage ./packages/<name> {}` entry to the
  `customPkgs` attrset.
- **Unfree packages** — add the package name to `allowUnfreePredicate` in `nixpkgs.nix`.
