# hyprland.nix
#
# Hyprland as a second, opt-in session next to Plasma — pick
# "Hyprland (uwsm-managed)" in SDDM's session menu, log out and pick
# "Plasma (Wayland)" to go back. Nothing here removes or reconfigures
# Plasma: every Plasma unit hangs off plasma-workspace.target, which only
# startplasma starts, and every XDG autostart entry Plasma relies on carries
# OnlyShowIn=KDE, so neither side leaks into the other. Remove this import
# from configuration.nix to drop the experiment entirely.
#
# UWSM runs the session: it starts graphical-session.target (ssh-key-pollen,
# megasync, krunner-ollama, gps-signature) and xdg-desktop-autostart.target
# (KDE Connect, pam_kwallet_init, gnome-keyring, ~/.config/autostart), which
# Hyprland 0.56 does not do on its own.
#
# Dotfiles (hyprland.lua, waybar, rofi, mako, hyprlock, hyprpaper) are not
# managed here; they live in ~/Mega/System/Configurations/<app>, symlinked
# into ~/.config like ghostty/wezterm. Hyprland 0.55+ reads hyprland.lua and
# only falls back to the deprecated hyprland.conf.
{ pkgs, ... }:

let
    # mako's share/ carries a D-Bus activation file for
    # org.freedesktop.Notifications (SystemdService=mako.service) plus that
    # user unit. The user manager also searches
    # /run/current-system/sw/share/systemd/user, so with the full package
    # installed an early notification during Plasma login could start mako
    # and take the bus name from plasmashell. Expose only the binaries and
    # man pages; hyprland.lua starts mako itself.
    makoBin = pkgs.runCommand "mako-bin-${pkgs.mako.version}" {} ''
        mkdir -p $out/share
        cp -rs ${pkgs.mako}/bin $out/bin
        cp -rs ${pkgs.mako}/share/man $out/share/man
    '';
in {
    programs.hyprland = {
        enable = true;
        withUWSM = true;
    };

    # hyprlock by hand rather than programs.hyprlock: that module also forces
    # services.hypridle on, whose unit is WantedBy=graphical-session.target —
    # which Plasma starts too, so it would run (and, with no hypridle.conf,
    # crash-loop) in both sessions. The lock is manual (Super+L), matching
    # Plasma's never-dim/never-lock/never-suspend settings.
    security.pam.services.hyprlock = {};

    # Plasma keeps kde-portals.conf (desktop/plasma.nix); this file is only
    # read when XDG_CURRENT_DESKTOP=Hyprland. Screenshot/ScreenCast/
    # GlobalShortcuts come from the Hyprland backend, everything it lacks
    # (file chooser, Settings → dark-mode/accent for apps) from the KDE one,
    # whose unit is D-Bus activated and not tied to plasma-workspace.target.
    xdg.portal.config.hyprland = {
        default = [ "hyprland" "kde" "gtk" ];
        "org.freedesktop.portal.FileChooser" = [ "kde" ];
    };

    # Sourced by UWSM for Hyprland sessions only (env-<desktop> per XDG config
    # dir, then ~/.config/uwsm/env-hyprland on top) and exported to every unit
    # and app it launches. QT_QPA_PLATFORMTHEME=kde, KDE_SESSION_VERSION and
    # the NVIDIA variables are already session-wide.
    environment.etc."xdg/uwsm/env-hyprland".text = ''
        # KDE apps outside Plasma: without the plasma- menu prefix, kbuildsycoca6
        # finds no applications.menu and Dolphin's "Open With" stays empty.
        export XDG_MENU_PREFIX=plasma-

        # Same cursor as Plasma (kcminputrc), for Hyprland and non-KDE apps.
        export XCURSOR_THEME=breeze_cursors
        export XCURSOR_SIZE=24
    '';

    environment.systemPackages = with pkgs; [
        # Session furniture, started from hyprland.lua.
        hyprlock
        hyprpaper
        makoBin
        nwg-dock-hyprland
        rofi
        waybar

        # hyprland-dialog (ANR prompts) + update screen; Hyprland warns at
        # every start when they are missing. nixpkgs still ships the Qt-era
        # name for what upstream now calls hyprland-guiutils.
        hyprland-qtutils

        # Clipboard history, screenshots (Spectacle needs KWin), colour picker.
        cliphist
        hyprpicker
        hyprshot
        libnotify
        playerctl
        wl-clipboard
    ];

    # Waybar/rofi icon glyphs.
    fonts.packages = [ pkgs.nerd-fonts.symbols-only ];
}

# <> #
