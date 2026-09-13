{ pkgs, ... }:

#-- ClaudeCodeBrowser — Firefox browser automation for Claude Code.
#--
#-- Review history:
#--   d5f6bbe (2026-05-11) — full source review: localhost-only servers
#--     (HTTP 8765 / WS 8766), token auth in ~/.claudecodebrowser/api_token,
#--     no external network calls or telemetry. The AMO-signed extension
#--     (claudecodebrowser@ligandal.com) matched upstream commit c3cfd10.
#--   96a7fd3 (2026-08-26, v1.4.0) — CURRENT PIN. Diff-level review of the
#--     19 commits since d5f6bbe, not a fresh full-source review. Confirmed:
#--     no new outbound network calls in runtime code (added external URLs are
#--     docs, badges and the release/packaging scripts only), servers still
#--     bind loopback, nothing binds 0.0.0.0. Adds mcp-server/safety.py (guard
#--     layer: protected-URL patterns, human approval, rate limits, one-shot
#--     approval tokens, audit log, CLAUDE_BROWSER_ALLOW_SCRIPTS=0 kill
#--     switch), a URL-scheme guard (http/https/about:blank only) and
#--     WebSocket auth on the first frame.
#--     Not re-verified at this pin: whether the installed AMO-signed XPI
#--     still corresponds to this commit — the extension version moved
#--     1.0.0 -> 1.4.0 and gained the "notifications" permission.
#--     Behaviour change worth knowing: content.js now wraps window.fetch and
#--     XMLHttpRequest on every page (<all_urls>) to log request/response
#--     traffic for browser_get_network_logs. Local-only, but broad.
#--     Note the repo's extension/manifest.json also gained an update_url
#--     pointing at GitHub Releases; it does not affect this derivation, which
#--     packages only native-host, mcp-server and agent — never the extension.
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
    pythonEnv = pkgs.python3.withPackages (ps: [ ps.websockets ]);

    #-- Launcher for the dedicated "Claude Code" Firefox profile — the only
    #-- profile with the ClaudeCodeBrowser extension installed. It is an
    #-- in-app profile-groups profile (not in profiles.ini), so it must be
    #-- launched by path, not with -P. The directory is registered in the
    #-- group DB (~/.mozilla/firefox/Profile Groups/f53ea869.sqlite).
    firefoxClaudeProfileDir = "/home/me/.mozilla/firefox/profile-claude-code";

    firefoxClaudeDesktopItem = pkgs.makeDesktopItem {
        type = "Application";
        terminal = false;
        name = "firefox-claude";
        desktopName = "Firefox (Claude Code)";
        exec = "firefox --profile \"${firefoxClaudeProfileDir}\" %u";
        icon = "/home/me/Mega/Images/Icons/Apps/claude.svg";
        startupWMClass = "firefox-claude";
        categories = [ "Network" "WebBrowser" ];
    };

    #-- Commit + hash come from manifest.json. This package is deliberately
    #-- NOT part of the nxmanifest auto-update sweep: its updater is named
    #-- repin.sh rather than update.sh, and nxmanifest only picks up
    #-- directories holding both manifest.json and update.sh. Upstream
    #-- publishes no tags, so automatic updating would mean tracking main and
    #-- silently discarding the source review noted above. Re-pin by hand with
    #-- ./repin.sh <rev> after reading the diff.
    manifest = pkgs.lib.importJSON ./manifest.json;

    claudecodebrowser = pkgs.stdenv.mkDerivation {
        pname = "claudecodebrowser";

        inherit (manifest) version;

        src = pkgs.fetchFromGitHub {
            owner = "nanogenomic";
            repo = "ClaudeCodeBrowser";
            inherit (manifest) rev hash;
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
