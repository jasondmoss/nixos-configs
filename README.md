# NixOS Configurations

NixOS unstable desktop configuration for **atreides** — an AMD Ryzen 9 3900X workstation
with an NVIDIA RTX 5060 Ti (Blackwell), 32 GiB RAM, running KDE Plasma 6 on Wayland.

This is a **traditional NixOS module system** configuration — no flakes, channel-based
nixpkgs only. The entry point is `configuration.nix`.

Secrets never enter this repository: `identity.nix` (e-mail addresses) is gitignored and
templated by `identity.nix.example`; the Wi-Fi SSID and PSK (`/var/lib/nm-secrets/wifi.env`,
substituted into the NetworkManager profile at activation), the WireGuard private key and
Grafana's secret key live under `/var/lib` and `/etc` on the machine only.

---

## System Profile

| Component       | Details                                      |
|-----------------|----------------------------------------------|
| CPU             | AMD Ryzen 9 3900X                            |
| GPU             | NVIDIA RTX 5060 Ti (Blackwell, open module)  |
| RAM             | 32 GiB (+ 8 GiB zstd zram swap)              |
| Kernel          | Linux (xanmod-latest)                        |
| Bootloader      | systemd-boot (EFI)                           |
| Display server  | Wayland                                      |
| Desktop         | KDE Plasma 6                                 |
| Display manager | SDDM (kwin_wayland greeter, local theme)     |
| Audio           | PipeWire (ALSA + PulseAudio + JACK)          |
| NixOS channel   | nixos-unstable                               |

---

## Filesystems

| Mount point           | Device      | FS    | Notes                          |
|-----------------------|-------------|-------|--------------------------------|
| `/`                   | nvme0n1p2   | ext4  | Root (NVMe)                    |
| `/home`               | nvme1n1p1   | Btrfs | zstd:1, noatime, monthly scrub |
| `~/Repository`        | sdb1        | Btrfs | zstd:1, noatime, monthly scrub |
| `~/Mega`              | sdb2        | ext4  | MEGAsync storage               |
| `~/Music`             | sdc1        | ext4  | Music library                  |
| `~/Videos/Movies`     | sda1        | ext4  | Movie library                  |
| `~/Videos/Television` | sdd         | ext4  | TV library                     |
| `/boot/efi`           | vfat        | vfat  | EFI partition                  |
| (zram0)               | —           | —     | 8 GiB compressed, priority 100 |
| (swapfile)            | /swapfile   | —     | 16 GiB, priority -1            |

---

## Module Structure

### Hardware (`hardware/`)

| File              | Purpose                                                              |
|-------------------|----------------------------------------------------------------------|
| `boot.nix`        | xanmod kernel, systemd initrd, systemd-boot, filesystems, swap + zram, btrfs scrub, kernel sysctl hardening |
| `gpu.nix`         | NVIDIA **open** kernel module (bleeding-edge driver), VAAPI, DRM modesetting, `<nixos-hardware>` blackwell profile |
| `peripherals.nix` | Bluetooth, QMK keyboard firmware, printing, SMART monitoring, udev  |
| `power.nix`       | AMD microcode, `amd_pstate=active`, static `performance` governor (TLP/power-profiles-daemon disabled) |

**Kernel params:** `amd_iommu=on`, `amd_pstate=active`, `nvidia-drm.modeset=1`, `nvidia-drm.fbdev=1`, `pcie_aspm=off`. nouveau and `i2c-nvidia_gpu` are blacklisted.

**Kernel hardening:** `kptr_restrict=2`, `unprivileged_bpf_disabled=1`, `bpf_jit_harden=2`, `yama.ptrace_scope=1`, no ICMP redirects, `tcp_rfc1337=1`, `ldisc_autoload=0`, `security.protectKernelImage` (no kexec).

---

### Desktop (`desktop/`)

| File         | Purpose                                                                     |
|--------------|-----------------------------------------------------------------------------|
| `plasma.nix` | KDE Plasma 6, SDDM (Wayland greeter, local *Perseverance* theme; Ly kept commented out), XDG portals, Wayland/Qt session vars |
| `fonts.nix`  | Font packages and fontconfig rules                                          |
| `theme.nix`  | 16-color terminal palette (plain Nix value, imported by `configuration.nix`) |

**Plasma 6** is configured Qt 6 only (`enableQt5Integration = false`), RHI rendering
backend, XDG portal delegation for KDE/GTK. No input-method framework (US layout via KWin).

---

### System

| File                  | Purpose                                                              |
|-----------------------|----------------------------------------------------------------------|
| `nixpkgs.nix`         | Host platform, `allowUnfree`, overlays (Firefox Nightly, PhpStorm, Chrome Vulkan-disable, Steam `libgdiplus`) |
| `identity.nix`        | E-mail addresses only — plain Nix value, not a module, **not committed** |
| `networking.nix`      | iptables firewall (nothing open to the world; SSH from the LAN only), NetworkManager + OpenVPN, CoreDNS on loopback with DNS-over-TLS, OpenSSH (key-only, root disabled) |
| `security.nix`        | PAM (KWallet, ssh-agent auth), polkit, sudo (`execWheelOnly`), `protectKernelImage`, fail2ban |
| `users.nix`           | User account and group memberships                                    |
| `environment.nix`     | Session/env vars, XDG base dirs, GStreamer paths, per-host git configs, 1Password browser allowlist, telemetry opt-outs |
| `programs.nix`        | git (LFS, conditional identity includes), neovim, SSH agent, GnuPG, 1Password, Steam, direnv, KDE Connect, nix-index |
| `packages.nix`        | Central package manifest, organized by category (see below)           |
| `services.nix`        | PipeWire, earlyoom, plocate, fwupd, journald cap, systemd user units (megasync, ssh-key-pollen), weekly prebuilt nix-index database fetch |
| `qbittorrent-vpn.nix` | qBittorrent confined to a WireGuard/ProtonVPN network namespace — a kill switch by construction |
| `pcp.nix`             | Performance Co-Pilot (pmcd/pmlogger/pmie/pmproxy) — always-on metrics with replayable archives, loopback only |
| `pcp-grafana.nix`     | Grafana + Redis/pmseries front-end for PCP, loopback only             |

**Networking:** CoreDNS on `127.0.0.1` is the system resolver, forwarding over **DNS-over-TLS**
to Cloudflare. A `local` zone resolves `*.local` to `127.0.0.1`. The firewall opens nothing
globally: SSH (22) is admitted from the LAN subnet only, KDE Connect (1714–1764) and Steam
Remote Play open their own ports through their program modules. `nftables.enable = false`
is intentional: Docker relies on iptables for NAT.

**qBittorrent VPN kill switch:** qBittorrent runs inside a dedicated network namespace
(`qbit`) whose only route out is a WireGuard tunnel (config at `/etc/wireguard/qbit.conf`,
root-only, never in the nix store or git). If the tunnel drops, qBittorrent simply loses
network. The passwordless sudo rule for entering the namespace requires `runuser -u me`, so
it cannot yield a root shell.

**Nix store:** auto-optimise enabled, GC runs weekly (deletes generations older than
14 days), `experimental-features = nix-command` only (no flakes).

---

### Development (`development.nix`)

Docker (overlay2 storage driver, unpinned `pkgs.docker`) with weekly auto-prune,
docker-compose, docker-buildx. DDEV handles PHP/Drupal dev work.

---

### AI (`ai.nix`, `ai-home.nix`)

Everything below is **local and loopback-only**. Nothing about the user or the home
directory is sent to any cloud model.

| Component       | Details                                                                     |
|-----------------|-----------------------------------------------------------------------------|
| Ollama          | CUDA, models on the /home NVMe, `127.0.0.1:11434`. Flash attention, q8 K/V cache, 32k context, cloud features disabled (`OLLAMA_NO_CLOUD`) |
| Open WebUI      | Private chat/RAG UI over Ollama, `127.0.0.1:8180`, no login, RAG embeddings via Ollama, image generation via ComfyUI, telemetry/update checks off |
| ComfyUI         | Image generation/editing (CUDA torch), `127.0.0.1:8188`, models bind-mounted read-only from `~/Repository/ai/comfyui/models` |
| Voice           | `whisper-cpp-vulkan` (GPU transcription) + `piper-tts`, driven by the `talk` script |
| Agents          | `opencode` (local models via Ollama), `goose-cli`; `claude-code` for cloud-assisted coding |
| **ai-home**     | Sandboxed, read-only view of `/home/me` for local models via MCP (`127.0.0.1:8300`): filesystem tools, Recoll full-text search, meaning-based search (Ollama `nomic-embed-text` embeddings of the document folders in an in-process sqlite-vec store), git, document-to-Markdown. Hidden paths are enforced by systemd `InaccessiblePaths` and never indexed; the units have no network egress. Edit `services.ai-home.hiddenPaths` to change what the AI can see |
| **krunner-ollama** | KRunner runner: `ai <question>` (or `? <question>`) shows the first line of the local model's answer as a match; Enter copies the full answer to the clipboard, the action button opens the question in Open WebUI (`/?q=…`). `services.krunner-ollama.*` — module + package in `packages/krunner-ollama`; hardened systemd user unit whose only network client is pinned to the loopback Ollama URL |

Firefox's AI chatbot sidebar is pointed at the local Open WebUI in both installed Firefoxes
(`programs.firefox` and the Nightly wrapper).

---

## Package Categories (`packages.nix`)

Packages are organized into named category lists, flattened into
`environment.systemPackages` at build time.

| Category              | Contents                                                          |
|-----------------------|-------------------------------------------------------------------|
| `nixos`               | fastfetch, nixos-icons, nixos-rebuild-ng, nix-prefetch-github, nh |
| `system-tools`        | btrfs-progs, htop, lsd, inxi, pciutils, smartmontools, dysk, etc. |
| `graphics-multimedia` | FFmpeg, mpv, Inkscape, Audacity, Shotcut, GStreamer plugins, MKVToolNix |
| `development`         | GCC, Rust/Cargo, Node.js, CMake, Qt/KDE dev tools, PhpStorm, Valgrind, PHP QA tools, Android tools |
| `kde-plasma-core`     | Plasma workspace, Baloo, KWallet, Breeze, NetworkManager-Qt, layer-shell-qt, etc. |
| `kde-applications`    | Dolphin, Kate, Kdenlive, Okular, Ark, KDevelop, etc.              |
| `kde-pim`             | Akonadi stack (calendar, contacts, search, MIME)                  |
| `gnome-stack`         | Nautilus, GNOME Tweaks, Adwaita icons (for GTK app compatibility) |
| `network-web`         | Firefox Nightly (overlay wrapper), Chrome, Edge, Mullvad Browser, Tor Browser, ProtonVPN, WireGuard tools (plain Firefox comes from `programs.firefox`) |
| `office`              | LibreOffice (Qt)                                                  |
| `utilities`           | Wezterm, fuzzel, pandoc, quickemu, p7zip, rar, tectonic           |
| `theming-compat`      | adwaita-qt6, Kvantum, qt6ct, Materia KDE, comixcursors            |
| `custom`              | All local package derivations (see below)                         |

KDE excluded packages: `elisa`, `itinerary`. GNOME excluded packages: decibels, geary,
gnome-calculator, gnome-calendar, gnome-console, gnome-contacts, gnome-maps, gnome-music,
gnome-tour, gnome-weather.

---

## Custom Packages (`packages/`)

Local derivations for software not in nixpkgs or requiring customization. Most pin their
version + checksum in a `manifest.json` refreshed by a sibling `update.sh`.

**`customPkgs` attrset** (via `pkgs.callPackage` in `packages.nix`): `antigravity-cli`,
`claude-desktop`, `gh-clone`, `jopdf`, `kde-darkly`, `kde-klassy`, `kde-vinyl`, `krema`,
`nyxt-custom`, `proton-drive-cli`, `sddm-perseverance`, `stage-manager`, `standardnotes`,
`strawberry-master`, `system-panel`, `vivaldi-snapshot`, `wavebox-beta`.

**Module imports:** `gimp` (+ `gimp-devel`), `claude-code-browser`,
`gps-signature`, `vaapi` (from `hardware/gpu.nix`), `pcp` (via `pcp.nix`), `grafana-pcp`
(via `pcp-grafana.nix`), `ai-home` (full-text and semantic search server scripts, via `ai-home.nix`),
`krunner-ollama` (KRunner runner module + package, via `ai.nix`).

**Inline `callPackage`:** `claude-code` (`ai.nix`).

**Overlay-based:** `firefox-nightly` (nixpkgs-mozilla + wrapper in `../overlays/default.nix`),
`jetbrains` (PhpStorm), `google-chrome` (Vulkan disabled), `steam` (`libgdiplus`), `drkonqi`
(GDB preamble patch).

---

## Workshop (`workshop/`)

In-development KDE projects: `stage-manager` (KWin effect), `system-panel` (plasmoid),
`kde-dev-shell.nix` (Nix shell for KDE/Qt development).

---

## Key Conventions

- **No flakes** — traditional NixOS module system with channel-based nixpkgs only.
- **Plain Nix values** — `desktop/theme.nix` and `identity.nix` are imported with `import`,
  not as NixOS modules.
- **`identity.nix` fields** — `emailPersonal`, `emailWork`, `emailOrigin` only. See
  `identity.nix.example`. Never committed.
- **File endings** — all `.nix` files close with a `# <> #` comment marker.
- **Adding a package** — add it to the appropriate category list in `packages.nix`. For a
  new custom derivation, add a `pkgs.callPackage ./packages/<name> {}` entry to `customPkgs`.
- **Unfree packages** — `allowUnfree = true` globally.
