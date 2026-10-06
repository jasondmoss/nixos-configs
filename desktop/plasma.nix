{ lib, pkgs, ... }: {
    imports = [
        # Panel icons switch light/dark with the wallpaper (services.panel-contrast).
        ../packages/panel-contrast
    ];

    qt.enable = true;
    qt.platformTheme = "kde";

    services = {
        displayManager = {
            enable = true;

            sddm = {
                enable = true;

                wayland = {
                    enable = true;
                    compositor = "kwin";
                };

                theme = "Perseverance";

                extraPackages = with pkgs.kdePackages; [
                    plasma-workspace
                    qt5compat
                ];

                enableHidpi = true;
                autoNumlock = false;

                settings = {
                    Theme = {
                        CursorTheme = "ComixCursors";
                        Font = "Noto Sans,10,-1,0,50,0,0,0,0,0";
                    };

                    Users = {
                        DefaultPath = "/run/current-system/sw/bin";

                        RememberLastUser = true;
                        RememberLastSession = true;
                    };
                };
            };

            #ly = {
            #    enable = true;
            #    package = pkgs.callPackage ../packages/ly {};
            #    x11Support = false;
            #
            #    settings = {
            #        clear_password = true;
            #        clock = "%c";
            #
            #        #animation = "dur_file";
            #        #dur_file_path = "${../packages/ly/animations/blackhole-smooth-240x67.dur}";
            #        #dur_offset_alignment = "center";
            #
            #        #animation = "matrix";
            #        #animation = "colormix";
            #        #animation = "doom";
            #        #animation = "gameoflife";
            #        #animation_timeout_sec = "20";
            #        #full_color = true;
            #        input_len = "64";
            #        waylandsessions = "${pkgs.kdePackages.plasma-workspace.sessions}/share/wayland-sessions";
            #    };
            #};

            defaultSession = "plasma";
        };

        desktopManager.plasma6 = {
           enable = true;
           enableQt5Integration = false;
        };

        orca.enable = false;
        speechd.enable = false;
    };

    xdg.portal = {
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

    system.userActivationScripts.rebuildKdeSycoca = ''
${pkgs.kdePackages.kservice}/bin/kbuildsycoca6 --noincremental
    '';

    # Plasma 6 & Qt session variables.
    environment.sessionVariables = {
        KDE_SESSION_VERSION = "6";
        QT_QPA_PLATFORM = "wayland;xcb";
        QT_QUICK_BACKEND = "rhi";
        PLASMA_USE_QT_SCENE_GRAPH_BACKEND = "opengl";
        QT_LOGGING_RULES = "kf.iconthemes.warning=false";
    };
}

# <> #
