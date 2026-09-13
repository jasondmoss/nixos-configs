#!/usr/bin/env nix
#!nix shell --ignore-environment .#cacert .#coreutils .#curl .#jq .#nix .#bash --command bash

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

FEED="https://proton.me/download/drive/cli/version.json"
PLATFORM="linux/x64"

## Proton publishes a release feed carrying the version and a SHA-512 per
## platform binary, so re-pinning needs no download at all — and the hash we
## record is upstream's own published checksum rather than one we computed
## from whatever bytes we happened to receive.
FEED_JSON="$(curl -fsSL "$FEED")"

if [ -n "${1:-}" ]; then
    RELEASE="$(jq -r --arg v "$1" '.Releases[] | select(.Version == $v)' <<< "$FEED_JSON")"
else
    RELEASE="$(jq -r '[.Releases[] | select(.CategoryName == "Stable")][0]' <<< "$FEED_JSON")"
fi

if [ -z "$RELEASE" ] || [ "$RELEASE" = "null" ]; then
    echo "proton-drive-cli: no matching release in $FEED" >&2
    exit 1
fi

VERSION="$(jq -r .Version <<< "$RELEASE")"
SHA512="$(jq -r --arg p "$PLATFORM" '.Files[] | select(.Platform == $p) | .Sha512CheckSum' <<< "$RELEASE")"

if [ -z "$SHA512" ] || [ "$SHA512" = "null" ]; then
    echo "proton-drive-cli: release $VERSION has no $PLATFORM binary" >&2
    exit 1
fi

cat > manifest.json << EOF
{
  "version": "$VERSION",
  "hash": "$(nix hash convert --hash-algo sha512 --to sri "$SHA512")"
}
EOF

echo "proton-drive-cli $VERSION"
