#!/usr/bin/env nix
#!nix shell --ignore-environment .#cacert .#coreutils .#curl .#gawk .#git .#gnugrep .#gnused .#jq .#nix .#bash --command bash

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

NAME="ly"
HOST="codeberg.org"
OWNER="fairyglade"
REPO="ly"
BRANCH="master"

## Tracks the $BRANCH branch rather than release tags, so the pin is the
## newest commit on it — or an explicit commit passed as $1. A branch name
## with a fixed hash only holds until the source is garbage-collected; a
## commit stays fetchable.
if [ -n "${1:-}" ]; then
    REV="$1"
else
    REV="$(git ls-remote "https://$HOST/$OWNER/$REPO.git" "refs/heads/$BRANCH" | cut -f1)"
fi

if [ -z "$REV" ]; then
    echo "$NAME: could not resolve the head of $OWNER/$REPO $BRANCH" >&2
    exit 1
fi

if [ -f manifest.json ] && [ "$(jq -r .rev manifest.json)" = "$REV" ]; then
    echo "$NAME $(jq -r .version manifest.json) (already current)"
    exit 0
fi

## Codeberg is a Forgejo instance, so nix-prefetch-github does not apply: the
## commit comes from the Forgejo API (full sha + date), the source hash from
## nix-prefetch-url on the same archive URL fetchFromGitea downloads.
COMMIT="$(curl -fsSL "https://$HOST/api/v1/repos/$OWNER/$REPO/git/commits/$REV?stat=false&verification=false&files=false")"
REV="$(jq -r .sha <<< "$COMMIT")"
DATE="$(jq -r '.commit.committer.date | .[:10]' <<< "$COMMIT")"

if [ -z "$REV" ] || [ "$REV" = "null" ] || [ -z "$DATE" ] || [ "$DATE" = "null" ]; then
    echo "$NAME: $HOST returned no commit/date for ${1:-$BRANCH}" >&2
    exit 1
fi

## --name source: the same store path fetchFromGitea produces, so the build
## that follows does not download it a second time.
PREFETCH="$(nix-prefetch-url --unpack --print-path --name source \
    "https://$HOST/$OWNER/$REPO/archive/$REV.tar.gz" 2>/dev/null)"
HASH="$(nix hash convert --hash-algo sha256 --to sri "$(sed -n 1p <<< "$PREFETCH")")"
SRC="$(sed -n 2p <<< "$PREFETCH")"

if [ -z "$HASH" ] || [ ! -d "$SRC" ]; then
    echo "$NAME: could not fetch the source of $REV" >&2
    exit 1
fi

## Guard 1 — Zig. Ly follows Zig releases closely (0.16 in 2026-04, 0.17 in
## 2026-10), and each needs the matching compiler: take the series from
## build.zig.zon and refuse the bump while nixpkgs has no zig_<series>.
MIN_ZIG="$(grep -oE 'minimum_zig_version *= *"[0-9]+\.[0-9]+' "$SRC/build.zig.zon" 2>/dev/null \
    | grep -oE '[0-9]+\.[0-9]+$' || true)"
if [ -z "$MIN_ZIG" ]; then
    echo "$NAME: no minimum_zig_version in build.zig.zon at ${REV:0:7} — keeping the current pin." >&2
    exit 1
fi
ZIG="${MIN_ZIG/./_}"
if ! nix-instantiate --eval '<nixpkgs>' -A "zig_$ZIG.version" > /dev/null 2>&1; then
    echo "$NAME: ${REV:0:7} needs Zig $MIN_ZIG and nixpkgs has no zig_$ZIG — keeping the current pin." >&2
    exit 1
fi

## Guard 2 — config. Ly reads /etc/ly/config.lua first and falls back to
## config.ini, which is the only file the NixOS module writes. If the
## fallback goes, the greeter would start on built-in defaults (no session
## paths). verify.nix checks the generated ini against the built binary;
## this catches the removal before anything is built.
if ! grep -q 'config\.ini' "$SRC/src/main.zig" 2>/dev/null; then
    echo "$NAME: ${REV:0:7} no longer references config.ini in src/main.zig — keeping the current pin." >&2
    exit 1
fi

## Version = commit date + short rev: nxmanifest compares versions to decide
## whether verify.nix must build the bump, so two commits on one day must
## still differ.
VERSION="$DATE.${REV:0:7}"

## Zig dependency hash: start from the previous one and let Nix say whether
## build.zig.zon's dependencies changed. The derivation name carries the
## version, so every bump refetches the (small) tree: unchanged dependencies
## reproduce the old hash, changed ones fail with the real hash in the
## mismatch message.
PREV_DEPS_HASH="$( { [ -f manifest.json ] && jq -r '.depsHash // empty' manifest.json; } || true)"
DEPS_HASH="${PREV_DEPS_HASH:-sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=}"

write_manifest() {
    cat > manifest.json << MANIFEST
{
  "version": "$VERSION",
  "zig": "$ZIG",
  "rev": "$REV",
  "date": "$DATE",
  "hash": "$HASH",
  "depsHash": "$1"
}
MANIFEST
}

BACKUP="$(mktemp)"
trap 'rm -f "$BACKUP"' EXIT
[ -f manifest.json ] && cp manifest.json "$BACKUP"

write_manifest "$DEPS_HASH"

if ! OUT="$(nix-build --no-out-link verify.nix -A deps 2>&1)"; then
    GOT="$(printf '%s\n' "$OUT" | grep -oE 'got: +sha256-[A-Za-z0-9+/=]+' | awk '{print $2}' | head -1)"
    if [ -z "$GOT" ]; then
        if [ -s "$BACKUP" ]; then cp "$BACKUP" manifest.json; else rm -f manifest.json; fi
        echo "$NAME: Zig dependency fetch failed for ${REV:0:7} — keeping the current pin." >&2
        printf '%s\n' "$OUT" | tail -15 >&2
        exit 1
    fi
    write_manifest "$GOT"
fi

echo "$NAME $VERSION"
