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
    ## Explicit version — pin (or roll back to) a specific release.
    ENTRY="$(awk -v v="$1" '$1 == v' <<< "$ENTRIES")"
else
    ## Newest release, feature-series jumps included (2026.2.x -> 2026.3).
    ## Until 2026-11-05 unattended bumps stayed inside the pinned series,
    ## because the JCEF fixup in default.nix might not fit a new series and a
    ## broken IDE build would fail the whole nxup rebuild. verify.nix now
    ## covers that: nxmanifest builds every bump and restores the previous
    ## manifest.json if the build fails.
    ENTRY="$(sort --version-sort <<< "$ENTRIES" | tail --lines=1)"
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
