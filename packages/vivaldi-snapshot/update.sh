#!/usr/bin/env nix
#!nix shell --ignore-environment .#cacert .#coreutils .#curl .#gawk .#bash --command bash

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

BASE_URL="https://repo.vivaldi.com/snapshot/deb"

## Same manifest pattern as packages/claude-code and packages/claude-desktop:
## derive version + checksum from the apt index the Debian/Ubuntu install
## uses. The index also lists vivaldi-stable, hence the Package filter.
entries=$(curl -fsSL "$BASE_URL/dists/stable/main/binary-amd64/Packages" | awk '
    /^Package:/  { pkg  = $2 }
    /^Version:/  { ver  = $2 }
    /^Filename:/ { file = $2 }
    /^SHA256:/   { if (pkg == "vivaldi-snapshot") print ver, file, $2 }
')

## Accepts the version with or without the Debian revision (8.2.x.y[-1]).
VERSION="${1:-$(printf '%s\n' "$entries" | awk '{print $1}' | sort -V | tail -1)}"

line=$(printf '%s\n' "$entries" | awk -v v="$VERSION" '$1 == v || $1 == v "-1" { print; exit }')
if [ -z "$line" ]; then
    echo "vivaldi-snapshot $VERSION not found in apt index" >&2
    exit 1
fi

## The nix version drops the Debian revision suffix.
set -- $line
cat > manifest.json <<JSON
{
  "version": "${1%-*}",
  "filename": "$2",
  "sha256": "$3"
}
JSON

echo "vivaldi-snapshot: ${1%-*}"
