#!/usr/bin/env python3
"""krunner-ollama — KRunner D-Bus runner (org.kde.krunner1) for a local Ollama.

    KRunner ── Match("ai <question>") ──▶ this service ── POST /api/chat ──▶ Ollama
    KRunner ◀── first line of the answer ─┘                (streamed, loopback only)
    Enter / action button ── Run(id, action) ──▶ clipboard and/or Open WebUI

Match() is answered asynchronously: the reply is held until the first line
of the answer is complete (or the whole answer, or the match timeout), so
KRunner shows the gist while the rest keeps streaming in the background.
Run() then waits for the full answer before copying it. A newer query
cancels the in-flight generation unless a Run is waiting on it.

The only network client in this file talks to KRUNNER_OLLAMA_URL, whose
host must resolve to loopback addresses only; anything else is refused at
startup. Ollama is contacted by resolved IP over http.client, which never
consults proxy environment variables. Open WebUI is opened through the
desktop portal (org.freedesktop.portal.OpenURI), i.e. by the browser, not
by this process.

Environment (all optional; the NixOS module sets them):
    KRUNNER_OLLAMA_URL            http://127.0.0.1:11434
    KRUNNER_OLLAMA_MODEL          qwen3:14b
    KRUNNER_OLLAMA_WEBUI_URL      http://localhost:8180  (opened as <url>/?q=<question>)
    KRUNNER_OLLAMA_TRIGGERS       "ai ?"                 space-separated trigger words
    KRUNNER_OLLAMA_ON_ACTIVATE    copy | open | both     what Enter does
    KRUNNER_OLLAMA_SYSTEM_PROMPT  see DEFAULT_SYSTEM_PROMPT
    KRUNNER_OLLAMA_NUM_PREDICT    512                    max answer tokens (-1 = unlimited)
    KRUNNER_OLLAMA_THINK          false | true | ""      "think" request field; "" omits it
    KRUNNER_OLLAMA_DEBOUNCE_MS    700                    idle time after typing before asking
    KRUNNER_OLLAMA_MATCH_TIMEOUT  20                     seconds Match() may wait (KRunner: 25)
    KRUNNER_OLLAMA_RUN_TIMEOUT    90                     seconds Run() waits for an unfinished answer
    KRUNNER_OLLAMA_MIN_PROMPT     3                      shortest question sent to the model
    KRUNNER_OLLAMA_BUS_NAME       org.jdmlabs.krunner.ollama
    KRUNNER_OLLAMA_LOG_PROMPTS    0                      1 = log questions and answers (journal)
"""

import hashlib
import http.client
import ipaddress
import json
import os
import re
import shutil
import socket
import subprocess
import sys
import threading
import time
import urllib.parse
from collections import OrderedDict

import dbus
import dbus.mainloop.glib
import dbus.service
from gi.repository import GLib

IFACE = "org.kde.krunner1"
OBJECT_PATH = "/runner"

PORTAL_NAME = "org.freedesktop.portal.Desktop"
PORTAL_PATH = "/org/freedesktop/portal/desktop"
PORTAL_OPENURI = "org.freedesktop.portal.OpenURI"

HINT_ID = "hint"
ACTIONS = (
    # id, label, icon — order is the order KRunner shows the buttons in
    ("copy", "Copy the full answer to the clipboard", "edit-copy"),
    ("open", "Open in Open WebUI", "internet-web-browser"),
)

DEFAULT_SYSTEM_PROMPT = (
    "You answer questions typed into a desktop launcher. Reply in plain text "
    "without Markdown. The first line must be the essential answer in one "
    "short sentence; add brief details on the following lines only when "
    "they are genuinely useful."
)

CACHE_SIZE = 16
CACHE_TTL = 15 * 60          # seconds a finished answer stays available
TEARDOWN_GRACE = 3           # seconds Run() may still arrive after Teardown()
SOCKET_TIMEOUT = 120         # per-read; a cold 14B model needs seconds to load


def log(msg, *args):
    print(msg % args if args else msg, file=sys.stderr, flush=True)


# --------------------------------------------------------------------------- #
# Configuration
# --------------------------------------------------------------------------- #

class Config:
    def __init__(self, environ):
        def get(name, default):
            value = environ.get("KRUNNER_OLLAMA_" + name)
            return default if value is None or value == "" else value

        def get_int(name, default):
            raw = get(name, None)
            if raw is None:
                return default
            try:
                return int(raw)
            except ValueError:
                log("ignoring KRUNNER_OLLAMA_%s=%r (not an integer)", name, raw)
                return default

        self.ollama_url = get("URL", "http://127.0.0.1:11434")
        self.model = get("MODEL", "qwen3:14b")
        self.webui_url = get("WEBUI_URL", "http://localhost:8180")
        self.triggers = sorted(get("TRIGGERS", "ai ?").split(), key=len, reverse=True)
        self.on_activate = get("ON_ACTIVATE", "copy")
        self.system_prompt = get("SYSTEM_PROMPT", DEFAULT_SYSTEM_PROMPT)
        self.num_predict = get_int("NUM_PREDICT", 512)
        self.debounce_ms = max(0, get_int("DEBOUNCE_MS", 700))
        self.match_timeout = max(1, get_int("MATCH_TIMEOUT", 20))
        self.run_timeout = max(1, get_int("RUN_TIMEOUT", 90))
        self.min_prompt = max(1, get_int("MIN_PROMPT", 3))
        self.bus_name = get("BUS_NAME", "org.jdmlabs.krunner.ollama")
        self.log_prompts = get("LOG_PROMPTS", "0") not in ("0", "false", "no")

        think = environ.get("KRUNNER_OLLAMA_THINK", "false").strip().lower()
        self.think = None if think == "" else think in ("1", "true", "yes")

        if self.on_activate not in ("copy", "open", "both"):
            log("ignoring KRUNNER_OLLAMA_ON_ACTIVATE=%r (copy|open|both)", self.on_activate)
            self.on_activate = "copy"
        if not self.triggers:
            raise SystemExit("KRUNNER_OLLAMA_TRIGGERS must name at least one trigger word")

        # Validated once, used for every request: scheme, Host header, IP, port.
        self.ollama_endpoint = loopback_endpoint(self.ollama_url)

    # What KRunner needs to skip us cheaply: the regex is evaluated in-process
    # by KRunner before any D-Bus call is made.
    @property
    def match_regex(self):
        words = "|".join(re.escape(t) for t in self.triggers)
        return r"^(?:%s)(?:\s|$)" % words

    @property
    def min_letter_count(self):
        return min(len(t) for t in self.triggers)

    def strip_trigger(self, query):
        """Return the question after the trigger word, '' for a bare trigger,
        None when the query does not start with a trigger."""
        for trigger in self.triggers:
            if query.startswith(trigger):
                rest = query[len(trigger):]
                if rest == "" or rest[0].isspace():
                    return rest.strip()
        return None


def loopback_endpoint(url):
    """Resolve the Ollama URL and refuse anything that is not loopback."""
    parts = urllib.parse.urlsplit(url)
    if parts.scheme not in ("http", "https") or not parts.hostname:
        raise SystemExit("KRUNNER_OLLAMA_URL must be an http(s) URL: %r" % url)
    port = parts.port or (443 if parts.scheme == "https" else 80)
    try:
        infos = socket.getaddrinfo(parts.hostname, port, type=socket.SOCK_STREAM)
    except socket.gaierror as exc:
        raise SystemExit("cannot resolve %s: %s" % (parts.hostname, exc))
    addresses = [info[4][0] for info in infos]
    bad = [a for a in addresses if not ipaddress.ip_address(a).is_loopback]
    if bad or not addresses:
        raise SystemExit(
            "refusing KRUNNER_OLLAMA_URL=%s: %s resolves to non-loopback %s"
            % (url, parts.hostname, bad or "nothing"))
    # IPv4 first: IPv6 may be disabled on the host even if ::1 resolves.
    addresses.sort(key=lambda a: ipaddress.ip_address(a).version)
    return parts.scheme, parts.netloc, addresses[0], port


# --------------------------------------------------------------------------- #
# Ollama streaming client (one thread per generation)
# --------------------------------------------------------------------------- #

THINK_RE = re.compile(r"<think>.*?(?:</think>|$)", re.S)


class Generation:
    """One streamed /api/chat completion; state is read from the main loop."""

    def __init__(self, key, prompt, cfg, on_update):
        self.key = key
        self.prompt = prompt
        self.cfg = cfg
        self.on_update = on_update      # called via GLib.idle_add
        self.raw = ""                   # everything the model sent
        self.text = ""                  # raw minus <think> blocks
        self.done = False
        self.error = None
        self.cancelled = False
        self.truncated = False
        self.first_line_ready = False
        self.finished_at = None
        self.run_waiters = 0            # Run() calls waiting → do not cancel
        self._conn = None
        self._cv = threading.Condition()
        self._thread = threading.Thread(target=self._worker, daemon=True,
                                        name="ollama-" + key[:8])

    def start(self):
        self._thread.start()

    def cancel(self):
        with self._cv:
            if self.done or self.cancelled:
                return
            self.cancelled = True
            conn = self._conn
        # Closing the socket makes Ollama abort the generation as well.
        if conn is not None:
            try:
                if conn.sock is not None:
                    conn.sock.shutdown(socket.SHUT_RDWR)
            except OSError:
                pass
            conn.close()

    def wait(self, timeout):
        with self._cv:
            return self._cv.wait_for(lambda: self.done, timeout)

    def _finish(self, error=None):
        with self._cv:
            if self.done:
                return
            self.done = True
            self.error = error
            self.finished_at = time.monotonic()
            self._cv.notify_all()
        GLib.idle_add(self.on_update, self)

    def _request_body(self):
        body = {
            "model": self.cfg.model,
            "stream": True,
            "messages": [
                {"role": "system", "content": self.cfg.system_prompt},
                {"role": "user", "content": self.prompt},
            ],
            "options": {"num_predict": self.cfg.num_predict},
        }
        if self.cfg.think is not None:
            body["think"] = self.cfg.think
        return json.dumps(body)

    def _worker(self):
        scheme, host_header, ip, port = self.cfg.ollama_endpoint
        conn_cls = http.client.HTTPSConnection if scheme == "https" else http.client.HTTPConnection
        conn = conn_cls(ip, port, timeout=SOCKET_TIMEOUT)
        with self._cv:
            if self.cancelled:
                return
            self._conn = conn
        try:
            conn.request("POST", "/api/chat", body=self._request_body(),
                         headers={"Content-Type": "application/json", "Host": host_header})
            response = conn.getresponse()
            if response.status != 200:
                detail = response.read(4096).decode("utf-8", "replace")
                try:
                    detail = json.loads(detail).get("error", detail)
                except ValueError:
                    pass
                self._finish("HTTP %d: %s" % (response.status, detail.strip()))
                return
            while True:
                line = response.readline()
                if not line:
                    break
                line = line.strip()
                if not line:
                    continue
                try:
                    event = json.loads(line)
                except ValueError:
                    continue
                if "error" in event:
                    self._finish(str(event["error"]))
                    return
                chunk = (event.get("message") or {}).get("content") or ""
                if chunk:
                    self._append(chunk)
                if event.get("done"):
                    self.truncated = event.get("done_reason") == "length"
                    break
            self._finish()
        except Exception as exc:  # noqa: BLE001 — reported to KRunner as a match
            if self.cancelled:
                self._finish("cancelled")
            else:
                self._finish("%s: %s" % (type(exc).__name__, exc))
        finally:
            conn.close()

    def _append(self, chunk):
        notify = False
        with self._cv:
            self.raw += chunk
            self.text = THINK_RE.sub("", self.raw)
            if not self.first_line_ready and "\n" in self.text.lstrip():
                self.first_line_ready = True
                notify = True
        if notify:
            GLib.idle_add(self.on_update, self)


MARKDOWN_EDGE = re.compile(r"^(?:[#>*\u2022-]+\s+)+|\s+$")
MARKDOWN_INLINE = re.compile(r"\*\*(.+?)\*\*|`(.+?)`|__(.+?)__")


def first_line(text):
    """First non-empty line, with light Markdown clean-up, single-spaced."""
    for line in text.splitlines():
        line = MARKDOWN_EDGE.sub("", line)
        line = MARKDOWN_INLINE.sub(lambda m: m.group(1) or m.group(2) or m.group(3), line)
        line = " ".join(line.split())
        if line:
            return line
    return ""


# --------------------------------------------------------------------------- #
# The KRunner D-Bus object
# --------------------------------------------------------------------------- #

class PendingMatch:
    __slots__ = ("prompt", "key", "reply", "gen", "debounce_source", "timeout_source")

    def __init__(self, prompt, key, reply):
        self.prompt = prompt
        self.key = key
        self.reply = reply
        self.gen = None
        self.debounce_source = None
        self.timeout_source = None

    def clear_sources(self):
        for attr in ("debounce_source", "timeout_source"):
            source = getattr(self, attr)
            if source is not None:
                GLib.source_remove(source)
                setattr(self, attr, None)


class Runner(dbus.service.Object):
    def __init__(self, cfg, bus):
        name = dbus.service.BusName(cfg.bus_name, bus, do_not_queue=True)
        super().__init__(name, OBJECT_PATH)
        self.cfg = cfg
        self.bus = bus
        self.pending = None             # PendingMatch (at most one)
        self.current = None             # most recent Generation
        self.cache = OrderedDict()      # key -> finished Generation
        self.activation_token = None
        self.in_session = False         # between the first Match and Teardown

    # -- org.kde.krunner1 ---------------------------------------------------

    @dbus.service.method(IFACE, out_signature="a{sv}")
    def Config(self):
        # X-Plasma-API=DBus2: KRunner asks for this on load, so the trigger
        # words configured here win over the fallback in the .desktop file.
        return dbus.Dictionary({
            "MatchRegex": dbus.String(self.cfg.match_regex),
            "MinLetterCount": dbus.Int32(self.cfg.min_letter_count),
        }, signature="sv")

    @dbus.service.method(IFACE, out_signature="a(sss)")
    def Actions(self):
        return [(i, label, icon) for i, label, icon in ACTIONS]

    @dbus.service.method(IFACE, in_signature="s", out_signature="a(sssida{sv})",
                         async_callbacks=("reply", "error"))
    def Match(self, query, reply, error):
        self.in_session = True
        prompt = self.cfg.strip_trigger(str(query))
        if prompt is None:
            reply([])
            return
        # KRunner may issue a new Match before the previous one returned; the
        # older query is stale, answer it with nothing and move on.
        self._drop_pending()
        if len(prompt) < self.cfg.min_prompt:
            reply([self._hint_match()])
            return

        key = hashlib.sha1(("%s\0%s" % (self.cfg.model, prompt)).encode()).hexdigest()
        gen = self._lookup(key)
        if gen is not None and gen.done and gen.error is None:
            reply([self._answer_match(gen)])
            return

        self.pending = PendingMatch(prompt, key, reply)
        if gen is not None and not gen.done:
            self._attach(gen)                       # same question, still streaming
        else:
            self.pending.debounce_source = GLib.timeout_add(
                self.cfg.debounce_ms, self._start_pending)

    @dbus.service.method(IFACE, in_signature="s")
    def SetActivationToken(self, token):
        self.activation_token = str(token)

    @dbus.service.method(IFACE, in_signature="ss")
    def Run(self, match_id, action_id):
        token, self.activation_token = self.activation_token, None
        match_id, action_id = str(match_id), str(action_id)
        if match_id == HINT_ID:
            self._open_webui(None, token)
            return
        gen = self._lookup(match_id)
        if gen is None:
            log("Run: no answer for match %s (expired?)", match_id[:8])
            return
        action = action_id or self.cfg.on_activate
        threading.Thread(target=self._run_action, args=(gen, action, token),
                         daemon=True, name="run-" + match_id[:8]).start()

    @dbus.service.method(IFACE)
    def Teardown(self):
        self._drop_pending()
        self.in_session = False
        # Enter sends Run and Teardown back to back (Run after an async
        # activation-token round trip), so wait before freeing the GPU.
        gen = self.current
        if gen is not None and not gen.done:
            GLib.timeout_add_seconds(TEARDOWN_GRACE, self._cancel_unwanted, gen)

    # -- match bookkeeping --------------------------------------------------

    def _lookup(self, key):
        gen = self.cache.get(key)
        if gen is not None:
            if time.monotonic() - gen.finished_at > CACHE_TTL:
                del self.cache[key]
                gen = None
            else:
                self.cache.move_to_end(key)
        if gen is None and self.current is not None and self.current.key == key:
            gen = self.current
        return gen

    def _remember(self, gen):
        if gen.error is not None or not gen.text.strip():
            return
        self.cache[gen.key] = gen
        self.cache.move_to_end(gen.key)
        while len(self.cache) > CACHE_SIZE:
            self.cache.popitem(last=False)

    def _drop_pending(self, matches=()):
        pending, self.pending = self.pending, None
        if pending is not None:
            pending.clear_sources()
            pending.reply(list(matches))

    def _start_pending(self):
        pending = self.pending
        if pending is None:
            return False
        pending.debounce_source = None
        current = self.current
        if (current is not None and not current.done
                and current.key != pending.key and current.run_waiters == 0):
            current.cancel()
        if self.cfg.log_prompts:
            log("asking %s: %s", self.cfg.model, pending.prompt)
        gen = Generation(pending.key, pending.prompt, self.cfg, self._on_generation_update)
        self.current = gen
        gen.start()
        self._attach(gen)
        return False

    def _attach(self, gen):
        pending = self.pending
        pending.gen = gen
        pending.timeout_source = GLib.timeout_add_seconds(
            self.cfg.match_timeout, self._on_match_timeout)
        if gen.done or gen.first_line_ready:
            self._reply_pending(gen)

    def _on_generation_update(self, gen):
        if gen.done:
            self._remember(gen)
            if gen.error and gen.error != "cancelled":
                log("%s: %s", self.cfg.model, gen.error)
            elif self.cfg.log_prompts and gen.error is None:
                log("answer (%d chars%s): %s", len(gen.text),
                    ", truncated" if gen.truncated else "", first_line(gen.text))
        pending = self.pending
        if pending is not None and pending.gen is gen and (gen.done or gen.first_line_ready):
            self._reply_pending(gen)
        return False

    def _on_match_timeout(self):
        pending = self.pending
        if pending is not None and pending.gen is not None:
            pending.timeout_source = None
            self._reply_pending(pending.gen)
        return False

    def _reply_pending(self, gen):
        pending, self.pending = self.pending, None
        if pending is None:
            return
        pending.clear_sources()
        pending.reply([self._answer_match(gen)])

    def _cancel_unwanted(self, gen):
        # Only the generation that was running at Teardown, and only if no
        # new session or Run has claimed it since.
        if not self.in_session and not gen.done and gen.run_waiters == 0:
            gen.cancel()
        return False

    # -- match construction -------------------------------------------------

    def _properties(self, subtext, actions):
        return dbus.Dictionary({
            "subtext": dbus.String(subtext),
            "category": dbus.String("Ollama"),
            "actions": dbus.Array([dbus.String(a) for a in actions], signature="s"),
        }, signature="sv")

    def _hint_match(self):
        triggers = " or ".join("'%s'" % t for t in self.cfg.triggers)
        return (HINT_ID, "Ask %s" % self.cfg.model, "dialog-question", 100, 0.1,
                self._properties("Type a question after %s. Enter opens Open WebUI." % triggers,
                                 ["open"]))

    def _answer_match(self, gen):
        text = first_line(gen.text)
        icon = "dialog-information"
        if gen.error and gen.error != "cancelled" and not text:
            text, icon = "Ollama: %s" % gen.error, "dialog-error"
        elif gen.error == "cancelled" and not text:
            text, icon = "Cancelled", "dialog-warning"
        elif not text:
            text = "Thinking…" if not gen.done else "(empty answer)"
        elif not gen.done and not gen.first_line_ready:
            text += " …"

        parts = [self.cfg.model]
        if not gen.done:
            parts.append("still answering")
        else:
            lines = len([l for l in gen.text.splitlines() if l.strip()])
            parts.append("%d line%s" % (lines, "" if lines == 1 else "s"))
            if gen.truncated:
                parts.append("cut at %d tokens" % self.cfg.num_predict)
        parts.append({"copy": "Enter copies the answer",
                      "open": "Enter opens it in Open WebUI",
                      "both": "Enter copies and opens in Open WebUI"}[self.cfg.on_activate])
        # Buttons for whatever Enter does not already do.
        buttons = [a for a, _, _ in ACTIONS
                   if self.cfg.on_activate == "both" or a != self.cfg.on_activate]
        return (gen.key, text, icon, 100, 1.0, self._properties(" · ".join(parts), buttons))

    # -- actions ------------------------------------------------------------

    def _run_action(self, gen, action, token):
        if not gen.done:
            gen.run_waiters += 1
            try:
                if not gen.wait(self.cfg.run_timeout):
                    log("Run: answer still incomplete after %ds, using what there is",
                        self.cfg.run_timeout)
            finally:
                gen.run_waiters -= 1
        text = gen.text.strip()
        if not gen.done or gen.error == "cancelled":
            note = "incomplete"
        else:
            note = gen.error
        if note:
            text = (text + "\n\n" if text else "") + "[answer %s]" % note
        if action in ("copy", "both"):
            self._copy(text)
        if action in ("open", "both"):
            self._open_webui(gen.prompt, token)

    def _copy(self, text):
        wl_copy = shutil.which("wl-copy")
        if wl_copy:
            try:
                # wl-copy forks a child that serves the selection; keep our
                # pipes out of it so run() returns as soon as the parent does.
                subprocess.run([wl_copy, "--type", "text/plain;charset=utf-8"],
                               input=text.encode(), check=True, timeout=10,
                               stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                return
            except (OSError, subprocess.SubprocessError) as exc:
                log("wl-copy failed (%s), trying Klipper", exc)

        def via_klipper():
            try:
                klipper = self.bus.get_object("org.kde.klipper", "/klipper")
                klipper.setClipboardContents(text, dbus_interface="org.kde.klipper.klipper")
            except dbus.DBusException as exc:
                log("clipboard unavailable: %s", exc.get_dbus_message())
            return False
        GLib.idle_add(via_klipper)

    def _open_webui(self, prompt, token):
        url = self.cfg.webui_url.rstrip("/") + "/"
        if prompt:
            url += "?" + urllib.parse.urlencode({"q": prompt})

        def via_portal():
            options = dbus.Dictionary(signature="sv")
            if token:
                options["activation_token"] = dbus.String(token)
            try:
                portal = self.bus.get_object(PORTAL_NAME, PORTAL_PATH)
                portal.OpenURI("", url, options, dbus_interface=PORTAL_OPENURI, timeout=30)
            except dbus.DBusException as exc:
                log("portal OpenURI failed (%s), falling back to kde-open", exc.get_dbus_message())
                opener = shutil.which("kde-open") or shutil.which("xdg-open")
                systemd_run = shutil.which("systemd-run")
                if opener and systemd_run:
                    # A transient unit: the browser must not inherit this
                    # service's sandbox (empty $HOME, read-only filesystem).
                    subprocess.Popen([systemd_run, "--user", "--collect", "--quiet",
                                      "--", opener, url],
                                     stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL,
                                     stderr=subprocess.DEVNULL)
                else:
                    log("no way to open %s", url)
            return False
        GLib.idle_add(via_portal)


def main():
    cfg = Config(os.environ)
    dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
    bus = dbus.SessionBus()
    try:
        Runner(cfg, bus)
    except dbus.NameExistsException:
        raise SystemExit("%s is already owned on the session bus" % cfg.bus_name)
    log("krunner-ollama: %s at %s://%s, triggers %s, Enter = %s",
        cfg.model, cfg.ollama_endpoint[0], cfg.ollama_endpoint[1],
        " ".join(cfg.triggers), cfg.on_activate)
    GLib.MainLoop().run()


if __name__ == "__main__":
    main()
