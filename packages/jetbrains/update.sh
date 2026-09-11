#!/usr/bin/env nix
#!nix shell --ignore-environment .#cacert .#coreutils .#curl .#jq .#gnused .#nix .#bash --command bash

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

API_URL="https://data.services.jetbrains.com/products/releases?code=PS&type=release"

## "<version> <build> <tarball-url> <checksum-url>" for every published
## PhpStorm release that ships a Linux tarball.
ENTRIES="$(curl -fsSL "$API_URL" | jq -r '
    .PS[]
    | select(.downloads.linux != null)
    | "\(.version) \(.build) \(.downloads.linux.link) \(.downloads.linux.checksumLink)"
')"

if [ -n "${1:-}" ]; then
    ## Explicit version — the only way to cross into a new feature series.
    ENTRY="$(awk -v v="$1" '$1 == v' <<< "$ENTRIES")"
else
    ## Unattended bumps stay inside the currently pinned feature series
    ## (2026.2.x). default.nix overrides nixpkgs' phpstorm with a JCEF fixup
    ## that is specific to the series, and this script runs from nxup where a
    ## broken IDE build would fail the whole system rebuild. Cross a series
    ## deliberately: ./update.sh 2026.3
    SERIES="$(jq -r '.version | split(".")[0:2] | join(".")' manifest.json)"
    ENTRY="$(awk -v s="$SERIES" '$1 == s || index($1, s ".") == 1' <<< "$ENTRIES" \
        | sort --version-sort | tail --lines=1)"

    NEWEST="$(sort --version-sort <<< "$ENTRIES" | tail --lines=1 | awk '{print $1}')"
    NEWEST_SERIES="$(cut -d. -f1,2 <<< "$NEWEST")"
    if [ "$NEWEST_SERIES" != "$SERIES" ]; then
        echo "phpstorm: note — $NEWEST is out (series $NEWEST_SERIES); staying on $SERIES." >&2
        echo "phpstorm: review the JCEF override in default.nix, then: ./update.sh $NEWEST" >&2
    fi
fi

if [ -z "$ENTRY" ]; then
    echo "phpstorm: no matching release in $API_URL" >&2
    exit 1
fi

read -r VERSION BUILD URL CHECKSUM_URL <<< "$ENTRY"

if [ -f manifest.json ] && grep -q "\"version\": \"$VERSION\"" manifest.json; then
    echo "phpstorm $VERSION (already current)"
    exit 0
fi

## JetBrains publishes a checksum next to each tarball, so the ~1.1 GB
## download is not needed just to re-pin.
SHA256="$(curl -fsSL "$CHECKSUM_URL" | awk '{print $1}')"

if [ -z "$SHA256" ]; then
    echo "phpstorm: no checksum at $CHECKSUM_URL" >&2
    exit 1
fi

cat > manifest.json << EOF
{
  "version": "$VERSION",
  "build": "$BUILD",
  "filename": "$(basename "$URL")",
  "sha256": "$(nix hash convert --hash-algo sha256 --to sri "$SHA256")"
}
EOF

echo "phpstorm $VERSION ($BUILD)"
