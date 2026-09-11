#!/usr/bin/env nix
#!nix shell --ignore-environment .#cacert .#coreutils .#curl .#jq .#gnutar .#gzip .#patch .#nix-prefetch-github .#bash --command bash

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

OWNER="isac322"
REPO="krema"

## Highest published release tag (upstream tags every release v<semver>),
## or an explicit version passed as $1.
if [ -n "${1:-}" ]; then
    VERSION="${1#v}"
else
    VERSION="$(curl -fsSL "https://api.github.com/repos/$OWNER/$REPO/releases?per_page=100" \
        | jq -r '.[] | select(.draft | not) | .tag_name | ltrimstr("v")' \
        | sort --version-sort | tail --lines=1)"
fi

if [ -z "$VERSION" ]; then
    echo "krema: no release tags found for $OWNER/$REPO" >&2
    exit 1
fi

if [ -f manifest.json ] && grep -q "\"version\": \"$VERSION\"" manifest.json; then
    echo "krema $VERSION (already current)"
    exit 0
fi

## This package carries local patches for upstream bugs (see default.nix).
## A version bump that silently invalidates them would break the next
## rebuild, so dry-run every patch against the new tree first and refuse the
## bump if any no longer applies — nxmanifest then keeps the current pin and
## warns, leaving the rebuild working.
WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

curl -fsSL "https://github.com/$OWNER/$REPO/archive/refs/tags/v$VERSION.tar.gz" \
    | tar -xz -C "$WORKDIR" --strip-components=1

for PATCHFILE in patches/*.patch; do
    if ! patch -p1 --dry-run --force --directory="$WORKDIR" < "$PATCHFILE" > /dev/null 2>&1; then
        echo "krema: $PATCHFILE no longer applies to v$VERSION — keeping the current pin." >&2
        echo "krema: rebase or drop the patch (check whether upstream fixed it), then re-run." >&2
        exit 1
    fi
done

HASH="$(nix-prefetch-github "$OWNER" "$REPO" --rev "v$VERSION" | jq -r .hash)"

if [ -z "$HASH" ] || [ "$HASH" = "null" ]; then
    echo "krema: nix-prefetch-github returned no hash for v$VERSION" >&2
    exit 1
fi

## Source fetch, not a binary download — fetchFromGitHub takes the NAR hash
## of the extracted tree, so there is no filename to record.
cat > manifest.json << EOF
{
  "version": "$VERSION",
  "hash": "$HASH"
}
EOF

echo "krema $VERSION"
