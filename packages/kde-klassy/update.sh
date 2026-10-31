#!/usr/bin/env nix
#!nix shell --ignore-environment .#cacert .#coreutils .#git .#jq .#nix .#nix-prefetch-github .#bash --command bash

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

NAME="kde-klassy"
OWNER="paulmcauley"
REPO="klassy"
BRANCH="master"

## Tracks the $BRANCH branch rather than release tags, so the pin is the
## newest commit on it — or an explicit commit passed as $1. A branch name
## with a fixed hash only holds until the source is garbage-collected; a
## commit stays fetchable.
if [ -n "${1:-}" ]; then
    REV="$1"
else
    REV="$(git ls-remote "https://github.com/$OWNER/$REPO.git" "refs/heads/$BRANCH" | cut -f1)"
fi

if [ -z "$REV" ]; then
    echo "$NAME: could not resolve the head of $OWNER/$REPO $BRANCH" >&2
    exit 1
fi

if [ -f manifest.json ] && [ "$(jq -r .rev manifest.json)" = "$REV" ]; then
    echo "$NAME $(jq -r .version manifest.json) (already current)"
    exit 0
fi

PREFETCH="$(nix-prefetch-github --meta "$OWNER" "$REPO" --rev "$REV")"
REV="$(jq -r .src.rev <<< "$PREFETCH")"
HASH="$(jq -r .src.hash <<< "$PREFETCH")"
DATE="$(jq -r .meta.commitDate <<< "$PREFETCH")"

if [ -z "$HASH" ] || [ "$HASH" = "null" ] || [ -z "$DATE" ] || [ "$DATE" = "null" ]; then
    echo "$NAME: nix-prefetch-github returned no hash/date for $REV" >&2
    exit 1
fi

## Version = commit date + short rev: nxmanifest compares versions to decide
## whether verify.nix must build the bump, so two commits on one day must
## still differ.
VERSION="$DATE.${REV:0:7}"

cat > manifest.json << EOF
{
  "version": "$VERSION",
  "rev": "$REV",
  "date": "$DATE",
  "hash": "$HASH"
}
EOF

echo "$NAME $VERSION"
