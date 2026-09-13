#!/usr/bin/env nix
#!nix shell --ignore-environment .#cacert .#coreutils .#curl .#jq .#nix .#bash --command bash

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

OWNER="performancecopilot"
REPO="grafana-pcp"

if [ -n "${1:-}" ]; then
    VERSION="${1#v}"
else
    VERSION="$(curl -fsSL "https://api.github.com/repos/$OWNER/$REPO/releases?per_page=100" \
        | jq -r '.[] | select(.draft | not) | select(.prerelease | not) | .tag_name | ltrimstr("v")' \
        | sort --version-sort | tail --lines=1)"
fi

if [ -z "$VERSION" ]; then
    echo "grafana-pcp: no releases found for $OWNER/$REPO" >&2
    exit 1
fi

if [ -f manifest.json ] && grep -q "\"version\": \"$VERSION\"" manifest.json; then
    echo "grafana-pcp $VERSION (already current)"
    exit 0
fi

FILENAME="performancecopilot-pcp-app-$VERSION.zip"
URL="https://github.com/$OWNER/$REPO/releases/download/v$VERSION/$FILENAME"

## default.nix uses fetchzip, whose hash covers the *unpacked* tree, so
## prefetch with --unpack. Upstream publishes only an .md5 beside the zip,
## which nix cannot consume. The zip is Grafana-signed and copied verbatim,
## so the signature is what actually authenticates it (see default.nix).
HASH="$(nix store prefetch-file --unpack --json "$URL" | jq -r .hash)"

if [ -z "$HASH" ] || [ "$HASH" = "null" ]; then
    echo "grafana-pcp: prefetch of $URL returned no hash" >&2
    exit 1
fi

cat > manifest.json << EOF
{
  "version": "$VERSION",
  "filename": "$FILENAME",
  "hash": "$HASH"
}
EOF

echo "grafana-pcp $VERSION"
