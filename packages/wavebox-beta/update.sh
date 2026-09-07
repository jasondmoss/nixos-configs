#!/usr/bin/env nix
#!nix shell --ignore-environment .#cacert .#coreutils .#curl .#gnused .#nix .#bash --command bash

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

BASE_URL="https://download.wavebox.app/beta/linux/tar"

## Requested version, or whatever the beta channel's "latest" redirect
## currently points at (upstream publishes no queryable tarball index).
if [ -n "${1:-}" ]; then
    FILENAME="Wavebox_$1.tar.gz"
else
    FILENAME="$(basename "$(curl -fs -o /dev/null -w '%{redirect_url}' 'https://download.wavebox.app/latest/beta/linux/tar')")"
fi

case "$FILENAME" in
    Wavebox_*.tar.gz) ;;
    *)
        echo "wavebox-beta: unexpected redirect target '$FILENAME'" >&2
        exit 1
        ;;
esac

VERSION="${FILENAME#Wavebox_}"
VERSION="${VERSION%.tar.gz}"

## The tarball is ~300 MB — skip the download when already pinned.
if [ -f manifest.json ] && grep -q "\"version\": \"$VERSION\"" manifest.json; then
    echo "wavebox-beta $VERSION (already current)"
    exit 0
fi

## Upstream ships no checksums, so hash the tarball itself; prefetching
## puts it in the store, so the rebuild reuses the download.
SHA256="$(nix store prefetch-file --json "$BASE_URL/$FILENAME" | sed -n 's/.*"hash":"\([^"]*\)".*/\1/p')"

if [ -z "$SHA256" ]; then
    echo "wavebox-beta: prefetch of $BASE_URL/$FILENAME returned no hash" >&2
    exit 1
fi

cat > manifest.json << EOF
{
  "version": "$VERSION",
  "filename": "$FILENAME",
  "sha256": "$SHA256"
}
EOF

echo "wavebox-beta $VERSION"
