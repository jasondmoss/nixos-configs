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

## Module Structure

### Hardware (`hardware/`)

| File             | Purpose                                                               |
|------------------|-----------------------------------------------------------------------|
| `boot.nix`       | xanmod kernel, systemd initrd, systemd-boot, filesystem mounts, swap |
| `gpu.nix`        | NVIDIA proprietary driver, VAAPI, Vulkan, DRM modesetting             |
| `peripherals.nix`| Bluetooth, QMK keyboard firmware, printing, SMART monitoring, udev   |
| `power.nix`      | AMD CPU microcode, `amd_pstate=active`, TLP power management          |

**Filesystems:** root on ext4 (NVMe), `/home` and `Repository` on Btrfs with zstd
compression, separate ext4 partitions for media libraries. 16 GiB swap file.

**Kernel hardening:** `kernel.kptr_restrict`, `unprivileged_bpf_disabled`,
`bpf_jit_harden`, `yama.ptrace_scope`, nouveau blacklisted.

---

### Desktop (`desktop/`)

| File        | Purpose                                                                    |
|-------------|----------------------------------------------------------------------------|
| `plasma.nix`| KDE Plasma 6, Ly display manager, XDG portals, Wayland/Qt session vars    |
| `fonts.nix` | Font packages and fontconfig rules                                         |
| `theme.nix` | 16-color terminal palette (plain Nix value, imported by configuration.nix) |

**Plasma 6** is configured with Qt 6 only (`enableQt5Integration = false`), RHI
rendering backend (`QT_QUICK_BACKEND = rhi`), and XDG portal delegation for KDE/GTK.

**Input method:** fcitx5 with Wayland frontend and Chinese add-ons.

---

### System

| File             | Purpose                                                                  |
|------------------|--------------------------------------------------------------------------|
| `nixpkgs.nix`    | Host platform, unfree allowlist, overlays (Firefox Nightly, PhpStorm, libQuotient) |
| `identity.nix`   | User identity values (handle, home path) — plain Nix value, not a module |
| `networking.nix` | nftables firewall, NetworkManager + OpenVPN, CoreDNS (local resolver), OpenSSH |
| `security.nix`   | PAM, polkit rules, sudo configuration                                    |
| `users.nix`      | User account and group memberships                                       |
| `environment.nix`| Session/env vars, XDG base dirs, GStreamer paths, per-host git configs, 1Password browser allowlist |
| `programs.nix`   | git (LFS, conditional identity includes), neovim, SSH agent, GnuPG (pinentry-qt), 1Password, Steam, direnv, KDE Connect, nix-index |
| `packages.nix`   | Central package manifest, organized by category (see below)              |
| `services.nix`   | PipeWire, Snapper (Btrfs snapshots), earlyoom, locate, systemd user units (megasync, notes, ssh-key-pollen, nix-index updater) |

**Networking:** CoreDNS runs locally on `127.0.0.1` as the system resolver, forwarding
to Cloudflare (1.1.1.1) and Google (8.8.8.8). SSH allows only key authentication;
root login disabled.

**Nix store:** auto-optimise enabled, GC runs weekly (deletes generations older than
2 days), `experimental-features = nix-command` only (no flakes).

---

### Development (`development.nix`)

Docker (v25, overlay2 storage driver) with weekly auto-prune, docker-compose,
docker-buildx. PHP/Apache stack via `packages/php`.

---

### AI (`ai.nix`)

| Component       | Details                                                          |
|-----------------|------------------------------------------------------------------|
| Ollama          | Local LLM server, CUDA-accelerated, single-GPU, 8 parallel slots|
| Open WebUI      | Web interface for Ollama (custom package build)                  |
| Automatic1111   | SD.Next Stable Diffusion WebUI, runs as a systemd user service   |
| CUDA            | `cudatoolkit` + `cudnn`, `CUDA_PATH` exported                    |
| claude-code     | Anthropic Claude CLI                                             |
| claude-monitor  | Usage monitor for Claude Code                                    |
| oterm           | TUI client for Ollama                                            |

---

## Package Categories (`packages.nix`)

Packages are organized into named category lists, flattened into
`environment.systemPackages` at build time.

| Category            | Contents                                                          |
|---------------------|-------------------------------------------------------------------|
| `nixos`             | nixos-icons, nixos-rebuild-ng, nix-prefetch-github               |
| `system-tools`      | btrfs-progs, htop, lsd, inxi, pciutils, smartmontools, dysk, fwupd, etc. |
| `graphics-multimedia` | FFmpeg, mpv, Inkscape, Audacity, Shotcut, GStreamer plugins, MKVToolNix |
| `development`       | GCC, Rust/Cargo, Node.js, CMake, Qt/KDE dev tools, PhpStorm, Valgrind, Android tools |
| `kde-plasma-core`   | Plasma workspace, Baloo, KWallet, Breeze, NetworkManager-Qt, etc. |
| `kde-applications`  | Dolphin, Kate, Kdenlive, KTorrent, Okular, Ark, KDevelop, etc.   |
| `kde-pim`           | Akonadi stack (calendar, contacts, search, MIME)                 |
| `gnome-stack`       | Nautilus, GNOME Tweaks, Adwaita icons (for GTK app compatibility) |
| `network-web`       | Firefox Nightly, Mullvad Browser, Tor Browser, ProtonVPN, megatools |
| `office`            | LibreOffice (Qt/fresh), Notes, Standard Notes                    |
| `utilities`         | Wezterm, fuzzel, rofi, quickemu, p7zip, conky                    |
| `theming-compat`    | adwaita-qt6, Kvantum, qt6ct, Materia KDE, comixcursors           |
| `custom`            | All local package derivations (see below)                        |

---

## Custom Packages (`packages/`)

Local derivations for software not in nixpkgs or requiring customization.
Integrated via `pkgs.callPackage` in `packages.nix`.

| Package                | Notes                                              |
|------------------------|----------------------------------------------------|
| `firefox-nightly`      | Via nixpkgs-mozilla overlay                        |
| `firefox-stable`       | Custom wrapper/module                              |
| `gemini-cli`           | Google Gemini CLI with wrapper                     |
| `gemini-nix-assistant` | Nix-aware Gemini assistant tool                    |
| `gh-clone`             | GitHub repository clone helper                     |
| `gimp`                 | GIMP module                                        |
| `gimp-devel`           | GIMP development build with wrapper                |
| `jetbrains`            | PhpStorm overlay with OpenGL/font fixes            |
| `kde-darkly`           | Darkly KDE window decoration theme                 |
| `kde-klassy`           | Klassy KDE window decoration theme                 |
| `ladybird`             | Ladybird browser build                             |
| `libquotient`          | libQuotient with upstream patch applied            |
| `ly`                   | Ly display manager                                 |
| `mkvtoolnix`           | MKVToolNix (inline callPackage in packages.nix)    |
| `nyxt-custom`          | Nyxt browser with customizations                   |
| `open-webui`           | Open WebUI (used by ai.nix service)                |
| `php`                  | PHP + Apache httpd stack                           |
| `standardnotes`        | Standard Notes desktop app                         |
| `strawberry-master`    | Strawberry music player (git master build)         |
| `vaapi`                | Custom VAAPI driver/wrapper                        |
| `vivaldi-snapshot`     | Vivaldi snapshot browser build                     |
| `wavebox-beta`         | Wavebox Beta browser/workspace app                 |

---

## Workshop (`workshop/`)

In-development KDE applications built locally.

| Project          | Description                                             |
|------------------|---------------------------------------------------------|
| `plasma-dock/`   | Custom KDE Wayland dock using wlr-layer-shell           |
| `kde-dev-shell.nix` | Nix shell environment for KDE/Qt development        |

---

## Overlays (`overlays/`)

| Overlay                    | Purpose                                          |
|----------------------------|--------------------------------------------------|
| `nixpkgs-mozilla/`         | Mozilla overlay providing `firefox-nightly`      |
| `default.nix`              | Top-level overlay aggregator                     |

Additional inline overlays in `nixpkgs.nix`: PhpStorm (OpenGL/font deps),
libQuotient (upstream patch).

---

## Key Conventions

- **No flakes** — traditional NixOS module system with channel-based nixpkgs only.
- **Plain Nix values** — `desktop/theme.nix` (color palette) and `identity.nix` (user
  identity) are imported with `import`, not as modules.
- **File endings** — all `.nix` files close with a `# <> #` comment marker.
- **Unfree packages** — managed via `allowUnfreePredicate` in `nixpkgs.nix`; covers
  NVIDIA drivers, Steam, and Vulkan components.
- **Custom packages** — collected into a `customPkgs` attrset in `packages.nix` and
  included via `builtins.attrValues customPkgs`; some packages (firefox-stable, gimp)
  are imported as full NixOS modules instead.
