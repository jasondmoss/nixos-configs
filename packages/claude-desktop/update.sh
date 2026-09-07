#!/usr/bin/env nix
#!nix shell --ignore-environment .#cacert .#coreutils .#curl .#gawk .#nix .#bash --command bash

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

BASE_URL="https://downloads.claude.ai/claude-desktop/apt/stable"

## "<version> <filename> <sha256-hex>" for every claude-desktop entry in the
## apt index — the same metadata apt itself installs from.
ENTRIES="$(curl -fsSL "$BASE_URL/dists/stable/main/binary-amd64/Packages" | awk -v RS= -v FS='\n' '
    /(^|\n)Package: claude-desktop(\n|$)/ {
        version = ""; filename = ""; sha256 = ""
        for (i = 1; i <= NF; i++) {
            if ($i ~ /^Version: /)  version  = substr($i, 10)
            if ($i ~ /^Filename: /) filename = substr($i, 11)
            if ($i ~ /^SHA256: /)   sha256   = substr($i, 9)
        }
        if (version != "" && filename != "" && sha256 != "") print version, filename, sha256
    }')"

## Requested version, or the highest published one.
if [ -n "${1:-}" ]; then
    ENTRY="$(awk -v v="$1" '$1 == v' <<< "$ENTRIES")"
else
    ENTRY="$(sort --version-sort <<< "$ENTRIES" | tail --lines=1)"
fi

if [ -z "$ENTRY" ]; then
    echo "claude-desktop: no matching version in $BASE_URL" >&2
    exit 1
fi

read -r VERSION FILENAME SHA256 <<< "$ENTRY"

cat > manifest.json << EOF
{
  "version": "$VERSION",
  "filename": "$FILENAME",
  "sha256": "$(nix hash convert --hash-algo sha256 --to sri "$SHA256")"
}
EOF

echo "claude-desktop $VERSION"
