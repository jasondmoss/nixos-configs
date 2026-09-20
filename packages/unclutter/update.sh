#!/usr/bin/env nix
#!nix shell --ignore-environment .#cacert .#coreutils .#curl .#gnugrep .#gnused .#jq .#nix .#nix-prefetch-github .#bash --command bash

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

OWNER="kitze"
REPO="unclutter"
API="https://api.github.com/repos/$OWNER/$REPO"

## Upstream has no releases or tags, so the pin is the newest commit on
## main — or an explicit commit passed as $1.
if [ -n "${1:-}" ]; then
    REV="$1"
else
    REV="$(curl -fsSL "$API/commits/main" | jq -r .sha)"
fi

if [ -z "$REV" ] || [ "$REV" = "null" ]; then
    echo "unclutter: could not resolve the head of $OWNER/$REPO main" >&2
    exit 1
fi

if [ -f manifest.json ] && [ "$(jq -r .rev manifest.json)" = "$REV" ]; then
    echo "unclutter $(jq -r .version manifest.json) (already current)"
    exit 0
fi

DATE="$(curl -fsSL "$API/commits/$REV" | jq -r '.commit.committer.date | .[:10]')"

## Commit count up to REV: with per_page=1 the Link header's rel="last" page
## number is the count. No Link header means a single commit.
COUNT="$(curl -fsSI "$API/commits?sha=$REV&per_page=1" \
    | grep -i '^link:' | grep -oE 'page=[0-9]+>; rel="last"' | grep -oE '[0-9]+' || true)"
COUNT="${COUNT:-1}"

UPSTREAM_VERSION="$(curl -fsSL "https://raw.githubusercontent.com/$OWNER/$REPO/$REV/package.json" | jq -r .version)"
if [ -z "$UPSTREAM_VERSION" ] || [ "$UPSTREAM_VERSION" = "null" ]; then
    echo "unclutter: no version in package.json at $REV" >&2
    exit 1
fi

## Extension version: package.json version + commit count, so it grows with
## every upstream commit (Chrome and Firefox only replace an installed
## extension when the version grows). Each dotted part must stay <= 65535
## for Chrome; a commit count will not get there.
VERSION="$UPSTREAM_VERSION.$COUNT"

HASH="$(nix-prefetch-github "$OWNER" "$REPO" --rev "$REV" | jq -r .hash)"
if [ -z "$HASH" ] || [ "$HASH" = "null" ]; then
    echo "unclutter: nix-prefetch-github returned no hash for $REV" >&2
    exit 1
fi

## node_modules hash: keep the previous one and let Nix tell us if bun.lock
## changed. The deps derivation is fixed-output, so an unchanged lockfile
## resolves to the store path already present (no network, instant); a
## changed one fails with the real hash in the mismatch message.
PREV_DEPS_HASH="$( { [ -f manifest.json ] && jq -r '.depsHash // empty' manifest.json; } || true)"
DEPS_HASH="${PREV_DEPS_HASH:-sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=}"

write_manifest() {
    cat > manifest.json << EOF
{
  "version": "$VERSION",
  "upstreamVersion": "$UPSTREAM_VERSION",
  "rev": "$REV",
  "revCount": $COUNT,
  "date": "$DATE",
  "hash": "$HASH",
  "depsHash": "$1"
}
EOF
}

BACKUP="$(mktemp)"
trap 'rm -f "$BACKUP"' EXIT
[ -f manifest.json ] && cp manifest.json "$BACKUP"

write_manifest "$DEPS_HASH"

if ! OUT="$(nix-build --no-out-link verify.nix -A deps 2>&1)"; then
    GOT="$(printf '%s\n' "$OUT" | grep -oE 'got: +sha256-[A-Za-z0-9+/=]+' | awk '{print $2}' | head -1)"
    if [ -z "$GOT" ]; then
        [ -s "$BACKUP" ] && cp "$BACKUP" manifest.json
        echo "unclutter: node_modules fetch failed for $REV — keeping the current pin." >&2
        printf '%s\n' "$OUT" | tail -15 >&2
        exit 1
    fi
    write_manifest "$GOT"
fi

echo "unclutter $VERSION"
