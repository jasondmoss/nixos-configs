#!/usr/bin/env nix
#!nix shell --ignore-environment .#cacert .#coreutils .#curl .#jq .#binutils .#gnutar .#xz .#gnugrep .#nix .#bash --command bash

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

## Upstream serves a single rolling "latest" URL with no version in the path
## and publishes no version index, so there is nothing to query: the only way
## to learn the current version is to fetch the .deb and read its control
## file. Prefetching lands it in the store, so the rebuild reuses the
## download and the version below is read back out of that same file.
URL="https://cdn.jopdf.com/download/jopdf/jopdf-linux-amd64_setup.deb"

PREFETCH="$(nix store prefetch-file --json "$URL")"
SHA256="$(jq -r .hash <<< "$PREFETCH")"
STORE_PATH="$(jq -r .storePath <<< "$PREFETCH")"

if [ -z "$SHA256" ] || [ "$SHA256" = "null" ]; then
    echo "jopdf: prefetch of $URL returned no hash" >&2
    exit 1
fi

VERSION="$(ar p "$STORE_PATH" control.tar.xz | tar -xJ -O ./control | grep -oP '^Version:\s*\K.*' | tr -d '[:space:]')"

if [ -z "$VERSION" ]; then
    echo "jopdf: could not read Version from the .deb control file" >&2
    exit 1
fi

## No filename key: the URL is constant, so default.nix hardcodes it.
cat > manifest.json << EOF
{
  "version": "$VERSION",
  "sha256": "$SHA256"
}
EOF

echo "jopdf $VERSION"
