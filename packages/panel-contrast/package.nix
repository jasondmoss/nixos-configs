{
    lib,
    writeShellApplication,
    writeText,
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
    #-- Plasma script (org.kde.PlasmaShell.evaluateScript) that sets the
    #-- foreground colour of panel widgets and tray items in every Panel
    #-- Colorizer widget. The watcher prepends `var color = "#rrggbb";`.
    #--
    #-- It edits only those fields of the widget's globalSettings JSON — the
    #-- `enabled` flags, sourceType 0 (custom), the colour, full alpha — and
    #-- writes only when one differs, so everything set in Panel Colorizer's
    #-- own settings window (transparency, blur, radius, …) stays. Loading a
    #-- preset instead, as this used to, replaces globalSettings wholesale.
    colorScript = writeText "panel-contrast-color.js" ''
        var report = [];
        panels().forEach(function (panel) {
            panel.widgets("luisbocanegra.panel.colorizer").forEach(function (widget) {
                widget.currentConfigGroup = ["General"];
                var raw = String(widget.readConfig("globalSettings", ""));
                var settings = {};
                try {
                    settings = raw ? JSON.parse(raw) : {};
                } catch (e) {
                    report.push(panel.id + "/" + widget.id + " unreadable");
                    return;
                }
                var want = { enabled: true, sourceType: 0, custom: color, alpha: 1 };
                var changed = false;
                ["widgets", "trayWidgets"].forEach(function (scope) {
                    var section = settings[scope] = settings[scope] || {};
                    var normal = section.normal = section.normal || {};
                    var fg = normal.foregroundColor = normal.foregroundColor || {};
                    if (normal.enabled !== true) {
                        normal.enabled = true;
                        changed = true;
                    }
                    for (var key in want) {
                        if (fg[key] !== want[key]) {
                            fg[key] = want[key];
                            changed = true;
                        }
                    }
                });
                if (changed) {
                    widget.writeConfig("globalSettings", JSON.stringify(settings));
                    widget.reloadConfig();
                }
                report.push(panel.id + "/" + widget.id + (changed ? " recoloured" : " unchanged"));
            });
        });
        print(report.join(", "));
    '';

    #-- Panel Colorizer widget settings outside globalSettings (both keys are
    #-- on its preset ignore list), written into the widget's
    #-- own config instead. They only say *how* tray icons are drawn — swap
    #-- these icons, draw those as masks — while the colour comes from
    #-- colorScript.
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
        PANEL_CONTRAST_LIGHT_COLOR = lightColor;
        PANEL_CONTRAST_DARK_COLOR = darkColor;
        PANEL_CONTRAST_COLOR_SCRIPT = colorScript;
        PANEL_CONTRAST_WIDGET_SCRIPT = widgetScript;
    };

    text = builtins.readFile ./panel-contrast.sh;

    passthru = { inherit colorScript widgetScript; };

    meta = {
        description = "Set Panel Colorizer's panel icon colour to light or dark to match the wallpaper behind the panel";
        license = lib.licenses.gpl2Plus;
        platforms = lib.platforms.linux;
        mainProgram = "panel-contrast";
    };
}

# <> #
