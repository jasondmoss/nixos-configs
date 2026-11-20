#!/usr/bin/env nix
#!nix shell --ignore-environment .#cacert .#coreutils .#curl .#jq .#nix .#bash --command bash

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

API_URL="https://api.github.com/repos/marktext/marktext/releases?per_page=50"

## Emit "<version> <filename> <url> <prerelease>" for every published
## release that carries an x86_64 AppImage (arm64 builds are named
## marktext-linux-arm64-<version>.AppImage, so the exact name skips them).
ENTRIES="$(curl -fsSL "$API_URL" | jq -r '
    .[]
    | select(.draft | not)
    | (.tag_name | ltrimstr("v")) as $version
    | .prerelease as $pre
    | .assets[]
    | select(.name == "marktext-linux-\($version).AppImage")
    | "\($version) \(.name) \(.browser_download_url) \($pre)"
')"

## Requested version (release candidates included), or the highest stable
## one — an unattended nxup never moves onto an -rc.
if [ -n "${1:-}" ]; then
    ENTRY="$(awk -v v="$1" '$1 == v' <<< "$ENTRIES")"
else
    ENTRY="$(awk '$4 == "false"' <<< "$ENTRIES" | sort --version-sort | tail --lines=1)"
fi

if [ -z "$ENTRY" ]; then
    echo "marktext: no matching release in $API_URL" >&2
    exit 1
fi

read -r VERSION FILENAME URL _ <<< "$ENTRY"

## The AppImage is ~150 MB — skip the download when already pinned.
if [ -f manifest.json ] && grep -q "\"version\": \"$VERSION\"" manifest.json; then
    echo "marktext $VERSION (already current)"
    exit 0
fi

## Upstream publishes no checksums, so hash the AppImage itself; prefetching
## puts it in the store, so the rebuild reuses the download.
SHA256="$(nix store prefetch-file --json "$URL" | jq -r .hash)"

if [ -z "$SHA256" ]; then
    echo "marktext: prefetch of $URL returned no hash" >&2
    exit 1
fi

cat > manifest.json << EOF
{
  "version": "$VERSION",
  "filename": "$FILENAME",
  "sha256": "$SHA256"
}
EOF

echo "marktext $VERSION"
