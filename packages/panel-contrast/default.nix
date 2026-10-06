{ config, lib, pkgs, ... }:

#-- panel-contrast — Plasma panel icons that follow the wallpaper.
#--
#-- The Plasma Style (Perseverance) fixes panel text and symbolic icons at a
#-- light grey, which washes out over light wallpapers. Panel Colorizer (a
#-- panel widget, nixpkgs `plasma-panel-colorizer`) can override that colour
#-- per panel and loads presets on request over D-Bus; the `panel-contrast`
#-- user unit samples the wallpaper region behind the panel — the same
#-- luminance test system-panel's Auto text colour uses — and asks it for the
#-- light-icons or dark-icons preset; symbolic icons and text follow it.
#--
#-- Full-colour app tray icons are made monochrome too, through two Panel
#-- Colorizer widget settings the watcher writes (`trayIcons`,
#-- `maskTrayItems` below): the icon is swapped for a cut-out SVG from
#-- ./icons (the app's own symbol becomes a hole in a solid shape) and then
#-- drawn as a mask in the preset's colour. Icons that already are a glyph on
#-- transparency (Claude) only need the mask. Trade-off: a swapped icon is
#-- static, so app-driven icon changes (MEGA's syncing/paused/warning states,
#-- unread badges) no longer show. Only StatusNotifierItem apps can be
#-- swapped; Plasma's own tray widgets (KDE Connect) cannot — the theme's
#-- full-colour `kdeconnect` icon stays as it is.
#--
#-- Other panel widgets that assumed light text get adjusted the same way
#-- (`widgetSettings`): the System Monitor rings switch to the "Pie Chart
#-- (contrast)" face from ./sensorface.nix, whose value glow and ring track
#-- follow the text colour, and the weather widget's dark temperature halo
#-- is turned off — the text colour itself now adapts.
#--
#-- Triggers: Plasma rewriting plasma-org.kde.plasma.desktop-appletsrc (a
#-- wallpaper change lands there a few seconds later), an activity switch,
#-- and a Panel Colorizer instance appearing on the bus (login, plasmashell
#-- restart). No polling.
#--
#-- One-time setup after the switch: add "Panel Colorizer" to the panel
#-- (right-click it → "Hide widget" keeps it out of sight; it stays visible in
#-- Edit Mode). Leave its D-Bus service option on (the default).
#--
#-- Checking: `panel-contrast --dry-run` prints the sampled luminance and the
#-- preset it would pick; `journalctl --user -u panel-contrast` logs each
#-- switch. The presets live in the store (`light-icons/`, `dark-icons/`) and
#-- are rewritten from the colours below, so edits made in Panel Colorizer's
#-- settings window last only until the next switch.

with lib;

let
    cfg = config.services.panel-contrast;

    #-- nixpkgs (8.0.0, also nixpkgs-unstable as of 2026-10-06) marks only
    #-- service.py and list_presets.sh executable. The widget runs
    #-- tools/gdbus_get_signal.sh directly to hear the D-Bus service's
    #-- preset_changed/property_changed signals; read-only, it fails with 126
    #-- and the widget never retries — presets reached the service (its
    #-- `preset s ''` echoed them) but never the panel.
    colorizer = pkgs.plasma-panel-colorizer.overrideAttrs (old: {
        postInstall = (old.postInstall or "") + ''
            chmod 755 $out/share/plasma/plasmoids/luisbocanegra.panel.colorizer/contents/ui/tools/gdbus_get_signal.sh
        '';
    });

    sensorface = pkgs.callPackage ./sensorface.nix { };

    #-- systemd expands %-specifiers in Environment= values.
    escapeSpecifiers = replaceStrings [ "%" ] [ "%%" ];
in {
    options.services.panel-contrast = {
        enable = mkOption {
            type = types.bool;
            default = true;
            description = "Switch Plasma panel icon colour with the wallpaper behind the panel.";
        };

        package = mkOption {
            type = types.package;
            default = pkgs.callPackage ./package.nix {
                inherit (cfg) lightColor darkColor trayIcons maskTrayItems widgetSettings;
            };
            defaultText = literalExpression "pkgs.callPackage ./package.nix { ... }";
            description = "The panel-contrast watcher, carrying both Panel Colorizer presets.";
        };

        lightColor = mkOption {
            type = types.strMatching "#[0-9a-fA-F]{6}";
            default = "#ffffff";
            description = "Icon and text colour over dark wallpapers (matches system-panel's white).";
        };

        darkColor = mkOption {
            type = types.strMatching "#[0-9a-fA-F]{6}";
            default = "#000000";
            description = "Icon and text colour over light wallpapers (matches system-panel's black).";
        };

        trayIcons = mkOption {
            type = types.listOf (types.submodule {
                options = {
                    description = mkOption {
                        type = types.str;
                        description = "Label shown in Panel Colorizer's tray icon replacement list.";
                    };
                    match = mkOption {
                        type = types.str;
                        description = ''
                            JavaScript regex tested against the tray item's title and its
                            StatusNotifierItem id (`busctl --user get-property <service>
                            /StatusNotifierItem org.kde.StatusNotifierItem Id`).
                        '';
                    };
                    icon = mkOption {
                        type = types.either types.path types.str;
                        description = "Replacement icon: a file (copied to the store) or an icon-theme name.";
                    };
                };
            });
            default = [
                { description = "MEGAsync";       match = "^MEGAsync$";                      icon = ./icons/megasync.svg; }
                { description = "1Password";      match = "^1Password_status_icon_";         icon = ./icons/1password.svg; }
                { description = "Standard Notes"; match = "^Standard Notes_status_icon_";    icon = ./icons/standard-notes.svg; }
                #-- Wavebox registers as chrome_status_icon_N like every
                #-- Chromium app; its tooltip title tells it apart.
                { description = "Wavebox";        match = "^Wavebox$";                       icon = ./icons/wavebox.svg; }
            ];
            description = "Tray icons swapped for monochrome replacements (list them in `maskTrayItems` too).";
        };

        maskTrayItems = mkOption {
            type = types.listOf types.str;
            default = [
                "MEGAsync"
                "1Password_status_icon_1"
                "Standard Notes_status_icon_1"
                "chrome_status_icon_1@wavebox"
                "Claude_status_icon_1"
            ];
            description = ''
                Tray items drawn as a solid silhouette in the preset's colour, by the
                exact name Panel Colorizer lists for them (its `panelWidgets` config
                key; Electron apps are `<App>_status_icon_<n>`).
            '';
        };

        widgetSettings = mkOption {
            type = types.attrsOf (types.attrsOf (types.attrsOf types.str));
            default = {
                "org.kde.plasma.systemmonitor.cpu".Appearance.chartFace = sensorface.faceId;
                "org.kde.plasma.systemmonitor.memory".Appearance.chartFace = sensorface.faceId;
                "org.kde.plasma.advanced-weather-widget".General.panelSimpleTempShadowEnabled = "false";
            };
            description = ''
                Config values written into panel widgets, as plugin id → config group
                (below `[Configuration]`, `/`-separated) → key → value. Applied to
                every widget of that plugin in any panel before each preset delivery;
                only differing values are written. Panel Colorizer's own tray
                settings are added from `trayIcons` and `maskTrayItems`.
            '';
        };

        threshold = mkOption {
            type = types.numbers.between 0 1;
            default = 0.5;
            description = "Mean luminance of the sampled region below which the light icons are used.";
        };

        region = mkOption {
            type = types.str;
            default = "2%x40%+0+0";
            description = ''
                ImageMagick crop geometry of the area behind the panel, relative to
                `gravity`, on the wallpaper fitted to `screenSize`. The default
                covers the right-edge panel (32 px thick plus the floating gap) from
                the top down to the end of the system tray.
            '';
        };

        gravity = mkOption {
            type = types.enum [ "NorthWest" "North" "NorthEast" "West" "Center" "East" "SouthWest" "South" "SouthEast" ];
            default = "NorthEast";
            description = "Screen corner or edge the `region` offsets are measured from.";
        };

        screen = mkOption {
            type = types.ints.unsigned;
            default = 0;
            description = "Plasma screen number of the panel; selects whose wallpaper is sampled.";
        };

        screenSize = mkOption {
            type = types.strMatching "[0-9]+x[0-9]+";
            default = "3840x2160";
            description = ''
                Resolution of that screen. Wallpapers are fitted to it the way
                Plasma's default "Scaled and Cropped" mode does before sampling.
            '';
        };
    };

    config = mkIf cfg.enable {
        environment.systemPackages = [
            colorizer
            sensorface
            cfg.package
        ];

        #-- Plasma-only: hangs off plasma-workspace.target, which only
        #-- startplasma starts, so the Hyprland session never runs it.
        systemd.user.services.panel-contrast = {
            description = "Match Plasma panel icon colour to the wallpaper";
            wantedBy = [ "plasma-workspace.target" ];
            after = [ "plasma-plasmashell.service" ];
            partOf = [ "graphical-session.target" ];

            environment = {
                PANEL_CONTRAST_THRESHOLD = toString cfg.threshold;
                PANEL_CONTRAST_REGION = escapeSpecifiers cfg.region;
                PANEL_CONTRAST_GRAVITY = cfg.gravity;
                PANEL_CONTRAST_SCREEN = toString cfg.screen;
                PANEL_CONTRAST_SCREEN_SIZE = cfg.screenSize;
            };

            serviceConfig = {
                ExecStart = getExe cfg.package;
                Restart = "always";
                RestartSec = 5;
            };
        };
    };
}

# <> #
