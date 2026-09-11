# gps-signature

Cryptonomicon-style email signature: the current location of **atreides** is
inserted into new Proton Mail messages composed in Wavebox.

## Pieces

| Piece | Where | Role |
|---|---|---|
| `gps-signature-server.py` | systemd user service `gps-signature` | Serves `http://127.0.0.1:47121/location.txt` |
| `default.nix` | NixOS module (imported from `packages.nix`) | Installs the daemon, enables GeoClue2 |
| `proton-gps-signature.user.js` | Violentmonkey in Wavebox | Swaps `[[GPS]]` in the signature when the composer opens |

## Browser setup (one time, manual)

1. In Wavebox, install **Violentmonkey** from the Chrome Web Store.
2. Violentmonkey dashboard → `+` → *Install from URL* / paste the contents of
   `proton-gps-signature.user.js`. Allow the `127.0.0.1` connect prompt on first run.
3. Proton Mail → Settings → Identity and addresses → Signature: put `[[GPS]]`
   where the location line should appear, e.g.

       Jason D. Moss
       [[GPS]]

## Location sources

Tried in order; the first fix wins.

| Source | Accuracy | Notes |
|---|---|---|
| `file` | phone GPS | `~/Mega/System/location.json` `{"lat":..,"lon":..,"accuracy":..}` — not set up yet |
| `gpsd` | true GPS | Needs a USB receiver and `services.gpsd` — not enabled |
| `geoclue` | 50–500 m with WiFi | WiFi radio is **off** by default on atreides (`nmcli radio wifi on`); without it GeoClue falls back to IP |
| `ip` | city | ipinfo.io / ip-api.com fallback |

Override with `GPS_SIGNATURE_SOURCES` / `GPS_SIGNATURE_FORMAT` in `default.nix`.

## Check

```bash
systemctl --user status gps-signature
curl http://127.0.0.1:47121/location.json
curl http://127.0.0.1:47121/refresh
```
