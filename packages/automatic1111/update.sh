#!/usr/bin/env nix
#!nix shell --ignore-environment .#cacert .#coreutils .#curl .#jq .#nix-prefetch-github .#bash --command bash

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

OWNER="AUTOMATIC1111"
REPO="stable-diffusion-webui"

## Highest stable release tag (upstream tags v<semver> and marks -RC builds as
## prereleases), or an explicit version passed as $1.
if [ -n "${1:-}" ]; then
    VERSION="${1#v}"
else
    VERSION="$(curl -fsSL "https://api.github.com/repos/$OWNER/$REPO/releases?per_page=100" \
        | jq -r '.[] | select(.draft | not) | select(.prerelease | not) | .tag_name | ltrimstr("v")' \
        | sort --version-sort | tail --lines=1)"
fi

if [ -z "$VERSION" ]; then
    echo "automatic1111: no releases found for $OWNER/$REPO" >&2
    exit 1
fi

if [ -f manifest.json ] && grep -q "\"version\": \"$VERSION\"" manifest.json; then
    echo "automatic1111 $VERSION (already current)"
    exit 0
fi

HASH="$(nix-prefetch-github "$OWNER" "$REPO" --rev "v$VERSION" | jq -r .hash)"

if [ -z "$HASH" ] || [ "$HASH" = "null" ]; then
    echo "automatic1111: nix-prefetch-github returned no hash for v$VERSION" >&2
    exit 1
fi

cat > manifest.json << EOF
{
  "version": "$VERSION",
  "hash": "$HASH"
}
EOF

echo "automatic1111 $VERSION"
