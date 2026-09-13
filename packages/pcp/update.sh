#!/usr/bin/env nix
#!nix shell --ignore-environment .#cacert .#coreutils .#curl .#jq .#gnutar .#gzip .#patch .#nix-prefetch-github .#bash --command bash

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

OWNER="performancecopilot"
REPO="pcp"

## Upstream tags plain semver (no "v"). Release tarballs are not used — the
## package builds from the git tree via fetchFromGitHub.
if [ -n "${1:-}" ]; then
    VERSION="${1#v}"
else
    VERSION="$(curl -fsSL "https://api.github.com/repos/$OWNER/$REPO/tags?per_page=100" \
        | jq -r '.[].name | select(test("^[0-9]+\\.[0-9]+\\.[0-9]+$"))' \
        | sort --version-sort | tail --lines=1)"
fi

if [ -z "$VERSION" ]; then
    echo "pcp: no release tags found for $OWNER/$REPO" >&2
    exit 1
fi

if [ -f manifest.json ] && grep -q "\"version\": \"$VERSION\"" manifest.json; then
    echo "pcp $VERSION (already current)"
    exit 0
fi

## package.nix applies four vendored NixOS-compat patches. PCP is a large
## source build, so a bump that invalidates them would cost a long compile to
## discover — dry-run them against the new tree first and refuse the bump if
## any no longer applies, leaving nxmanifest to keep the working pin.
WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

curl -fsSL "https://github.com/$OWNER/$REPO/archive/refs/tags/$VERSION.tar.gz" \
    | tar -xz -C "$WORKDIR" --strip-components=1

for PATCHFILE in patches/*.patch; do
    if ! patch -p1 --dry-run --force --directory="$WORKDIR" < "$PATCHFILE" > /dev/null 2>&1; then
        echo "pcp: $PATCHFILE no longer applies to $VERSION — keeping the current pin." >&2
        echo "pcp: rebase or drop the patch (check whether upstream fixed it), then re-run." >&2
        exit 1
    fi
done

HASH="$(nix-prefetch-github "$OWNER" "$REPO" --rev "$VERSION" | jq -r .hash)"

if [ -z "$HASH" ] || [ "$HASH" = "null" ]; then
    echo "pcp: nix-prefetch-github returned no hash for $VERSION" >&2
    exit 1
fi

## Source fetch — fetchFromGitHub takes the NAR hash of the extracted tree,
## so there is no filename to record. The package's own version string is
## read from VERSION.pcp inside the source, not from here.
cat > manifest.json << EOF
{
  "version": "$VERSION",
  "hash": "$HASH"
}
EOF

echo "pcp $VERSION"
