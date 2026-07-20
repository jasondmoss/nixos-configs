{ pkgs, ... }:

#-- ClaudeCodeBrowser — Firefox browser automation for Claude Code.
#-- Source reviewed at the pinned commit (2026-05-11): localhost-only servers
#-- (HTTP 8765 / WS 8766), token auth in ~/.claudecodebrowser/api_token,
#-- no external network calls or telemetry. The AMO-signed extension
#-- (claudecodebrowser@ligandal.com) matches upstream commit c3cfd10.
#--
#-- Components installed:
#--   claudecodebrowser-host   — native messaging host (launched by Firefox)
#--   claudecodebrowser-mcp    — MCP stdio wrapper (register with Claude Code)
#--   claudecodebrowser-server — MCP HTTP/WS server (auto-started; manual run for debugging)
#--   claudecodebrowser-agent  — standalone CLI automation agent
#--
#-- Runtime state lives in ~/.claudecodebrowser (logs, api_token) and
#-- screenshots in /tmp/claudecodebrowser/screenshots.

let
    identity = import ../../identity.nix;

    pythonEnv = pkgs.python3.withPackages (ps: [ ps.websockets ]);

    #-- Launcher for the dedicated "Claude Code" Firefox profile — the only
    #-- profile with the ClaudeCodeBrowser extension installed. It is an
    #-- in-app profile-groups profile (not in profiles.ini), so it must be
    #-- launched by path, not with -P. The directory is registered in the
    #-- group DB (~/.mozilla/firefox/Profile Groups/f53ea869.sqlite).
    firefoxClaudeProfileDir = "${identity.userHome}/.mozilla/firefox/profile-claude-code";

    firefoxClaudeDesktopItem = pkgs.makeDesktopItem {
        type = "Application";
        terminal = false;
        name = "firefox-claude";
        desktopName = "Firefox (Claude Code)";
        exec = "firefox --profile \"${firefoxClaudeProfileDir}\" %u";
        icon = "${identity.userHome}/Mega/Images/Icons/Apps/claude.svg";
        startupWMClass = "firefox-claude";
        categories = [ "Network" "WebBrowser" ];
    };

    claudecodebrowser = pkgs.stdenv.mkDerivation rec {
        pname = "claudecodebrowser";
        version = "1.0.0-unstable-2026-05-11";

        src = pkgs.fetchFromGitHub {
            owner = "nanogenomic";
            repo = "ClaudeCodeBrowser";
            rev = "d5f6bbe9fef2cfe82474722320af7e04499fb10d";
            hash = "sha256-Hbj3i+DezUcctRi18+WyJjkfsq2GxN8EtCX+WBxo30A=";
        };

        nativeBuildInputs = [ pkgs.makeWrapper ];

        dontBuild = true;

        installPhase = ''
mkdir -p $out/bin $out/share/claudecodebrowser $out/lib/mozilla/native-messaging-hosts

#-- Keep the repo layout: the native host locates server.py relative to itself.
cp -r native-host mcp-server agent $out/share/claudecodebrowser/

#-- lsof is used by the native host to reap stale server processes.
makeWrapper ${pythonEnv}/bin/python3 $out/bin/claudecodebrowser-host \
 --add-flags "$out/share/claudecodebrowser/native-host/claudecodebrowser_host.py" \
 --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.lsof ]}

makeWrapper ${pythonEnv}/bin/python3 $out/bin/claudecodebrowser-mcp \
 --add-flags "$out/share/claudecodebrowser/mcp-server/stdio_wrapper.py"

makeWrapper ${pythonEnv}/bin/python3 $out/bin/claudecodebrowser-server \
 --add-flags "$out/share/claudecodebrowser/mcp-server/server.py" \
 --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.lsof ]}

makeWrapper ${pythonEnv}/bin/python3 $out/bin/claudecodebrowser-agent \
 --add-flags "$out/share/claudecodebrowser/agent/browser_agent.py"

#-- Native messaging manifest pointing at the store path of the host.
cat > $out/lib/mozilla/native-messaging-hosts/claudecodebrowser.json << EOF
{
  "name": "claudecodebrowser",
  "description": "ClaudeCodeBrowser Native Messaging Host - Bridge between Firefox extension and MCP server",
  "path": "$out/bin/claudecodebrowser-host",
  "type": "stdio",
  "allowed_extensions": [
    "claudecodebrowser@ligandal.com"
  ]
}
EOF
        '';

        meta = with pkgs.lib; {
            description = "Firefox browser automation MCP server for Claude Code";
            homepage = "https://github.com/nanogenomic/ClaudeCodeBrowser";
            license = licenses.mit;
            platforms = platforms.linux;
        };
    };
in {
    environment.systemPackages = [
        claudecodebrowser

        #-- Create desktop entry.
        firefoxClaudeDesktopItem
    ];

    #-- Firefox always scans ~/.mozilla/native-messaging-hosts, regardless of
    #-- how it was packaged; symlink the manifest there declaratively.
    systemd.user.tmpfiles.rules = [
        "L+ %h/.mozilla/native-messaging-hosts/claudecodebrowser.json - - - - ${claudecodebrowser}/lib/mozilla/native-messaging-hosts/claudecodebrowser.json"
    ];
}

# <> #
