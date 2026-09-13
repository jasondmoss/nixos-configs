{ lib, stdenvNoCC, python3, makeWrapper, writeText, coreutils, wl-clipboard, systemd, kdePackages
, busName ? "org.jdmlabs.krunner.ollama"
, triggerWords ? [ "ai" "?" ]
, unitName ? "krunner-ollama.service"
}:

#-- krunner-ollama — the runner program plus the two files KRunner and the
#-- session bus need to find it. Runtime settings (model, URLs, ...) come
#-- from the environment set by the module; only what KRunner reads from
#-- disk before any D-Bus call is baked in here.
#--
#--   bin/krunner-ollama                              the D-Bus service
#--   share/krunner/dbusplugins/plasma-runner-ollama.desktop  plugin metadata
#--   share/dbus-1/services/<busName>.service          on-demand activation
#--                                                    → SystemdService=<unit>

let
    pythonEnv = python3.withPackages (ps: [ ps.dbus-python ps.pygobject3 ]);

    #-- KConfig unescapes backslash sequences when reading .desktop values
    #-- (`\s` is a space), so every backslash the regex needs is doubled.
    kconfigEscape = lib.replaceStrings [ "\\" ] [ "\\\\" ];
    matchRegex = kconfigEscape
        "^(?:${lib.concatMapStringsSep "|" lib.escapeRegex triggerWords})(?:\\s|$)";
    minLetterCount = lib.foldl' lib.min 1000 (map lib.stringLength triggerWords);

    #-- One syntax entry per trigger word; entries are comma-separated.
    syntaxDescription = "Asks the local Ollama model :q: and shows the first line of the answer. Enter copies the full answer to the clipboard. The action button opens the question in Open WebUI.";
    syntaxes = lib.concatMapStringsSep "," (w: "${w} :q:") triggerWords;
    syntaxDescriptions = lib.concatMapStringsSep "," (_: syntaxDescription) triggerWords;

    #-- X-Plasma-API=DBus2: KRunner calls Config() on load (which D-Bus-
    #-- activates the service) and Teardown() after every query session. The
    #-- regex/letter count below are the fallback for when Config() fails.
    pluginDesktop = ''
[Desktop Entry]
Name=Ollama
Comment=Ask the local Ollama model from KRunner
Type=Service
Icon=applications-science
X-KDE-PluginInfo-Name=krunner-ollama
X-KDE-PluginInfo-Version=0.1.0
X-KDE-PluginInfo-License=GPL-2.0-or-later
X-KDE-PluginInfo-EnabledByDefault=true
X-Plasma-API=DBus2
X-Plasma-DBusRunner-Service=${busName}
X-Plasma-DBusRunner-Path=/runner
X-Plasma-Request-Actions-Once=true
X-Plasma-Runner-Min-Letter-Count=${toString minLetterCount}
X-Plasma-Runner-Match-Regex=${matchRegex}
X-Plasma-Runner-Syntaxes=${syntaxes}
X-Plasma-Runner-Syntax-Descriptions=${syntaxDescriptions}
    '';

    #-- dbus-broker hands activation requests to the user manager, so the
    #-- Exec= line is never run; it only has to exist.
    dbusService = ''
[D-BUS Service]
Name=${busName}
Exec=${coreutils}/bin/false
SystemdService=${unitName}
    '';
in stdenvNoCC.mkDerivation {
    pname = "krunner-ollama";
    version = "0.1.0";

    src = ./krunner-ollama.py;
    dontUnpack = true;
    dontConfigure = true;
    dontBuild = true;

    nativeBuildInputs = [ makeWrapper ];

    doCheck = true;
    checkPhase = ''
        runHook preCheck
        ${pythonEnv}/bin/python3 -m py_compile "$src"
        runHook postCheck
    '';

    installPhase = ''
        runHook preInstall

        install -Dm644 "$src" "$out/libexec/krunner-ollama.py"
        makeWrapper "${pythonEnv}/bin/python3" "$out/bin/krunner-ollama" \
            --add-flags "$out/libexec/krunner-ollama.py" \
            --set PYTHONUNBUFFERED 1 \
            --set-default KRUNNER_OLLAMA_BUS_NAME "${busName}" \
            --set-default KRUNNER_OLLAMA_TRIGGERS "${lib.concatStringsSep " " triggerWords}" \
            --prefix PATH : "${lib.makeBinPath [ wl-clipboard systemd kdePackages.kde-cli-tools ]}"

        install -Dm644 "${writeText "plasma-runner-ollama.desktop" pluginDesktop}" \
            "$out/share/krunner/dbusplugins/plasma-runner-ollama.desktop"
        install -Dm644 "${writeText "${busName}.service" dbusService}" \
            "$out/share/dbus-1/services/${busName}.service"

        runHook postInstall
    '';

    meta = {
        description = "KRunner D-Bus runner that asks a local Ollama model and copies or opens the answer";
        license = lib.licenses.gpl2Plus;
        platforms = lib.platforms.linux;
        mainProgram = "krunner-ollama";
    };
}

# <> #
