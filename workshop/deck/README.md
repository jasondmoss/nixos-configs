# Deck — desktop cards for the project open in PhpStorm

After Alexander Shumenko's *Deck* for macOS (glance-able cards on the desktop
instead of forty browser tabs), done as ordinary Plasma 6 widgets: default
widget background, the stock edit handle, a settings page each.

| Card | Plugin id | Shows |
|---|---|---|
| Git | `org.jdmlabs.deck.git` | Branch, upstream, ahead/behind, stashes, last commit, changed files (click → open in PhpStorm) of the project open in PhpStorm. Fetch + "open repository" buttons. |
| Gulp | `org.jdmlabs.deck.gulp` | The agent's own `gulp default` watcher for that project: state (watching / compiling / error / exited / running elsewhere), last compile, error excerpt, live coloured log. Start / stop / restart / clear. |
| CircleCI | `org.jdmlabs.deck.circleci` | The pipelines *you* triggered across the organisation, with workflows and — for anything not green — jobs. Rows and chips open the browser. |
| Pantheon | `org.jdmlabs.deck.pantheon` | Site, plan, environments (dev/test/live/multidev), connection mode, PHP/Drush, recent workflows, open site/admin/dashboard, clear caches (two clicks). Follows the site your latest pipeline deploys to, or the PhpStorm project, or a pinned site. |

## How it fits together

```
PhpStorm window caption ──TasksModel──▶ Git/Gulp card ──POST /project──▶ deck-agent ──▶ git status
"CHI: Castle Hill Inn [~/Repository/…] – file.php"                          │           gulp default (child process)
                                                                            │           CircleCI API v2 (mine=true)
Cards poll GET /git /gulp?since= /circleci /pantheon  ◀─── 127.0.0.1:47657 ─┘           terminus site:info / env:list / workflow:list
```

* `agent/deck-agent.py` — one Python file, standard library only. Runs as the
  `deck-agent` user service (`packages/deck/default.nix`). `GET /` lists the
  endpoints; `GET /state` dumps everything; `deck-agent --print-config` shows
  the merged configuration.
* `GET /work` — on/off the clock and the reason.
* `plasmoids/<id>/` — one KPackage per card. `plasmoids/common/` holds the
  shared QML (`DeckClient` polling, `ProjectTracker`, `CardHeader`, `Pill`,
  `StatusDot`, `Offline`, `Utils.js`), symlinked into each package and
  dereferenced by the Nix build.

The active project is the PhpStorm window that was focused last. PhpStorm's
caption carries the project path in brackets, and Plasma's `TasksModel` gives
the cards the active window, so no IDE plugin is needed. The agent seeds itself
from PhpStorm's `recentProjects.xml` on start.

The Gulp watcher runs the same command as PhpStorm's gulp run configuration
(`node <theme>/node_modules/gulp/bin/gulp.js --color --gulpfile … default`),
found through `.idea/workspace.xml` or `web/themes/custom/*/gulpfile.js`. A
gulp started elsewhere for the same gulpfile (PhpStorm's Run window) is
detected and shown as "running outside the agent" instead of starting a
second one.

Repository → Pantheon site comes from the `.lando.yml` files under the
configured project roots (`config.site`, `config.id`, plus `git remote
get-url origin`).

## Off the clock

The agent decides you are working when any PhpStorm window shows a project
under one of the `project_roots` (every card reports the full window list),
or when one of `work.processes` (default: Google Chrome, used for work only)
is running. Otherwise the CircleCI and Pantheon cards show a placeholder
("Off the clock") and the agent polls both services every `work.idle_interval`
seconds instead of every minute or two. `GET /work` shows the verdict and why.
Each of the two cards can opt out in its settings.

## Configuration and secrets

Defaults in `deck-agent.py` ← `services.deck.settings` (NixOS module, written
to the store as JSON) ← `~/.config/deck/config.json`.

`~/.config/deck/secrets.env` (never in this repository):

```
CIRCLE_TOKEN=…        # CircleCI personal API token (User settings → Personal API Tokens)
TERMINUS_TOKEN=…      # Pantheon machine token (Account → Machine Tokens)
```

Values may also be `op://<vault>/<item>/<field>` references; the agent resolves
them with the 1Password CLI when the app is unlocked and retries otherwise.
The file is re-read when it changes.

Terminus does not read `TERMINUS_TOKEN` for ordinary commands: the agent runs
`terminus auth:login --machine-token=…` with it the first time terminus answers
"not logged in", and the session lands in `~/.terminus` (so the `terminus` CLI
is logged in too). Organisation labels come from `org:list`, PHP/Drush versions
from `env:info` (dev/test/live only, cached half an hour).

The systemd user unit has NixOS's minimal PATH; the wrapper appends
`/run/wrappers/bin:/run/current-system/sw/bin` so node (the one PhpStorm uses),
phpstorm, op and ssh are found.

## After a rebuild

`nxr` installs new builds but does not restart user-level things:

```
systemctl --user restart deck-agent            # new agent code
systemctl --user restart plasma-plasmashell    # widgets reload their QML from the new store path
```

Widgets already on the desktop keep the QML they were created with until
plasmashell restarts, so a card can look one version behind the agent.

## Developing

```
# agent, on a scratch port with a scratch config dir
DECK_CONFIG_DIR=/tmp/deckcfg python3 agent/deck-agent.py --port 47658
curl -s -X POST -H 'X-Deck: 1' -d '{"caption":"X [~/Repository/work/origin/seymour] – f","active":true}' localhost:47658/project
curl -s localhost:47658/gulp | jq

# a card (the symlinks resolve in place)
nix-shell -p kdePackages.plasma-sdk --run "plasmoidviewer -a plasmoids/org.jdmlabs.deck.gulp --size 600x460"
```

POST requests need an `X-Deck` header (keeps browsers from poking the agent);
the agent only listens on 127.0.0.1.
