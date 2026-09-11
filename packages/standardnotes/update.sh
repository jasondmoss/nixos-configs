#!/usr/bin/env nix
#!nix shell --ignore-environment .#cacert .#coreutils .#curl .#jq .#nix .#bash --command bash

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

API_URL="https://api.github.com/repos/standardnotes/app/releases?per_page=100"

## The app repo is a monorepo: every component (web, server, mobile, desktop)
## publishes to the same release feed, and most desktop builds are flagged as
## prereleases — so /releases/latest is useless here (it returns whichever
## component shipped last). Filter the feed to desktop tags that actually
## carry an amd64 .deb, and emit "<version> <filename> <url>" for each.
ENTRIES="$(curl -fsSL "$API_URL" | jq -r '
    .[]
    | select(.draft | not)
    | select(.tag_name | startswith("@standardnotes/desktop@"))
    | (.tag_name | ltrimstr("@standardnotes/desktop@")) as $version
    | .assets[]
    | select(.name == "standard-notes-\($version)-linux-amd64.deb")
    | "\($version) \(.name) \(.browser_download_url)"
')"

## Requested version, or the highest published one.
if [ -n "${1:-}" ]; then
    ENTRY="$(awk -v v="$1" '$1 == v' <<< "$ENTRIES")"
else
    ENTRY="$(sort --version-sort <<< "$ENTRIES" | tail --lines=1)"
fi

if [ -z "$ENTRY" ]; then
    echo "standardnotes: no matching desktop release in $API_URL" >&2
    exit 1
fi

read -r VERSION FILENAME URL <<< "$ENTRY"

## The .deb is ~150 MB — skip the download when already pinned.
if [ -f manifest.json ] && grep -q "\"version\": \"$VERSION\"" manifest.json; then
    echo "standardnotes $VERSION (already current)"
    exit 0
fi

## Upstream publishes no checksums, so hash the .deb itself; prefetching
## puts it in the store, so the rebuild reuses the download.
SHA256="$(nix store prefetch-file --json "$URL" | jq -r .hash)"

if [ -z "$SHA256" ]; then
    echo "standardnotes: prefetch of $URL returned no hash" >&2
    exit 1
fi

cat > manifest.json << EOF
{
  "version": "$VERSION",
  "filename": "$FILENAME",
  "sha256": "$SHA256"
}
EOF

echo "standardnotes $VERSION"
