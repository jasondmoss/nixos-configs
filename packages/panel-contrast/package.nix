{
    lib,
    writeShellApplication,
    writeText,
    writeTextDir,
    symlinkJoin,
    coreutils,
    dbus,
    findutils,
    gawk,
    gnused,
    imagemagick,
    inotify-tools,
    systemd,
    lightColor ? "#ffffff",
    darkColor ? "#000000",
    trayIcons ? [ ],
    maskTrayItems ? [ ],
    widgetSettings ? { },
}:

let
    #-- A Panel Colorizer preset that sets only the foreground colour of panel
    #-- widgets and system-tray items. Panel Colorizer merges a loaded preset
    #-- over its defaults, so everything else keeps the stock panel look.
    preset = name: color: writeTextDir "${name}/settings.json" (builtins.toJSON {
        globalSettings = let
            normal = {
                enabled = true;
                foregroundColor = {
                    enabled = true;
                    sourceType = 0;  # Custom
                    custom = color;
                    alpha = 1;
                };
            };
        in {
            widgets.normal = normal;
            trayWidgets.normal = normal;
        };
    });

    presets = symlinkJoin {
        name = "panel-contrast-presets";
        paths = [
            (preset "light-icons" lightColor)
            (preset "dark-icons" darkColor)
        ];
    };

    #-- Panel Colorizer widget settings that presets cannot carry (both keys
    #-- are on its preset ignore list), so they are written into the widget's
    #-- own config instead. They only say *how* tray icons are drawn — swap
    #-- these icons, draw those as masks — while the colour still comes from
    #-- whichever preset is loaded.
    #--   systemTrayIconUserReplacements: regex on the tray item's title or
    #--     StatusNotifierItem id → replacement icon (name or file path).
    #--   forceForegroundColor: items whose icons are redrawn as a solid
    #--     silhouette in the foreground colour (holes in the icon stay holes).
    #--     Tray items always carry id -1; `name` is the id Panel Colorizer
    #--     lists for them (its panelWidgets config key).
    colorizerSettings = {
        systemTrayIconsReplacementEnabled = if trayIcons != [ ] then "true" else "false";
        systemTrayIconUserReplacements = builtins.toJSON (map (rule: {
            inherit (rule) description match;
            icon = "${rule.icon}";
            enabled = true;
        }) trayIcons);
        forceForegroundColor = builtins.toJSON {
            widgets = map (name: {
                inherit name;
                id = -1;
                method = { mask = true; multiEffect = false; };
                reload = false;
            }) maskTrayItems;
            reloadInterval = 250;
        };
    };

    #-- plugin → config group → key → value, for every widget of that plugin
    #-- in any panel.
    allWidgetSettings = lib.recursiveUpdate widgetSettings {
        "luisbocanegra.panel.colorizer".General = colorizerSettings;
    };

    #-- Plasma script (org.kde.PlasmaShell.evaluateScript) that writes those
    #-- settings, touching and reloading a widget only when a value differs.
    widgetScript = writeText "panel-contrast-widget-settings.js" ''
        var desired = ${builtins.toJSON allWidgetSettings};
        var report = [];
        panels().forEach(function (panel) {
            for (var plugin in desired) {
                panel.widgets(plugin).forEach(function (widget) {
                    var changed = false;
                    for (var group in desired[plugin]) {
                        widget.currentConfigGroup = group.split("/");
                        for (var key in desired[plugin][group]) {
                            var value = desired[plugin][group][key];
                            if (String(widget.readConfig(key, "")) !== value) {
                                widget.writeConfig(key, value);
                                changed = true;
                            }
                        }
                    }
                    if (changed) {
                        widget.reloadConfig();
                    }
                    report.push(plugin + " " + panel.id + "/" + widget.id + (changed ? " updated" : " unchanged"));
                });
            }
        });
        print(report.join(", "));
    '';
in

writeShellApplication {
    name = "panel-contrast";

    runtimeInputs = [
        coreutils
        dbus           # dbus-monitor
        findutils
        gawk
        gnused
        imagemagick
        inotify-tools
        systemd        # busctl
    ];

    runtimeEnv = {
        PANEL_CONTRAST_PRESETS = presets;
        PANEL_CONTRAST_WIDGET_SCRIPT = widgetScript;
    };

    text = builtins.readFile ./panel-contrast.sh;

    passthru = { inherit presets widgetScript; };

    meta = {
        description = "Switch Panel Colorizer between light and dark panel icons to match the wallpaper behind the panel";
        license = lib.licenses.gpl2Plus;
        platforms = lib.platforms.linux;
        mainProgram = "panel-contrast";
    };
}

# <> #
