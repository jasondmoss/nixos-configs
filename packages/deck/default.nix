{ config, lib, pkgs, ... }:

#-- deck — desktop cards for the project open in PhpStorm.
#--
#-- After Alexander Shumenko's "Deck" for macOS (glance-able cards on the
#-- desktop instead of forty browser tabs), as plain Plasma widgets. Four
#-- cards — Git, Gulp, CircleCI, Pantheon (workshop/deck/plasmoids) — poll one
#-- user service, deck-agent (workshop/deck/agent), over HTTP on 127.0.0.1.
#--
#-- The Git and Gulp cards read the active PhpStorm window's caption through
#-- Plasma's TasksModel ("Title [~/path] – file") and post the project to the
#-- agent, which then tracks that repository and runs `gulp default` with the
#-- project's own node_modules/gulp — the same command as PhpStorm's gulp run
#-- configuration, so the floating Run window is no longer needed. CircleCI
#-- lists the pipelines you triggered across the organisation (API v2,
#-- mine=true); Pantheon follows the site your latest pipeline deploys to
#-- (repository → site from the projects' .lando.yml files) through terminus.
#--
#-- Secrets never enter this repository: the agent reads CIRCLE_TOKEN and
#-- TERMINUS_TOKEN from ~/.config/deck/secrets.env (plain values or op://
#-- references for the 1Password CLI). Runtime overrides go in
#-- ~/.config/deck/config.json; `deck-agent --print-config` shows the merge.
#--
#-- One-time setup after the switch: add the four "Deck: …" widgets to the
#-- desktop (Development Tools category) and write the two tokens to the
#-- secrets file. `journalctl --user -u deck-agent -f` follows the agent;
#-- `curl -s localhost:47657/state | jq` dumps everything the cards see.

with lib;

let
    cfg = config.services.deck;

    configFile = pkgs.writeText "deck-config.json" (builtins.toJSON cfg.settings);
in {
    options.services.deck = {
        enable = mkOption {
            type = types.bool;
            default = true;
            description = "Install the Deck cards and run the deck-agent user service.";
        };

        agent = mkOption {
            type = types.package;
            default = pkgs.callPackage ./package.nix { };
            defaultText = literalExpression "pkgs.callPackage ./package.nix { }";
            description = "The deck-agent service.";
        };

        plasmoids = mkOption {
            type = types.package;
            default = pkgs.callPackage ./plasmoids.nix { };
            defaultText = literalExpression "pkgs.callPackage ./plasmoids.nix { }";
            description = "The four Deck plasmoids.";
        };

        settings = mkOption {
            type = (pkgs.formats.json { }).type;
            default = {
                port = 47657;
                # Scanned (three levels deep) for .lando.yml files: repository
                # name → Pantheon site, so the Pantheon card can follow a pipeline.
                project_roots = [
                    "~/Repository/work/origin"
                    "~/Repository/work/cyan-solutions"
                    "~/Repository/work/mmgy"
                ];
                circleci.org_slug = "gh/originoutside";
                gulp = {
                    task = "default";
                    auto_start = true;    # start the watcher when a project becomes active
                    stop_others = false;  # keep other projects' watchers running
                };
                pantheon.follow = "pipeline";  # pipeline | phpstorm | pinned
            };
            description = ''
                Agent configuration, merged over the defaults in deck-agent.py;
                ~/.config/deck/config.json is merged on top at runtime.
            '';
        };
    };

    config = mkIf cfg.enable {
        environment.systemPackages = [
            cfg.agent
            cfg.plasmoids
            # Also handy on the command line; the agent carries its own copy.
            pkgs.terminus
        ];

        systemd.user.services.deck-agent = {
            description = "Deck agent — data hub for the Deck Plasma cards";
            wantedBy = [ "plasma-workspace.target" ];
            after = [ "plasma-plasmashell.service" ];
            partOf = [ "graphical-session.target" ];

            environment.DECK_CONFIG = configFile;

            serviceConfig = {
                ExecStart = getExe cfg.agent;
                # Stopping the service stops the gulp watchers with it.
                KillMode = "control-group";
                Restart = "on-failure";
                RestartSec = 3;
            };
        };
    };
}

# <> #
