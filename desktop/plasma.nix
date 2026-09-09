{ lib, pkgs, ... }: {
    qt.enable = true;
    qt.platformTheme = "kde";

    services = {
        displayManager = {
            enable = true;

            ly = {
                enable = true;
                package = pkgs.callPackage ../packages/ly {};
                x11Support = false;

                settings = {
                    clear_password = true;
                    clock = "%c";

                    #animation = "dur_file";
                    #dur_file_path = "${../packages/ly/animations/blackhole-smooth-240x67.dur}";
                    #dur_offset_alignment = "center";

                    #animation = "matrix";
                    #animation = "colormix";
                    #animation = "doom";
                    #animation = "gameoflife";
                    #animation_timeout_sec = "20";
                    #full_color = true;
                    input_len = "64";
                    waylandsessions = "${pkgs.kdePackages.plasma-workspace.sessions}/share/wayland-sessions";
                };
            };

            defaultSession = "plasma";
        };

        desktopManager.plasma6 = {
           enable = true;
           enableQt5Integration = false;
        };

        # No screen reader. The plasma6 module defaults services.orca.enable to
        # true and graphical-desktop.nix defaults speechd on; kaccess then
        # launches Orca at login whenever kaccessrc [ScreenReader] Enabled=true,
        # and KWin routes every key through the a11y keyboard monitor. That
        # desynced on focus changes (2026-09-07..09) and swallowed typed input in
        # all apps. Disabling both also turns off at-spi2-core (NO_AT_BRIDGE=1).
        orca.enable = false;
        speechd.enable = false;
    };

    # XDG portals and MIME defaults.
    xdg = {
        mime.defaultApplications = {
            "text/html" = "firefox.desktop";
            "x-scheme-handler/http" = "firefox.desktop";
            "x-scheme-handler/https" = "firefox.desktop";
            "x-scheme-handler/about" = "firefox.desktop";
            "x-scheme-handler/unknown" = "firefox.desktop";
        };

        portal = {
            enable = true;
            xdgOpenUsePortal = true;
            config = {
                kde.default = [ "kde" "gtk" "gnome" ];
                kde."org.freedesktop.portal.FileChooser" = [ "kde" ];
                kde."org.freedesktop.portal.OpenURI" = [ "kde" ];
            };
            extraPortals = with pkgs; [
                xdg-desktop-portal
                xdg-desktop-portal-termfilechooser
                kdePackages.xdg-desktop-portal-kde
            ];
        };
    };

    # xdg-desktop-portal can be dbus-activated in the logout/login gap, before
    # Plasma re-imports DISPLAY/WAYLAND_DISPLAY into the systemd user manager.
    # It then holds a display-less environment and every OpenURI launch (link
    # clicks -> browser) dies with "no DISPLAY environment variable specified".
    # Hold the start until the session environment has landed; give up after
    # 30 s so headless activation still works.
    systemd.user.services.xdg-desktop-portal = {
        path = lib.mkForce [];

        serviceConfig.ExecStartPre = pkgs.writeShellScript "wait-for-session-env" ''
tries=0
until ${pkgs.systemd}/bin/systemctl --user show-environment | ${pkgs.gnugrep}/bin/grep -q '^WAYLAND_DISPLAY='; do
    tries=$((tries + 1))
    if [ "$tries" -ge 60 ]; then
        break
    fi
    ${pkgs.coreutils}/bin/sleep 0.5
done
exit 0
        '';
    };

    # Rebuild KDE sycoca on every nixos-rebuild switch so the app launcher
    # picks up newly installed/removed .desktop files immediately.
    system.userActivationScripts.rebuildKdeSycoca = ''
${pkgs.kdePackages.kservice}/bin/kbuildsycoca6 --noincremental
    '';

    # Plasma 6 & Qt session variables.
    environment.sessionVariables = {
        KDE_SESSION_VERSION = "6";
        QT_QPA_PLATFORM = "wayland;xcb";
        # Transition from 'software' to 'rhi' (Render Hardware Interface).
        QT_QUICK_BACKEND = "rhi";
        PLASMA_USE_QT_SCENE_GRAPH_BACKEND = "opengl";
        # Silence the harmless KF icon-theme fallback warning emitted by Qt/KF
        # helpers such as ksshaskpass (e.g. "kf.iconthemes: Icon theme
        # \"gnome\" not found." during git/ssh over SSH).
        QT_LOGGING_RULES = "kf.iconthemes.warning=false";
    };
}

# <> #
