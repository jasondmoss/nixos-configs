#!/usr/bin/env python3
"""gps-signature — serve the machine's current location for an email signature.

Cryptonomicon-style: a tiny localhost HTTP server that a browser userscript
queries when the Proton Mail composer opens, replacing a placeholder in the
signature with current coordinates.

Endpoints (bind 127.0.0.1 only, CORS "*" so a userscript may read them):
    /location.txt   formatted signature line (text/plain)
    /location.json  raw fix + metadata (application/json)
    /health         "ok"

Location sources, tried in order until one yields a fix:
    file     JSON file written by something else (e.g. a phone relay synced
             via MEGA): {"lat": .., "lon": .., "accuracy": .., "alt": ..}
             Path from GPS_SIGNATURE_FILE; skipped if unset or missing.
    gpsd     A USB GPS receiver via gpsd on 127.0.0.1:2947 (real GPS).
    geoclue  GeoClue2 over the system D-Bus (WiFi/cell → beacondb, else IP).
    ip       IP geolocation (ipinfo.io, then ip-api.com). City-level only.

Environment:
    GPS_SIGNATURE_PORT      default 47121
    GPS_SIGNATURE_REFRESH   seconds between background refreshes (default 300)
    GPS_SIGNATURE_FILE      optional JSON file source (see above)
    GPS_SIGNATURE_FORMAT    Python format string; fields: lat lon lat_abs lon_abs
                            lat_hemi lon_hemi acc alt time source
    GPS_SIGNATURE_SOURCES   comma list overriding the source order
"""

import json
import os
import socket
import sys
import threading
import time
import urllib.request
from datetime import datetime
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

PORT = int(os.environ.get("GPS_SIGNATURE_PORT", "47121"))
REFRESH = int(os.environ.get("GPS_SIGNATURE_REFRESH", "300"))
FILE_SOURCE = os.environ.get("GPS_SIGNATURE_FILE", "")
FORMAT = os.environ.get(
    "GPS_SIGNATURE_FORMAT",
    "{lat_abs:.5f}° {lat_hemi}, {lon_abs:.5f}° {lon_hemi} (±{acc:.0f} m) · {time}",
)
SOURCES = [
    s.strip()
    for s in os.environ.get("GPS_SIGNATURE_SOURCES", "file,gpsd,geoclue,ip").split(",")
    if s.strip()
]

USER_AGENT = "gps-signature/1.0 (+localhost)"


def log(msg):
    print(f"[gps-signature] {msg}", file=sys.stderr, flush=True)


# --------------------------------------------------------------------------
# Sources. Each returns dict(lat, lon, accuracy, alt, source) or None.
# --------------------------------------------------------------------------

def source_file():
    if not FILE_SOURCE or not os.path.exists(FILE_SOURCE):
        return None
    with open(FILE_SOURCE, encoding="utf-8") as fh:
        data = json.load(fh)
    lat = data.get("lat", data.get("latitude"))
    lon = data.get("lon", data.get("longitude"))
    if lat is None or lon is None:
        return None
    return {
        "lat": float(lat),
        "lon": float(lon),
        "accuracy": float(data.get("accuracy", data.get("acc", 0)) or 0),
        "alt": data.get("alt", data.get("altitude")),
        "source": "file",
    }


def source_gpsd(host="127.0.0.1", port=2947, timeout=8.0):
    try:
        sock = socket.create_connection((host, port), timeout=1.0)
    except OSError:
        return None
    try:
        sock.settimeout(timeout)
        sock.sendall(b'?WATCH={"enable":true,"json":true}\n')
        buf = b""
        deadline = time.monotonic() + timeout
        while time.monotonic() < deadline:
            chunk = sock.recv(4096)
            if not chunk:
                break
            buf += chunk
            while b"\n" in buf:
                line, buf = buf.split(b"\n", 1)
                try:
                    msg = json.loads(line)
                except ValueError:
                    continue
                if msg.get("class") == "TPV" and msg.get("mode", 0) >= 2:
                    if "lat" in msg and "lon" in msg:
                        acc = max(msg.get("eph", 0) or 0, msg.get("epx", 0) or 0, msg.get("epy", 0) or 0)
                        return {
                            "lat": float(msg["lat"]),
                            "lon": float(msg["lon"]),
                            "accuracy": float(acc or 10),
                            "alt": msg.get("altHAE", msg.get("alt")),
                            "source": "gpsd",
                        }
    except OSError as exc:
        log(f"gpsd: {exc}")
    finally:
        sock.close()
    return None


def source_geoclue(timeout=15.0):
    try:
        from gi.repository import Gio, GLib  # type: ignore
    except ImportError:
        return None

    BUS = "org.freedesktop.GeoClue2"
    try:
        bus = Gio.bus_get_sync(Gio.BusType.SYSTEM, None)
        manager = Gio.DBusProxy.new_sync(
            bus, Gio.DBusProxyFlags.NONE, None, BUS,
            "/org/freedesktop/GeoClue2/Manager", f"{BUS}.Manager", None,
        )
        (client_path,) = manager.call_sync("GetClient", None, 0, -1, None).unpack()

        props = Gio.DBusProxy.new_sync(
            bus, Gio.DBusProxyFlags.NONE, None, BUS, client_path,
            "org.freedesktop.DBus.Properties", None,
        )
        props.call_sync("Set", GLib.Variant("(ssv)", (f"{BUS}.Client", "DesktopId",
                        GLib.Variant("s", "gps-signature"))), 0, -1, None)
        # 8 = GCLUE_ACCURACY_LEVEL_EXACT
        props.call_sync("Set", GLib.Variant("(ssv)", (f"{BUS}.Client", "RequestedAccuracyLevel",
                        GLib.Variant("u", 8))), 0, -1, None)

        client = Gio.DBusProxy.new_sync(
            bus, Gio.DBusProxyFlags.NONE, None, BUS, client_path, f"{BUS}.Client", None,
        )
        client.call_sync("Start", None, 0, -1, None)

        loc_path = "/"
        deadline = time.monotonic() + timeout
        try:
            while time.monotonic() < deadline:
                (variant,) = props.call_sync(
                    "Get", GLib.Variant("(ss)", (f"{BUS}.Client", "Location")), 0, -1, None
                ).unpack()
                loc_path = variant
                if loc_path and loc_path != "/":
                    break
                time.sleep(0.5)
            if not loc_path or loc_path == "/":
                log("geoclue: no fix before timeout")
                return None

            loc = Gio.DBusProxy.new_sync(
                bus, Gio.DBusProxyFlags.NONE, None, BUS, loc_path, f"{BUS}.Location", None,
            )

            def prop(name):
                v = loc.get_cached_property(name)
                return v.unpack() if v is not None else None

            alt = prop("Altitude")
            return {
                "lat": float(prop("Latitude")),
                "lon": float(prop("Longitude")),
                "accuracy": float(prop("Accuracy") or 0),
                "alt": None if alt is None or alt <= -1e6 else alt,
                "source": "geoclue",
            }
        finally:
            try:
                client.call_sync("Stop", None, 0, -1, None)
            except Exception:
                pass
    except Exception as exc:  # GLib.Error, DBus not running, access denied ...
        log(f"geoclue: {exc}")
        return None


def _http_json(url, timeout=6.0):
    req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT, "Accept": "application/json"})
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        return json.loads(resp.read().decode("utf-8"))


def source_ip():
    try:
        data = _http_json("https://ipinfo.io/json")
        lat, lon = data["loc"].split(",")
        return {"lat": float(lat), "lon": float(lon), "accuracy": 25000.0, "alt": None,
                "source": "ip", "place": ", ".join(p for p in (data.get("city"), data.get("region")) if p)}
    except Exception as exc:
        log(f"ipinfo: {exc}")
    try:
        data = _http_json("http://ip-api.com/json/?fields=status,lat,lon,city,regionName")
        if data.get("status") == "success":
            return {"lat": float(data["lat"]), "lon": float(data["lon"]), "accuracy": 25000.0,
                    "alt": None, "source": "ip",
                    "place": ", ".join(p for p in (data.get("city"), data.get("regionName")) if p)}
    except Exception as exc:
        log(f"ip-api: {exc}")
    return None


SOURCE_FUNCS = {
    "file": source_file,
    "gpsd": source_gpsd,
    "geoclue": source_geoclue,
    "ip": source_ip,
}


# --------------------------------------------------------------------------
# Cache + formatting.
# --------------------------------------------------------------------------

class Cache:
    def __init__(self):
        self.lock = threading.Lock()
        self.fix = None
        self.updated = 0.0
        self.error = None

    def refresh(self):
        for name in SOURCES:
            func = SOURCE_FUNCS.get(name)
            if func is None:
                log(f"unknown source '{name}'")
                continue
            try:
                fix = func()
            except Exception as exc:
                log(f"{name}: {exc}")
                fix = None
            if fix:
                fix["time"] = datetime.now().astimezone().isoformat(timespec="seconds")
                fix["time_local"] = time.strftime("%Y-%m-%d %H:%M %Z")
                with self.lock:
                    self.fix, self.updated, self.error = fix, time.time(), None
                log(f"fix from {name}: {fix['lat']:.5f}, {fix['lon']:.5f} ±{fix['accuracy']:.0f} m")
                return True
        with self.lock:
            self.error = "no location source produced a fix"
        log(self.error)
        return False

    def snapshot(self):
        with self.lock:
            return self.fix, self.updated, self.error


def format_fix(fix):
    fields = {
        "lat": fix["lat"],
        "lon": fix["lon"],
        "lat_abs": abs(fix["lat"]),
        "lon_abs": abs(fix["lon"]),
        "lat_hemi": "N" if fix["lat"] >= 0 else "S",
        "lon_hemi": "E" if fix["lon"] >= 0 else "W",
        "acc": fix.get("accuracy") or 0.0,
        "alt": fix.get("alt") if fix.get("alt") is not None else float("nan"),
        "time": fix.get("time_local", fix["time"]),
        "source": fix.get("source", "?"),
        "place": fix.get("place", ""),
    }
    return FORMAT.format(**fields)


cache = Cache()


def refresher():
    while True:
        cache.refresh()
        time.sleep(REFRESH)


class Handler(BaseHTTPRequestHandler):
    server_version = "gps-signature/1.0"

    def _send(self, code, body, ctype):
        data = body.encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", f"{ctype}; charset=utf-8")
        self.send_header("Content-Length", str(len(data)))
        self.send_header("Cache-Control", "no-store")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        self.wfile.write(data)

    def do_OPTIONS(self):
        self.send_response(204)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "*")
        self.end_headers()

    def do_GET(self):
        path = self.path.split("?", 1)[0]
        fix, updated, error = cache.snapshot()

        if path == "/health":
            return self._send(200, "ok\n", "text/plain")

        if path == "/refresh":
            cache.refresh()
            fix, updated, error = cache.snapshot()

        if fix is None:
            return self._send(503, json.dumps({"error": error or "no fix yet"}), "application/json")

        if path in ("/", "/location.txt", "/refresh"):
            return self._send(200, format_fix(fix), "text/plain")
        if path == "/location.json":
            body = dict(fix)
            body["formatted"] = format_fix(fix)
            body["age_seconds"] = round(time.time() - updated)
            return self._send(200, json.dumps(body), "application/json")
        return self._send(404, "not found\n", "text/plain")

    def log_message(self, fmt, *args):  # quiet
        pass


def main():
    threading.Thread(target=refresher, name="refresher", daemon=True).start()
    server = ThreadingHTTPServer(("127.0.0.1", PORT), Handler)
    log(f"listening on http://127.0.0.1:{PORT}  sources={','.join(SOURCES)}")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass


if __name__ == "__main__":
    main()
