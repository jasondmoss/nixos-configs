#!/usr/bin/env python3
"""
deck-agent — the local data hub behind the Deck Plasma cards.

One user service gathers everything the cards show and serves it as JSON over
HTTP on 127.0.0.1 (default port 47657); the plasmoids poll it with
XMLHttpRequest. Cards post the active PhpStorm project (read from the window
caption through Plasma's TasksModel), and the agent follows it:

  /git        branch, ahead/behind, changed files and last commit of the
              active project (git status --porcelain=v2, polled; fetch on a
              slower timer)
  /gulp       the agent's own `gulp <task>` watcher for the active project —
              started with the project's node_modules/gulp like PhpStorm's
              run configuration — with its output (ANSI → HTML) and a small
              state machine (watching / compiling / error / exited)
  /circleci   the pipelines you triggered across the organisation
              (CircleCI API v2, `mine=true`) with workflows and jobs
  /pantheon   site, environments and recent workflows (terminus) of the site
              the latest pipeline deploys to — the repo → site mapping comes
              from the .lando.yml files under the configured project roots

Configuration: defaults below ← $DECK_CONFIG (JSON, written by the NixOS
module) ← ~/.config/deck/config.json. Secrets: ~/.config/deck/secrets.env with
CIRCLE_TOKEN and TERMINUS_TOKEN (plain values or op:// references resolved
with the 1Password CLI). Standard library only.

SPDX-License-Identifier: GPL-2.0-or-later
"""

import argparse
import collections
import faulthandler
import glob
import html
import json
import os
import re
import shlex
import shutil
import signal
import subprocess
import sys
import threading
import time
import urllib.error
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ET
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

VERSION = "0.1.0"
STARTED = time.time()

DEFAULTS = {
    "port": 47657,
    # Roots scanned (3 levels deep) for .lando.yml files: repository name →
    # Pantheon site, used by the Pantheon card to follow a pipeline.
    "project_roots": [
        "~/Repository/work/origin",
        "~/Repository/work/cyan-solutions",
        "~/Repository/work/mmgy",
    ],
    "phpstorm": {
        "bin": "phpstorm",
        "recent_projects": "~/.config/JetBrains/PhpStorm*/options/recentProjects.xml",
    },
    "git": {
        "interval": 5,          # seconds between status refreshes
        "fetch": True,          # git fetch the active project …
        "fetch_interval": 600,  # … this often
        "max_files": 80,        # files listed per bucket
    },
    "gulp": {
        "node": "",             # empty: `node` from PATH (PhpStorm uses the system node)
        "task": "default",
        "auto_start": True,     # start the watcher when a project becomes active
        "stop_others": False,   # stop watchers of other projects when switching
        "buffer": 400,          # lines kept per watcher
    },
    "circleci": {
        "org_slug": "gh/originoutside",
        "interval": 60,
        "active_interval": 20,  # while something is running
        "limit": 8,
        "jobs": True,
    },
    "pantheon": {
        "follow": "pipeline",   # pipeline | phpstorm | pinned
        "site": "",             # for follow = pinned
        "interval": 120,
        "workflow_limit": 10,
    },
}

CONFIG_DIR = Path(os.environ.get("DECK_CONFIG_DIR", "~/.config/deck")).expanduser()


def log(*parts):
    print(time.strftime("%H:%M:%S"), *parts, file=sys.stderr, flush=True)


def deep_merge(base, extra):
    out = dict(base)
    for key, value in (extra or {}).items():
        if isinstance(value, dict) and isinstance(out.get(key), dict):
            out[key] = deep_merge(out[key], value)
        else:
            out[key] = value
    return out


def load_config():
    cfg = DEFAULTS
    for candidate in (os.environ.get("DECK_CONFIG"), CONFIG_DIR / "config.json"):
        if not candidate:
            continue
        path = Path(candidate).expanduser()
        if path.is_file():
            try:
                cfg = deep_merge(cfg, json.loads(path.read_text()))
            except (OSError, ValueError) as exc:
                log(f"config {path}: {exc}")
    return cfg


def run(cmd, cwd=None, timeout=30, env=None, text=True):
    """Run a command; returns (returncode, stdout, stderr), never raises."""
    merged = dict(os.environ)
    merged.setdefault("GIT_TERMINAL_PROMPT", "0")
    if env:
        merged.update(env)
    try:
        proc = subprocess.run(
            cmd, cwd=cwd, timeout=timeout, env=merged, text=text,
            stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
        )
        return proc.returncode, proc.stdout, proc.stderr
    except subprocess.TimeoutExpired:
        return 124, "", f"timed out after {timeout}s: {shlex.join(cmd)}"
    except OSError as exc:
        return 127, "", str(exc)


def now_iso(ts=None):
    return time.strftime("%Y-%m-%dT%H:%M:%S%z", time.localtime(ts))


# Where a program lives when PATH is a systemd unit's minimal one.
FALLBACK_BIN_DIRS = ("/run/wrappers/bin", "/run/current-system/sw/bin",
                     os.path.expanduser("~/.nix-profile/bin"), "/usr/local/bin", "/usr/bin")


def find_bin(name):
    """`name` as given if it is a path to an executable, else PATH, else the usual NixOS places."""
    if not name:
        return None
    if os.path.sep in name:
        return name if os.access(name, os.X_OK) else None
    found = shutil.which(name)
    if found:
        return found
    for directory in FALLBACK_BIN_DIRS:
        candidate = os.path.join(directory, name)
        if os.access(candidate, os.X_OK):
            return candidate
    return None


# --------------------------------------------------------------------------
# Secrets
# --------------------------------------------------------------------------

class Secrets:
    """KEY=VALUE lines from secrets.env; op:// values go through `op read`."""

    def __init__(self):
        self.path = CONFIG_DIR / "secrets.env"
        self._mtime = None
        self._raw = {}
        self._resolved = {}
        self._failed_at = {}
        self._lock = threading.Lock()

    def _reload(self):
        try:
            mtime = self.path.stat().st_mtime
        except OSError:
            self._raw, self._mtime = {}, None
            return
        if mtime == self._mtime:
            return
        raw = {}
        for line in self.path.read_text().splitlines():
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            key, value = line.split("=", 1)
            value = value.strip()
            if len(value) >= 2 and value[0] == value[-1] and value[0] in "\"'":
                value = value[1:-1]
            raw[key.strip()] = value
        self._raw, self._mtime = raw, mtime
        self._resolved.clear()
        self._failed_at.clear()

    def get(self, name):
        with self._lock:
            self._reload()
            value = self._raw.get(name) or os.environ.get(name) or ""
            if not value.startswith("op://"):
                return value or None
            if name in self._resolved:
                return self._resolved[name]
            if time.time() - self._failed_at.get(name, 0) < 60:
                return None
            code, out, err = run(["op", "read", "--no-newline", value], timeout=30)
            if code == 0 and out.strip():
                self._resolved[name] = out.strip()
                return self._resolved[name]
            self._failed_at[name] = time.time()
            log(f"secret {name}: op read failed: {err.strip().splitlines()[-1] if err.strip() else code}")
            return None

    def status(self):
        with self._lock:
            self._reload()
            return {
                "file": str(self.path),
                "present": self._mtime is not None,
                "keys": sorted(self._raw),
            }


# --------------------------------------------------------------------------
# Active project
# --------------------------------------------------------------------------

CAPTION_PATH = re.compile(r"\[(~?/[^\]]+)\]")


def parse_caption(caption):
    """'CHI: Castle Hill Inn [~/Repository/x] – file.php' → (path, title)."""
    match = CAPTION_PATH.search(caption or "")
    if not match:
        return None, None
    path = os.path.expanduser(match.group(1))
    title = caption[: match.start()].strip().rstrip("-–—").strip()
    return path, title or os.path.basename(path)


class ProjectTracker:
    def __init__(self, cfg):
        self.cfg = cfg
        self._lock = threading.Lock()
        self.path = None
        self.title = None
        self.source = None
        self.changed_at = None
        self.listeners = []

    def snapshot(self):
        with self._lock:
            return {
                "path": self.path,
                "short": self.path.replace(str(Path.home()), "~", 1) if self.path else None,
                "name": os.path.basename(self.path) if self.path else None,
                "title": self.title,
                "source": self.source,
                "changed_at": self.changed_at,
            }

    def report(self, path, title=None, active=True, source="phpstorm"):
        if not path:
            return self.snapshot()
        path = os.path.expanduser(path).rstrip("/")
        if not os.path.isdir(path):
            return self.snapshot()
        changed = False
        with self._lock:
            # A background PhpStorm window never displaces the active project.
            # (No self.snapshot() in here: the lock is not reentrant.)
            if active or not self.path or self.path == path:
                changed = path != self.path
                self.path, self.title, self.source = path, title or os.path.basename(path), source
                if changed:
                    self.changed_at = now_iso()
        if changed:
            log(f"project → {path} ({source})")
            for listener in self.listeners:
                try:
                    listener(path)
                except Exception as exc:  # noqa: BLE001 — listeners must not kill the tracker
                    log(f"listener error: {exc}")
        return self.snapshot()

    def seed_from_recent_projects(self):
        """Startup fallback: the PhpStorm project activated most recently."""
        files = sorted(glob.glob(os.path.expanduser(self.cfg["phpstorm"]["recent_projects"])),
                       key=lambda f: os.path.getmtime(f), reverse=True)
        if not files:
            return
        try:
            root = ET.parse(files[0]).getroot()
        except (ET.ParseError, OSError) as exc:
            log(f"recentProjects.xml: {exc}")
            return
        best = (0, None, None)
        for entry in root.iter("entry"):
            key = entry.get("key", "")
            info = entry.find("./value/RecentProjectMetaInfo")
            if info is None or info.get("hidden") == "true":
                continue
            stamp = info.find("./option[@name='activationTimestamp']")
            try:
                when = int(stamp.get("value")) if stamp is not None else 0
            except ValueError:
                when = 0
            path = key.replace("$USER_HOME$", str(Path.home()))
            if when > best[0] and os.path.isdir(path):
                title = (info.get("frameTitle") or "").split(" [")[0].strip()
                best = (when, path, title)
        if best[1]:
            self.report(best[1], best[2], source="recent")


# --------------------------------------------------------------------------
# Git
# --------------------------------------------------------------------------

STATUS_WORDS = {
    "M": "modified", "A": "added", "D": "deleted", "R": "renamed",
    "C": "copied", "T": "typechange", "U": "unmerged",
}


def remote_web_url(remote):
    if not remote:
        return None
    match = re.match(r"^(?:git@|ssh://git@)?github\.com[^:/]*[:/]([^/]+)/([^/]+?)(?:\.git)?/?$", remote)
    if match:
        return f"https://github.com/{match.group(1)}/{match.group(2)}"
    match = re.match(r"^https?://github\.com/([^/]+)/([^/]+?)(?:\.git)?/?$", remote)
    if match:
        return f"https://github.com/{match.group(1)}/{match.group(2)}"
    match = re.match(r"^(?:git@|ssh://git@)?(gitlab\.com|bitbucket\.org)[:/]([^/]+)/([^/]+?)(?:\.git)?/?$", remote)
    if match:
        return f"https://{match.group(1)}/{match.group(2)}/{match.group(3)}"
    return None


class GitPoller(threading.Thread):
    def __init__(self, cfg, tracker):
        super().__init__(name="git", daemon=True)
        self.cfg = cfg["git"]
        self.tracker = tracker
        self.wake = threading.Event()
        self.fetch_now = threading.Event()
        self._lock = threading.Lock()
        self.state = {"available": False, "project": None}
        self._fetched = {}
        tracker.listeners.append(lambda _path: self.wake.set())

    def snapshot(self):
        with self._lock:
            return dict(self.state)

    def run(self):
        while True:
            try:
                self.collect()
            except Exception as exc:  # noqa: BLE001
                log(f"git: {exc}")
            self.wake.wait(self.cfg["interval"])
            self.wake.clear()

    def collect(self):
        project = self.tracker.snapshot()
        path = project["path"]
        base = {"project": project, "updated_at": now_iso()}
        if not path:
            with self._lock:
                self.state = {**base, "available": False, "error": "No PhpStorm project yet"}
            return
        code, top, _ = run(["git", "-C", path, "rev-parse", "--show-toplevel"], timeout=10)
        if code != 0:
            with self._lock:
                self.state = {**base, "available": False, "error": "Not a git repository"}
            return
        top = top.strip()

        if self.cfg["fetch"] and (self.fetch_now.is_set()
                                  or time.time() - self._fetched.get(top, 0) > self.cfg["fetch_interval"]):
            self.fetch_now.clear()
            self._fetched[top] = time.time()
            fcode, _, ferr = run(["git", "-C", top, "fetch", "--quiet"], timeout=90,
                                 env={"GIT_SSH_COMMAND": "ssh -o BatchMode=yes -o ConnectTimeout=15"})
            if fcode != 0:
                log(f"git fetch {top}: {ferr.strip().splitlines()[-1] if ferr.strip() else fcode}")

        code, out, err = run(["git", "-C", top, "status", "--porcelain=v2", "--branch"], timeout=30)
        if code != 0:
            with self._lock:
                self.state = {**base, "available": False, "error": err.strip() or "git status failed"}
            return

        info = {
            "branch": None, "upstream": None, "ahead": 0, "behind": 0, "detached": False, "oid": None,
            "staged": [], "unstaged": [], "untracked": [], "conflicts": [],
        }
        counts = {"staged": 0, "unstaged": 0, "untracked": 0, "conflicts": 0}
        limit = self.cfg["max_files"]

        def add(bucket, item):
            counts[bucket] += 1
            if len(info[bucket]) < limit:
                info[bucket].append(item)

        for line in out.splitlines():
            if line.startswith("# branch.oid "):
                info["oid"] = line[13:]
            elif line.startswith("# branch.head "):
                head = line[14:]
                info["detached"] = head == "(detached)"
                info["branch"] = None if info["detached"] else head
            elif line.startswith("# branch.upstream "):
                info["upstream"] = line[18:]
            elif line.startswith("# branch.ab "):
                match = re.match(r"# branch\.ab \+(\d+) -(\d+)", line)
                if match:
                    info["ahead"], info["behind"] = int(match.group(1)), int(match.group(2))
            elif line[:2] in ("1 ", "2 "):
                parts = line.split(" ", 8 if line[0] == "1" else 9)
                xy = parts[1]
                rest = parts[-1]
                if line[0] == "2":
                    rest = rest.split("\t")[0]
                if xy[0] != ".":
                    add("staged", {"path": rest, "status": xy[0], "label": STATUS_WORDS.get(xy[0], xy[0])})
                if xy[1] != ".":
                    add("unstaged", {"path": rest, "status": xy[1], "label": STATUS_WORDS.get(xy[1], xy[1])})
            elif line.startswith("u "):
                parts = line.split(" ", 10)
                add("conflicts", {"path": parts[-1], "status": "U", "label": "conflict"})
            elif line.startswith("? "):
                add("untracked", {"path": line[2:], "status": "?", "label": "untracked"})

        code, out, _ = run(["git", "-C", top, "log", "-1", "--format=%h%x01%s%x01%cr%x01%an%x01%ct"], timeout=10)
        last = None
        if code == 0 and out.strip():
            fields = out.strip().split("\x01")
            if len(fields) == 5:
                last = {"hash": fields[0], "subject": fields[1], "when": fields[2],
                        "author": fields[3], "time": int(fields[4])}

        code, out, _ = run(["git", "-C", top, "rev-list", "--walk-reflogs", "--count", "refs/stash"], timeout=10)
        stashes = int(out.strip()) if code == 0 and out.strip().isdigit() else 0

        _, remote, _ = run(["git", "-C", top, "remote", "get-url", "origin"], timeout=10)
        remote = remote.strip() or None

        with self._lock:
            self.state = {
                **base,
                "available": True,
                "root": top,
                **info,
                "counts": counts,
                "dirty": any(counts.values()),
                "last_commit": last,
                "stashes": stashes,
                "remote": remote,
                "web_url": remote_web_url(remote),
                "fetched_at": now_iso(self._fetched[top]) if top in self._fetched else None,
                "fetch_enabled": self.cfg["fetch"],
            }


# --------------------------------------------------------------------------
# Gulp
# --------------------------------------------------------------------------

ANSI_RE = re.compile(r"\x1b\[([0-9;]*)m|\x1b\][^\x07\x1b]*(?:\x07|\x1b\\)|\x1b\[[0-9;?]*[A-Za-z]|\x1b[()][AB012]")

ANSI_16 = {
    30: "#8b8b96", 31: "#ff6b6b", 32: "#5be39a", 33: "#f5c451", 34: "#6ea8fe", 35: "#d58cff",
    36: "#5fd7e5", 37: "#e8e8ee", 90: "#8b8b96", 91: "#ff8585", 92: "#7ff0b1", 93: "#ffd56b",
    94: "#8fbcff", 95: "#e4a7ff", 96: "#86e5ef", 97: "#ffffff",
}


def xterm256(index):
    if index < 16:
        return ANSI_16.get(30 + index if index < 8 else 90 + index - 8, "#e8e8ee")
    if index < 232:
        index -= 16
        r, g, b = index // 36, (index // 6) % 6, index % 6
        return "#%02x%02x%02x" % tuple(0 if v == 0 else 55 + v * 40 for v in (r, g, b))
    grey = 8 + (index - 232) * 10
    return "#%02x%02x%02x" % (grey, grey, grey)


def ansi_to_html(text):
    """Minimal SGR → Qt rich text (font color, b, i, u). Everything else is dropped."""
    out, pos = [], 0
    color, bold, italic, underline = None, False, False, False
    open_tags = []

    def close():
        while open_tags:
            out.append(open_tags.pop())

    def reopen():
        if color:
            out.append(f'<font color="{color}">')
            open_tags.append("</font>")
        if bold:
            out.append("<b>")
            open_tags.append("</b>")
        if italic:
            out.append("<i>")
            open_tags.append("</i>")
        if underline:
            out.append("<u>")
            open_tags.append("</u>")

    for match in ANSI_RE.finditer(text):
        if match.start() > pos:
            out.append(html.escape(text[pos:match.start()]))
        pos = match.end()
        if match.group(1) is None:
            continue
        codes = [int(c) if c else 0 for c in match.group(1).split(";")] or [0]
        i = 0
        while i < len(codes):
            code = codes[i]
            if code == 0:
                color, bold, italic, underline = None, False, False, False
            elif code == 1:
                bold = True
            elif code == 2:
                color = color or "#9a9aa5"
            elif code == 3:
                italic = True
            elif code == 4:
                underline = True
            elif code in (22, 23, 24):
                bold = bold and code != 22
                italic = italic and code != 23
                underline = underline and code != 24
            elif code == 39:
                color = None
            elif code in ANSI_16:
                color = ANSI_16[code]
            elif code == 38 and i + 1 < len(codes):
                if codes[i + 1] == 5 and i + 2 < len(codes):
                    color = xterm256(codes[i + 2])
                    i += 2
                elif codes[i + 1] == 2 and i + 4 < len(codes):
                    color = "#%02x%02x%02x" % tuple(min(255, max(0, v)) for v in codes[i + 2:i + 5])
                    i += 4
            elif code == 48 and i + 1 < len(codes):
                i += 2 if codes[i + 1] == 5 else 4 if codes[i + 1] == 2 else 0
            i += 1
        close()
        reopen()
    if pos < len(text):
        out.append(html.escape(text[pos:]))
    close()
    return "".join(out)


GULP_STARTING = re.compile(r"Starting '([^']+)'")
GULP_FINISHED = re.compile(r"Finished '([^']+)' after (.+?)\s*$")
GULP_ERRORED = re.compile(r"'([^']+)' errored after")
GULP_ERROR_MARK = re.compile(r"(Error in plugin|\bError\b|SassError|TypeError|ReferenceError|SyntaxError|ENOENT|✖\s+\d+\s+problems?)")
GULP_WARN_MARK = re.compile(r"(warning|✖|deprecat)", re.IGNORECASE)


def find_gulpfile(project, task):
    """PhpStorm's gulp run configuration first, then the usual theme layout."""
    workspace = Path(project) / ".idea" / "workspace.xml"
    found = []
    if workspace.is_file():
        try:
            root = ET.parse(workspace).getroot()
            for conf in root.iterfind("./component[@name='RunManager']/configuration[@type='js.build_tools.gulp']"):
                gulpfile = conf.findtext("gulpfile")
                tasks = [t.text for t in conf.iterfind("./tasks/task")]
                if gulpfile:
                    path = gulpfile.replace("$PROJECT_DIR$", project)
                    if os.path.isfile(path):
                        found.append((0 if task in tasks else 1, path))
        except ET.ParseError as exc:
            log(f"workspace.xml {project}: {exc}")
    if found:
        return sorted(found)[0][1]
    for pattern in ("web/themes/custom/*/gulpfile.js", "themes/custom/*/gulpfile.js",
                    "docroot/themes/custom/*/gulpfile.js", "gulpfile.js"):
        matches = sorted(glob.glob(os.path.join(project, pattern)))
        if matches:
            preferred = [m for m in matches if "/origin/" in m]
            return (preferred or matches)[0]
    return None


class GulpWatcher:
    def __init__(self, cfg, project):
        self.cfg = cfg
        self.project = project
        self.task = cfg["task"]
        self.gulpfile = find_gulpfile(project, self.task)
        self.cwd = os.path.dirname(self.gulpfile) if self.gulpfile else None
        self.theme = os.path.basename(self.cwd) if self.cwd else None
        self.proc = None
        self.pgid = None
        self.started_at = None
        self.ended_at = None
        self.exit_code = None
        self.stopped_by_user = False
        self.phase = "idle"      # idle | compiling
        self.cycle_error = False
        self.error = None        # {"at", "task", "lines"}
        self.error_capture = 0
        self.warnings = 0
        self.last_event = None   # {"kind", "task", "duration", "at"}
        self.message = None
        self.seq = 0
        self.lines = collections.deque(maxlen=cfg["buffer"])
        self.lock = threading.Lock()
        self.command = None

    # -- process ------------------------------------------------------------

    def _resolve_command(self):
        node = find_bin(self.cfg["node"] or "node")
        if not node:
            return None, "node not found — set gulp.node in ~/.config/deck/config.json"
        candidates = [
            os.path.join(self.cwd, "node_modules", "gulp", "bin", "gulp.js"),
            os.path.join(self.cwd, "node_modules", ".bin", "gulp"),
        ]
        gulp_bin = next((c for c in candidates if os.path.exists(c)), None)
        if gulp_bin and gulp_bin.endswith("gulp.js"):
            cmd = [node, gulp_bin]
        elif gulp_bin:
            cmd = [gulp_bin]
        elif find_bin("gulp"):
            cmd = [find_bin("gulp")]
        else:
            return None, f"gulp is not installed in {self.theme} — run yarn/npm install"
        return cmd + ["--color", "--gulpfile", self.gulpfile, self.task], None

    def start(self):
        with self.lock:
            if self.running:
                return True
            if not self.gulpfile:
                self.message = "No gulpfile found in this project"
                return False
            cmd, error = self._resolve_command()
            if error:
                self.message = error
                return False
            env = dict(os.environ, FORCE_COLOR="1", DECK_AGENT_GULP="1", TERM="xterm-256color")
            env.pop("NODE_OPTIONS", None)
            try:
                self.proc = subprocess.Popen(
                    cmd, cwd=self.cwd, env=env, start_new_session=True,
                    stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                )
            except OSError as exc:
                self.message = f"Could not start gulp: {exc}"
                return False
            self.pgid = os.getpgid(self.proc.pid)
            self.command = shlex.join(cmd)
            self.started_at = time.time()
            self.ended_at = self.exit_code = None
            self.stopped_by_user = False
            self.phase, self.cycle_error, self.error, self.warnings = "idle", False, None, 0
            self.message = None
            short_dir = self.cwd.replace(str(Path.home()), "~", 1)
            self._append(f"$ gulp {self.task}  ({short_dir})", meta=True)
            threading.Thread(target=self._reader, name=f"gulp:{self.theme}", daemon=True).start()
            log(f"gulp start [{self.project}] {self.command}")
            return True

    def stop(self, by_user=True):
        with self.lock:
            if not self.running:
                return
            self.stopped_by_user = by_user
            pgid, proc = self.pgid, self.proc
        try:
            os.killpg(pgid, signal.SIGTERM)
        except ProcessLookupError:
            return
        try:
            proc.wait(timeout=5)
        except subprocess.TimeoutExpired:
            try:
                os.killpg(pgid, signal.SIGKILL)
            except ProcessLookupError:
                pass

    @property
    def running(self):
        return self.proc is not None and self.proc.poll() is None

    def _reader(self):
        proc = self.proc
        buffer = b""
        while True:
            chunk = proc.stdout.read1(65536) if hasattr(proc.stdout, "read1") else proc.stdout.read(1)
            if not chunk:
                break
            buffer += chunk
            while True:
                cut = -1
                for sep in (b"\n", b"\r"):
                    idx = buffer.find(sep)
                    if idx != -1 and (cut == -1 or idx < cut):
                        cut = idx
                if cut == -1:
                    break
                raw, buffer = buffer[:cut], buffer[cut + 1:]
                self._ingest(raw.decode("utf-8", "replace"))
        if buffer.strip():
            self._ingest(buffer.decode("utf-8", "replace"))
        code = proc.wait()
        with self.lock:
            self.exit_code = code
            self.ended_at = time.time()
            self.phase = "idle"
            self._append(f"[gulp exited with code {code}]", meta=True)
        log(f"gulp exit [{self.project}] code {code}")

    # -- output -------------------------------------------------------------

    def _append(self, text, meta=False, html_text=None):
        self.seq += 1
        self.lines.append({
            "seq": self.seq, "t": time.time(), "text": text,
            "html": html_text if html_text is not None else (f'<i><font color="#8b8b96">{html.escape(text)}</font></i>' if meta else html.escape(text)),
        })

    def _ingest(self, line):
        line = line.rstrip()
        if not line:
            return
        plain = ANSI_RE.sub("", line)
        with self.lock:
            self._append(plain, html_text=ansi_to_html(line))
            stamp = time.time()
            match = GULP_STARTING.search(plain)
            if match:
                task = match.group(1)
                if task not in (self.task, "watch"):
                    self.phase = "compiling"
                    self.cycle_error = False
                    self.warnings = 0
                self.last_event = {"kind": "starting", "task": task, "duration": None, "at": stamp}
                self.error_capture = 0
                return
            match = GULP_FINISHED.search(plain)
            if match:
                task = match.group(1)
                if task not in (self.task, "watch"):
                    self.phase = "idle"
                    if not self.cycle_error:
                        self.error = None
                self.last_event = {"kind": "finished", "task": task, "duration": match.group(2), "at": stamp}
                self.error_capture = 0
                return
            match = GULP_ERRORED.search(plain)
            if match or GULP_ERROR_MARK.search(plain):
                if not self.cycle_error:
                    self.error = {"at": stamp, "task": (self.last_event or {}).get("task"), "lines": []}
                self.cycle_error = True
                self.error_capture = 8
            if self.error_capture > 0 and self.error is not None:
                if len(self.error["lines"]) < 12:
                    self.error["lines"].append(plain.strip())
                self.error_capture -= 1
            elif GULP_WARN_MARK.search(plain):
                self.warnings += 1

    def external_pid(self):
        """A gulp for this gulpfile that is not ours (PhpStorm's Run window)."""
        if not self.gulpfile:
            return None
        needle = self.gulpfile.encode()
        for entry in os.scandir("/proc"):
            if not entry.name.isdigit():
                continue
            try:
                with open(f"/proc/{entry.name}/cmdline", "rb") as fh:
                    cmdline = fh.read()
                if b"gulp" not in cmdline or needle not in cmdline:
                    continue
                with open(f"/proc/{entry.name}/environ", "rb") as fh:
                    if b"DECK_AGENT_GULP=1" in fh.read():
                        continue
                return int(entry.name)
            except OSError:
                continue
        return None

    def snapshot(self, since=0, external_pid=None):
        with self.lock:
            running = self.running
            if running:
                if self.error:
                    state = "error"
                elif self.phase == "compiling":
                    state = "compiling"
                else:
                    state = "watching"
            elif external_pid:
                state = "external"
            elif self.exit_code is not None and not self.stopped_by_user:
                state = "exited"
            elif not self.gulpfile:
                state = "missing"
            else:
                state = "stopped"
            if since <= 0:
                lines = list(self.lines)
            else:
                lines = [l for l in self.lines if l["seq"] > since]
            return {
                "project": {"path": self.project, "name": os.path.basename(self.project),
                            "short": self.project.replace(str(Path.home()), "~", 1)},
                "available": self.gulpfile is not None,
                "gulpfile": self.gulpfile,
                "theme": self.theme,
                "task": self.task,
                "command": self.command,
                "state": state,
                "pid": self.proc.pid if running else None,
                "external_pid": external_pid,
                "started_at": now_iso(self.started_at) if self.started_at else None,
                "ended_at": now_iso(self.ended_at) if self.ended_at else None,
                "exit_code": self.exit_code,
                "last_event": self.last_event,
                "error": self.error,
                "warnings": self.warnings,
                "message": self.message,
                "seq": self.seq,
                "first_seq": self.lines[0]["seq"] if self.lines else 0,
                "lines": lines,
            }

    def clear(self):
        with self.lock:
            self.lines.clear()


class GulpManager:
    def __init__(self, cfg, tracker):
        self.cfg = cfg["gulp"]
        self.tracker = tracker
        self.watchers = {}
        self.lock = threading.Lock()
        self._external_cache = {}
        tracker.listeners.append(self.on_project)

    def watcher(self, project, create=True):
        with self.lock:
            watcher = self.watchers.get(project)
            if watcher is None and create and project:
                watcher = GulpWatcher(self.cfg, project)
                self.watchers[project] = watcher
            return watcher

    def on_project(self, project):
        watcher = self.watcher(project)
        if self.cfg["stop_others"]:
            for other, w in list(self.watchers.items()):
                if other != project and w.running:
                    w.stop()
        if self.cfg["auto_start"] and watcher and watcher.gulpfile and not watcher.running \
                and not watcher.stopped_by_user and not watcher.external_pid():
            threading.Thread(target=watcher.start, daemon=True).start()

    def _external(self, watcher):
        cached = self._external_cache.get(watcher.project)
        if cached and time.time() - cached[0] < 5:
            return cached[1]
        pid = None if watcher.running else watcher.external_pid()
        self._external_cache[watcher.project] = (time.time(), pid)
        return pid

    def snapshot(self, project=None, since=0):
        project = project or self.tracker.snapshot()["path"]
        if not project:
            return {"available": False, "state": "missing", "message": "No PhpStorm project yet", "lines": [], "seq": 0}
        watcher = self.watcher(project)
        data = watcher.snapshot(since, external_pid=self._external(watcher))
        data["others"] = [
            {"path": p, "name": os.path.basename(p), "theme": w.theme, "running": w.running}
            for p, w in self.watchers.items() if p != project and w.running
        ]
        data["settings"] = {"auto_start": self.cfg["auto_start"], "stop_others": self.cfg["stop_others"]}
        return data

    def action(self, verb, project=None):
        project = project or self.tracker.snapshot()["path"]
        if not project:
            return {"ok": False, "error": "No active project"}
        watcher = self.watcher(project)
        if verb == "start":
            watcher.stopped_by_user = False
            ok = watcher.start()
        elif verb == "stop":
            watcher.stop()
            ok = True
        elif verb == "restart":
            watcher.stop()
            watcher.stopped_by_user = False
            ok = watcher.start()
        elif verb == "clear":
            watcher.clear()
            ok = True
        else:
            return {"ok": False, "error": f"unknown action {verb}"}
        return {"ok": ok, "message": watcher.message, "state": watcher.snapshot(since=watcher.seq)["state"]}

    def stop_all(self):
        for watcher in list(self.watchers.values()):
            watcher.stop(by_user=False)


# --------------------------------------------------------------------------
# CircleCI
# --------------------------------------------------------------------------

TERMINAL = {"success", "failed", "error", "canceled", "not_run", "unauthorized"}


def parse_iso(value):
    if not value:
        return None
    try:
        return time.mktime(time.strptime(value[:19], "%Y-%m-%dT%H:%M:%S")) - time.timezone
    except ValueError:
        return None


class CircleCIPoller(threading.Thread):
    def __init__(self, cfg, secrets):
        super().__init__(name="circleci", daemon=True)
        self.cfg = cfg["circleci"]
        self.secrets = secrets
        self.wake = threading.Event()
        self._lock = threading.Lock()
        self.state = {"configured": False, "pipelines": []}
        self._wf_cache = {}   # workflow id → (status, jobs) for finished workflows
        self.latest_repo = None
        self.listeners = []

    def snapshot(self):
        with self._lock:
            return dict(self.state)

    def api(self, path, token):
        request = urllib.request.Request(
            "https://circleci.com/api/v2" + path,
            headers={"Circle-Token": token, "Accept": "application/json", "User-Agent": f"deck-agent/{VERSION}"},
        )
        with urllib.request.urlopen(request, timeout=25) as response:
            return json.load(response)

    def run(self):
        while True:
            interval = self.cfg["interval"]
            try:
                interval = self.collect() or interval
            except urllib.error.HTTPError as exc:
                self._error("CircleCI token rejected (401)" if exc.code == 401 else f"CircleCI HTTP {exc.code}")
            except (urllib.error.URLError, OSError, ValueError) as exc:
                self._error(f"CircleCI unreachable: {exc}")
            except Exception as exc:  # noqa: BLE001
                log(f"circleci: {exc!r}")
                self._error(str(exc))
            self.wake.wait(interval)
            self.wake.clear()

    def _error(self, message):
        log(f"circleci: {message}")
        with self._lock:
            self.state = {**self.state, "configured": True, "error": message, "updated_at": now_iso()}

    def collect(self):
        token = self.secrets.get("CIRCLE_TOKEN")
        org = self.cfg["org_slug"]
        if not token:
            with self._lock:
                self.state = {
                    "configured": False, "org": org, "pipelines": [], "running": 0,
                    "error": f"Add CIRCLE_TOKEN to {CONFIG_DIR / 'secrets.env'} (a personal API token)",
                    "updated_at": now_iso(),
                }
            return 30
        data = self.api(f"/pipeline?org-slug={urllib.parse.quote(org, safe='')}&mine=true", token)
        items = data.get("items", [])[: self.cfg["limit"]]
        pipelines, running = [], 0
        for item in items:
            slug = item.get("project_slug", "")
            parts = slug.split("/")
            vcs_name = {"gh": "github", "bb": "bitbucket"}.get(parts[0], parts[0]) if parts else "github"
            repo = parts[-1] if parts else slug
            org_name = parts[1] if len(parts) > 1 else ""
            number = item.get("number")
            url = f"https://app.circleci.com/pipelines/{vcs_name}/{org_name}/{repo}/{number}"
            vcs = item.get("vcs") or {}
            trigger = item.get("trigger") or {}
            workflows = []
            for wf in self.api(f"/pipeline/{item['id']}/workflow", token).get("items", []):
                status = wf.get("status")
                jobs = None
                cached = self._wf_cache.get(wf["id"])
                if cached and cached[0] == status:
                    jobs = cached[1]
                elif self.cfg["jobs"]:
                    jobs = []
                    for job in self.api(f"/workflow/{wf['id']}/job", token).get("items", []):
                        started, stopped = parse_iso(job.get("started_at")), parse_iso(job.get("stopped_at"))
                        jobs.append({
                            "name": job.get("name"), "status": job.get("status"), "type": job.get("type"),
                            "number": job.get("job_number"),
                            "duration": (stopped or time.time()) - started if started else None,
                            "url": f"{url}/workflows/{wf['id']}/jobs/{job.get('job_number')}" if job.get("job_number") else None,
                        })
                    if status in TERMINAL:
                        self._wf_cache[wf["id"]] = (status, jobs)
                created, stopped = parse_iso(wf.get("created_at")), parse_iso(wf.get("stopped_at"))
                if status in ("running", "on_hold", "failing"):
                    running += 1
                workflows.append({
                    "id": wf["id"], "name": wf.get("name"), "status": status,
                    "created_at": wf.get("created_at"), "stopped_at": wf.get("stopped_at"),
                    "duration": (stopped or time.time()) - created if created else None,
                    "url": f"{url}/workflows/{wf['id']}",
                    "jobs": jobs or [],
                })
            statuses = [w["status"] for w in workflows]
            if any(s in ("running", "failing") for s in statuses):
                status = "running"
            elif "on_hold" in statuses:
                status = "on_hold"
            elif any(s in ("failed", "error", "unauthorized") for s in statuses):
                status = "failed"
            elif statuses and all(s == "success" for s in statuses):
                status = "success"
            elif "canceled" in statuses:
                status = "canceled"
            else:
                status = item.get("state", "pending")
            pipelines.append({
                "id": item["id"], "number": number, "project_slug": slug, "repo": repo, "org": org_name,
                "branch": vcs.get("branch"), "tag": vcs.get("tag"),
                "subject": (vcs.get("commit") or {}).get("subject"),
                "revision": (vcs.get("revision") or "")[:7],
                "actor": (trigger.get("actor") or {}).get("login"),
                "trigger_type": trigger.get("type"),
                "created_at": item.get("created_at"), "created": parse_iso(item.get("created_at")),
                "state": item.get("state"), "status": status, "url": url, "workflows": workflows,
            })
        latest_repo = pipelines[0]["repo"] if pipelines else None
        with self._lock:
            self.state = {
                "configured": True, "org": org, "pipelines": pipelines, "running": running,
                "latest_repo": latest_repo, "error": None, "updated_at": now_iso(),
                "url": f"https://app.circleci.com/pipelines/{org.replace('gh/', 'github/')}?filter=mine",
            }
        if latest_repo != self.latest_repo:
            self.latest_repo = latest_repo
            for listener in self.listeners:
                listener(latest_repo)
        return self.cfg["active_interval"] if running else self.cfg["interval"]


# --------------------------------------------------------------------------
# Pantheon
# --------------------------------------------------------------------------

class SiteMap:
    """repository name / project path → Pantheon site, from .lando.yml files."""

    def __init__(self, roots):
        self.roots = [os.path.expanduser(r) for r in roots]
        self.by_repo = {}
        self.by_path = {}
        self.scanned_at = 0
        self._lock = threading.Lock()

    def scan(self, force=False):
        with self._lock:
            if not force and time.time() - self.scanned_at < 600:
                return
            by_repo, by_path = {}, {}
            for root in self.roots:
                for depth in ("*", "*/*", "*/*/*"):
                    for lando in glob.glob(os.path.join(root, depth, ".lando.yml")):
                        try:
                            text = Path(lando).read_text()
                        except OSError:
                            continue
                        if "recipe: pantheon" not in text and "pantheon" not in text:
                            continue
                        site = re.search(r"^\s*site:\s*['\"]?([A-Za-z0-9._-]+)", text, re.M)
                        site_id = re.search(r"^\s*id:\s*['\"]?([0-9a-f-]{36})", text, re.M)
                        name = re.search(r"^name:\s*['\"]?([^\s'\"]+)", text, re.M)
                        if not site:
                            continue
                        project = os.path.dirname(lando)
                        _, remote, _ = run(["git", "-C", project, "remote", "get-url", "origin"], timeout=5)
                        repo = None
                        if remote.strip():
                            repo = remote.strip().rstrip("/").rsplit("/", 1)[-1].rsplit(":", 1)[-1]
                            repo = repo[:-4] if repo.endswith(".git") else repo
                        entry = {
                            "site": site.group(1), "id": site_id.group(1) if site_id else None,
                            "path": project, "lando": name.group(1) if name else None, "repo": repo,
                        }
                        by_path[project] = entry
                        if repo and repo.lower() not in by_repo:
                            by_repo[repo.lower()] = entry
            self.by_repo, self.by_path, self.scanned_at = by_repo, by_path, time.time()
            log(f"sitemap: {len(by_repo)} repositories → sites")

    def for_repo(self, repo):
        if not repo:
            return None
        self.scan()
        entry = self.by_repo.get(repo.lower())
        if entry is None and time.time() - self.scanned_at > 60:
            self.scan(force=True)
            entry = self.by_repo.get(repo.lower())
        return entry

    def for_path(self, path):
        if not path:
            return None
        self.scan()
        return self.by_path.get(path.rstrip("/"))


class PantheonPoller(threading.Thread):
    ENV_ORDER = {"dev": 0, "test": 1, "live": 2}

    def __init__(self, cfg, secrets, tracker, circleci, sitemap):
        super().__init__(name="pantheon", daemon=True)
        self.cfg = cfg["pantheon"]
        self.secrets = secrets
        self.tracker = tracker
        self.circleci = circleci
        self.sitemap = sitemap
        self.wake = threading.Event()
        self._lock = threading.Lock()
        self.follow = self.cfg["follow"]
        self.pinned = self.cfg["site"]
        self.state = {"configured": False}
        self._login_failed_token = None
        self._orgs = (0, {})          # (fetched_at, id → label)
        self._env_details = {}        # "site.env" → (fetched_at, {php_version, drush_version})
        circleci.listeners.append(lambda _repo: self.follow == "pipeline" and self.wake.set())
        tracker.listeners.append(lambda _path: self.follow == "phpstorm" and self.wake.set())

    def snapshot(self):
        with self._lock:
            return dict(self.state)

    def set_follow(self, follow, site=None):
        if follow in ("pipeline", "phpstorm", "pinned"):
            self.follow = follow
        if site is not None:
            self.pinned = site
        self.wake.set()

    TERMINUS_ENV = {"TERMINUS_HIDE_UPDATE_MESSAGE": "1"}

    @staticmethod
    def _terminus_message(code, out, err):
        # Symfony console wraps the message in a box after "In File.php line N:"
        # and appends the command's usage line; keep just the message.
        lines = [l.strip() for l in (err or out).splitlines() if l.strip()]
        lines = [l for l in lines if not re.match(r"^In \S+ line \d+:$", l) and not re.match(r"^[a-z]+:[a-z-]+ \[", l)]
        return (" ".join(lines[:2]) if lines else f"terminus exit {code}").strip(" []")

    def login(self):
        """`terminus auth:login --machine-token=…` once; the session lands in ~/.terminus.
        Terminus (4.3) does not read TERMINUS_TOKEN for ordinary commands."""
        token = self.secrets.get("TERMINUS_TOKEN")
        if not token or token == self._login_failed_token:
            return False
        code, out, err = run([find_bin("terminus") or "terminus", "auth:login", f"--machine-token={token}", "-n"],
                             timeout=120, env=self.TERMINUS_ENV)
        if code == 0:
            log("terminus: logged in with the machine token from secrets.env")
            self._login_failed_token = None
            return True
        self._login_failed_token = token
        log(f"terminus login failed: {self._terminus_message(code, out, err)}")
        return False

    def terminus(self, args, timeout=90, _retry=True):
        code, out, err = run([find_bin("terminus") or "terminus", *args, "--format=json", "-n"],
                             timeout=timeout, env=self.TERMINUS_ENV)
        if code != 0:
            message = self._terminus_message(code, out, err)
            if _retry and "not logged in" in message.lower() and self.login():
                return self.terminus(args, timeout, _retry=False)
            raise RuntimeError(message)
        try:
            return json.loads(out) if out.strip() else {}
        except ValueError as exc:
            raise RuntimeError(f"terminus returned no JSON: {exc}") from exc

    def organization_label(self, org_id):
        """site:info gives the organisation as a UUID; org:list has the labels."""
        if not org_id:
            return None
        fetched_at, orgs = self._orgs
        if org_id not in orgs and time.time() - fetched_at > 3600:
            try:
                raw = self.terminus(["org:list"])
                items = raw.values() if isinstance(raw, dict) else raw
                orgs = {o.get("id"): (o.get("label") or o.get("name")) for o in items if o.get("id")}
            except RuntimeError as exc:
                log(f"terminus org:list: {exc}")
            self._orgs = (time.time(), orgs)
        return orgs.get(org_id)

    def env_details(self, site_name, env_id):
        """env:list leaves php_version/drush_version empty; env:info fills them (cached 30 min)."""
        key = f"{site_name}.{env_id}"
        fetched_at, details = self._env_details.get(key, (0, None))
        if details is None or time.time() - fetched_at > 1800:
            try:
                info = self.terminus(["env:info", key])
                details = {"php_version": info.get("php_version"), "drush_version": info.get("drush_version")}
            except RuntimeError as exc:
                log(f"terminus env:info {key}: {exc}")
                details = details or {}
            self._env_details[key] = (time.time(), details)
        return details

    def select(self):
        if self.follow == "pinned":
            return {"site": self.pinned, "id": None, "repo": None, "path": None}, {"from": "pinned"}
        if self.follow == "phpstorm":
            path = self.tracker.snapshot()["path"]
            entry = self.sitemap.for_path(path)
            return entry, {"from": "phpstorm", "path": path}
        repo = self.circleci.snapshot().get("latest_repo")
        entry = self.sitemap.for_repo(repo)
        if entry is None and repo:
            entry = {"site": repo, "id": None, "repo": repo, "path": None, "guessed": True}
        return entry, {"from": "pipeline", "repo": repo}

    def run(self):
        while True:
            try:
                self.collect()
            except Exception as exc:  # noqa: BLE001
                log(f"pantheon: {exc!r}")
                with self._lock:
                    self.state = {**self.state, "error": str(exc), "updated_at": now_iso()}
            self.wake.wait(self.cfg["interval"])
            self.wake.clear()

    def collect(self):
        if not find_bin("terminus"):
            with self._lock:
                self.state = {"configured": False, "follow": self.follow, "error": "terminus is not installed", "updated_at": now_iso()}
            return
        entry, source = self.select()
        base = {"follow": self.follow, "pinned": self.pinned, "source": source, "updated_at": now_iso()}
        if not entry or not entry.get("site"):
            with self._lock:
                self.state = {**base, "configured": True, "site": None,
                              "error": {"pipeline": "Waiting for a pipeline of yours",
                                        "phpstorm": "The active project has no Pantheon .lando.yml",
                                        "pinned": "No site pinned"}[self.follow]}
            return
        site_name = entry["site"]
        try:
            info = self.terminus(["site:info", site_name])
            envs_raw = self.terminus(["env:list", site_name])
            workflows_raw = self.terminus(["workflow:list", site_name])
        except RuntimeError as exc:
            message = str(exc)
            if "not logged in" in message.lower():
                message += (f" — add TERMINUS_TOKEN to {CONFIG_DIR / 'secrets.env'}; the agent logs in with it"
                            if not self.secrets.get("TERMINUS_TOKEN") else " — the machine token in secrets.env was rejected")
            with self._lock:
                self.state = {**base, "configured": True, "site": {"name": site_name, "label": site_name}, "error": message}
            return

        site_id = info.get("id") or entry.get("id")
        envs = []
        items = envs_raw.values() if isinstance(envs_raw, dict) else envs_raw
        for env in items:
            env_id = env.get("id")
            domain = env.get("domain") or f"{env_id}-{site_name}.pantheonsite.io"
            details = {}
            if env_id in self.ENV_ORDER and not (env.get("php_version") and env.get("drush_version")):
                details = self.env_details(site_name, env_id)
            envs.append({
                "id": env_id,
                "initialized": str(env.get("initialized", "true")).lower() in ("true", "1", "yes"),
                "locked": str(env.get("locked", "false")).lower() in ("true", "1", "yes"),
                "connection_mode": env.get("connection_mode"),
                "php_version": env.get("php_version") or details.get("php_version"),
                "drush_version": env.get("drush_version") or details.get("drush_version"),
                "created": env.get("created"),
                "domain": domain,
                "url": f"https://{domain}",
                "admin_url": f"https://{domain}/user/login",
                "dashboard_url": f"https://dashboard.pantheon.io/sites/{site_id}#{env_id}/code" if site_id else None,
                "multidev": env_id not in self.ENV_ORDER,
            })
        envs.sort(key=lambda e: (self.ENV_ORDER.get(e["id"], 9), e["id"]))

        workflows = []
        items = workflows_raw.values() if isinstance(workflows_raw, dict) else workflows_raw
        for wf in list(items)[: self.cfg["workflow_limit"]]:
            workflows.append({
                "id": wf.get("id"), "env": wf.get("env"), "workflow": wf.get("workflow"),
                "user": wf.get("user"), "status": wf.get("status"),
                "time": wf.get("time"), "started_at": wf.get("started_at"), "finished_at": wf.get("finished_at"),
            })

        with self._lock:
            self.state = {
                **base, "configured": True, "error": None,
                "site": {
                    "name": site_name, "label": info.get("label") or site_name, "id": site_id,
                    "plan": info.get("plan_name"), "framework": info.get("framework"),
                    "upstream": info.get("upstream"), "organization": info.get("organization"),
                    "organization_name": self.organization_label(info.get("organization")),
                    "region": info.get("region"), "frozen": info.get("frozen"),
                    "dashboard_url": f"https://dashboard.pantheon.io/sites/{site_id}" if site_id else None,
                    "repo": entry.get("repo"), "path": entry.get("path"), "guessed": entry.get("guessed", False),
                },
                "envs": envs, "workflows": workflows,
            }

    def clear_cache(self, env):
        site = self.snapshot().get("site") or {}
        if not site.get("name") or not re.fullmatch(r"[a-z0-9-]+", env or ""):
            return {"ok": False, "error": "No site selected"}
        try:
            self.terminus(["env:clear-cache", f"{site['name']}.{env}"], timeout=180)
        except RuntimeError as exc:
            return {"ok": False, "error": str(exc)}
        self.wake.set()
        return {"ok": True}


# --------------------------------------------------------------------------
# HTTP
# --------------------------------------------------------------------------

class Agent:
    def __init__(self, cfg):
        self.cfg = cfg
        self.secrets = Secrets()
        self.tracker = ProjectTracker(cfg)
        self.git = GitPoller(cfg, self.tracker)
        self.gulp = GulpManager(cfg, self.tracker)
        self.circleci = CircleCIPoller(cfg, self.secrets)
        self.sitemap = SiteMap(cfg["project_roots"])
        self.pantheon = PantheonPoller(cfg, self.secrets, self.tracker, self.circleci, self.sitemap)

    def start(self):
        self.tracker.seed_from_recent_projects()
        for thread in (self.git, self.circleci, self.pantheon):
            thread.start()
        threading.Thread(target=self.sitemap.scan, daemon=True).start()

    def health(self):
        return {
            "ok": True, "version": VERSION, "uptime": int(time.time() - STARTED), "port": self.cfg["port"],
            "project": self.tracker.snapshot(), "secrets": self.secrets.status(),
            "terminus": find_bin("terminus") is not None,
            "node": find_bin(self.cfg["gulp"]["node"] or "node"),
            "phpstorm": find_bin(self.cfg["phpstorm"]["bin"]),
            "path": os.environ.get("PATH"),
            "watchers": [{"path": p, "running": w.running} for p, w in self.gulp.watchers.items()],
        }

    def open_in_ide(self, path, line=None):
        if not path or not os.path.exists(path):
            return {"ok": False, "error": "no such file"}
        ide = find_bin(self.cfg["phpstorm"]["bin"])
        if not ide:
            return {"ok": False, "error": f"{self.cfg['phpstorm']['bin']} not found"}
        cmd = [ide]
        if line:
            cmd += ["--line", str(int(line))]
        cmd.append(path)
        try:
            subprocess.Popen(cmd, start_new_session=True, stdin=subprocess.DEVNULL,
                             stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        except OSError as exc:
            return {"ok": False, "error": str(exc)}
        return {"ok": True}


class Handler(BaseHTTPRequestHandler):
    agent: Agent = None
    server_version = f"deck-agent/{VERSION}"

    def log_message(self, fmt, *args):  # quiet; the journal gets our own log()
        pass

    def _send(self, payload, status=200, content_type="application/json"):
        body = payload if isinstance(payload, bytes) else json.dumps(payload).encode()
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        agent = self.agent
        url = urllib.parse.urlsplit(self.path)
        query = urllib.parse.parse_qs(url.query)
        route = url.path.rstrip("/") or "/"
        if route == "/":
            text = "deck-agent %s\nGET  /health /project /git /gulp?since=N /circleci /pantheon /state\nPOST /project /git/fetch /gulp/{start,stop,restart,clear} /circleci/refresh /pantheon/{refresh,clear-cache,follow} /open\n" % VERSION
            return self._send(text.encode(), content_type="text/plain")
        if route == "/health":
            return self._send(agent.health())
        if route == "/project":
            return self._send(agent.tracker.snapshot())
        if route == "/git":
            return self._send(agent.git.snapshot())
        if route == "/gulp":
            since = int(query.get("since", ["0"])[0] or 0)
            return self._send(agent.gulp.snapshot(query.get("path", [None])[0], since))
        if route == "/circleci":
            return self._send(agent.circleci.snapshot())
        if route == "/pantheon":
            return self._send(agent.pantheon.snapshot())
        if route == "/state":
            return self._send({
                "health": agent.health(), "git": agent.git.snapshot(), "gulp": agent.gulp.snapshot(),
                "circleci": agent.circleci.snapshot(), "pantheon": agent.pantheon.snapshot(),
            })
        self._send({"error": "not found"}, 404)

    def do_POST(self):
        agent = self.agent
        if self.headers.get("X-Deck") is None:
            return self._send({"error": "missing X-Deck header"}, 403)
        length = int(self.headers.get("Content-Length") or 0)
        try:
            body = json.loads(self.rfile.read(length) or b"{}") if length else {}
        except ValueError:
            return self._send({"error": "bad JSON"}, 400)
        route = urllib.parse.urlsplit(self.path).path.rstrip("/")
        if route == "/project":
            path, title = body.get("path"), body.get("title")
            if not path and body.get("caption"):
                path, title = parse_caption(body["caption"])
            return self._send(agent.tracker.report(path, title, active=bool(body.get("active", True))))
        if route == "/git/fetch":
            agent.git.fetch_now.set()
            agent.git.wake.set()
            return self._send({"ok": True})
        if route.startswith("/gulp/"):
            return self._send(agent.gulp.action(route[6:], body.get("path")))
        if route == "/circleci/refresh":
            agent.circleci.wake.set()
            return self._send({"ok": True})
        if route == "/pantheon/refresh":
            agent.sitemap.scan(force=True)
            agent.pantheon.wake.set()
            return self._send({"ok": True})
        if route == "/pantheon/clear-cache":
            return self._send(agent.pantheon.clear_cache(body.get("env")))
        if route == "/pantheon/follow":
            agent.pantheon.set_follow(body.get("follow"), body.get("site"))
            return self._send({"ok": True, "follow": agent.pantheon.follow, "site": agent.pantheon.pinned})
        if route == "/open":
            return self._send(agent.open_in_ide(body.get("path"), body.get("line")))
        self._send({"error": "not found"}, 404)


def adopt_session_environment():
    """Pick up SSH_AUTH_SOCK (git fetch over SSH) from the systemd user manager when
    the unit did not inherit it."""
    wanted = [name for name in ("SSH_AUTH_SOCK", "DBUS_SESSION_BUS_ADDRESS") if not os.environ.get(name)]
    if not wanted:
        return
    code, out, _ = run(["systemctl", "--user", "show-environment"], timeout=10)
    if code != 0:
        return
    for line in out.splitlines():
        key, sep, value = line.partition("=")
        if sep and key in wanted and value:
            os.environ[key] = value
            log(f"adopted {key} from the user manager")


def main():
    parser = argparse.ArgumentParser(description="Deck agent — data hub for the Deck Plasma cards")
    parser.add_argument("--port", type=int, help="override the configured port")
    parser.add_argument("--print-config", action="store_true", help="print the merged configuration and exit")
    args = parser.parse_args()

    cfg = load_config()
    if args.port:
        cfg["port"] = args.port
    if args.print_config:
        print(json.dumps(cfg, indent=2))
        return 0

    adopt_session_environment()
    agent = Agent(cfg)
    Handler.agent = agent
    server = ThreadingHTTPServer(("127.0.0.1", cfg["port"]), Handler)
    server.daemon_threads = True

    def shutdown(signum, _frame):
        log(f"signal {signum}: stopping gulp watchers")
        agent.gulp.stop_all()
        threading.Thread(target=server.shutdown, daemon=True).start()

    signal.signal(signal.SIGTERM, shutdown)
    signal.signal(signal.SIGINT, shutdown)
    # `kill -USR1 <pid>` dumps every thread's stack to the journal.
    faulthandler.register(signal.SIGUSR1, all_threads=True)

    agent.start()
    log(f"deck-agent {VERSION} listening on http://127.0.0.1:{cfg['port']}")
    server.serve_forever()
    return 0


if __name__ == "__main__":
    sys.exit(main())
