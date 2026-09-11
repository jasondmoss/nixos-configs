#!/usr/bin/env nix
#!nix shell --ignore-environment .#cacert .#coreutils .#curl .#gnugrep .#gnused .#gawk .#gnutar .#xz .#patch .#nix .#bash --command bash

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

## Series are pinned, not discovered. gimp-devel's passthru (targetLibDir,
## targetDataDir, majorVersion) and the gimp-3.2 -> gimp-3.0 compat shim in
## ../gimp/default.nix both hardcode "3.2", and the babl/gegl overrides there
## hardcode their lib directories — so a 3.4 / 0.2 / 0.6 jump needs those
## edited by hand, not an unattended manifest bump.
GIMP_SERIES="3.2"
BABL_SERIES="0.1"
GEGL_SERIES="0.4"

GIMP_BASE="https://download.gimp.org/gimp/v$GIMP_SERIES"
BABL_BASE="https://download.gimp.org/pub/babl/$BABL_SERIES"
GEGL_BASE="https://download.gimp.org/pub/gegl/$GEGL_SERIES"

## Highest release tarball in a series, plus its published checksum. The
## "-RC<n>" tarballs sitting in the same directory are excluded by the
## pattern. Prints "<version> <filename> <sri-hash>".
resolve() {
    local base="$1" pkg="$2" series="$3" want="${4:-}"
    local escaped version filename sha

    escaped="${series//./\\.}"

    if [ -n "$want" ]; then
        version="$want"
    else
        version="$(curl -fsSL "$base/" \
            | grep -oE "$pkg-$escaped\.[0-9]+\.tar\.xz" \
            | sed -e "s/^$pkg-//" -e 's/\.tar\.xz$//' \
            | sort --version-sort | tail --lines=1)"
    fi

    if [ -z "$version" ]; then
        echo "gimp: no $pkg tarball in series $series at $base" >&2
        return 1
    fi

    filename="$pkg-$version.tar.xz"
    sha="$(curl -fsSL "$base/SHA256SUMS" \
        | awk -v f="$filename" '$2 == f || $2 == "*" f { print $1; exit }')"

    if [ -z "$sha" ]; then
        echo "gimp: $filename has no entry in $base/SHA256SUMS" >&2
        return 1
    fi

    echo "$version $filename $(nix hash convert --hash-algo sha256 --to sri "$sha")"
}

read -r GIMP_VERSION GIMP_FILE GIMP_SHA < <(resolve "$GIMP_BASE" gimp "$GIMP_SERIES" "${1:-}")
read -r BABL_VERSION BABL_FILE BABL_SHA < <(resolve "$BABL_BASE" babl "$BABL_SERIES" "${2:-}")
read -r GEGL_VERSION GEGL_FILE GEGL_SHA < <(resolve "$GEGL_BASE" gegl "$GEGL_SERIES" "${3:-}")

if [ -f manifest.json ] \
    && grep -q "\"version\": \"$GIMP_VERSION\"" manifest.json \
    && grep -q "\"version\": \"$BABL_VERSION\"" manifest.json \
    && grep -q "\"version\": \"$GEGL_VERSION\"" manifest.json; then
    echo "gimp $GIMP_VERSION (already current; babl $BABL_VERSION, gegl $GEGL_VERSION)"
    exit 0
fi

## This package carries local patches (see default.nix). A bump that
## invalidates them would break the next rebuild — and gimp is a source
## build, so that failure costs a long compile to discover. Dry-run them
## against the new tree first; on failure nxmanifest keeps the current pin.
WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

curl -fsSL "$GIMP_BASE/$GIMP_FILE" | tar -xJ -C "$WORKDIR" --strip-components=1

for PATCHFILE in *.patch; do
    if ! patch -p1 --dry-run --force --directory="$WORKDIR" < "$PATCHFILE" > /dev/null 2>&1; then
        echo "gimp: $PATCHFILE no longer applies to $GIMP_VERSION — keeping the current pin." >&2
        echo "gimp: rebase or drop the patch (check whether upstream fixed it), then re-run." >&2
        exit 1
    fi
done

## babl and gegl live here rather than in ../gimp because they are pinned as
## a set with gimp: ../gimp/default.nix overrides them only to satisfy this
## package, and reads them back out of this manifest.
cat > manifest.json << EOF
{
  "version": "$GIMP_VERSION",
  "filename": "$GIMP_FILE",
  "sha256": "$GIMP_SHA",
  "babl": {
    "version": "$BABL_VERSION",
    "filename": "$BABL_FILE",
    "sha256": "$BABL_SHA"
  },
  "gegl": {
    "version": "$GEGL_VERSION",
    "filename": "$GEGL_FILE",
    "sha256": "$GEGL_SHA"
  }
}
EOF

echo "gimp $GIMP_VERSION (babl $BABL_VERSION, gegl $GEGL_VERSION)"
