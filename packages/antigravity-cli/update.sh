#!/usr/bin/env nix
#!nix shell --ignore-environment .#cacert .#coreutils .#curl .#jq .#nix .#bash --command bash

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

OWNER="google-antigravity"
REPO="antigravity-cli"
ASSET="agy_cli_linux_x64.tar.gz"

## Highest published release, or an explicit version passed as $1. Upstream
## tags without a leading "v" and ships one asset per platform.
if [ -n "${1:-}" ]; then
    VERSION="$1"
else
    VERSION="$(curl -fsSL "https://api.github.com/repos/$OWNER/$REPO/releases?per_page=100" \
        | jq -r '.[] | select(.draft | not) | .tag_name' \
        | sort --version-sort | tail --lines=1)"
fi

if [ -z "$VERSION" ]; then
    echo "antigravity-cli: no releases found for $OWNER/$REPO" >&2
    exit 1
fi

if [ -f manifest.json ] && grep -q "\"version\": \"$VERSION\"" manifest.json; then
    echo "antigravity-cli $VERSION (already current)"
    exit 0
fi

URL="https://github.com/$OWNER/$REPO/releases/download/$VERSION/$ASSET"

## Upstream publishes no checksums, so hash the tarball itself; prefetching
## puts it in the store, so the rebuild reuses the download.
SHA256="$(nix store prefetch-file --json "$URL" | jq -r .hash)"

if [ -z "$SHA256" ] || [ "$SHA256" = "null" ]; then
    echo "antigravity-cli: prefetch of $URL returned no hash" >&2
    exit 1
fi

cat > manifest.json << EOF
{
  "version": "$VERSION",
  "filename": "$ASSET",
  "sha256": "$SHA256"
}
EOF

echo "antigravity-cli $VERSION"
