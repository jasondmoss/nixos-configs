#!/usr/bin/env bash
# proton-backup — compress a local path, then upload the single archive to
# Proton Drive.
#
# Why this exists: Proton Drive is end-to-end encrypted, so the client encrypts
# file blocks *before* upload. Encrypted data is high-entropy and effectively
# incompressible, and Proton cannot compress server-side (it never sees your
# plaintext). Therefore `proton-drive filesystem upload` stores files ~1:1 —
# Drive space used ≈ original size. Compressing *locally first* (zstd) and
# uploading the resulting archive is the only way to actually save Drive space.
#
# Usage: proton-backup <source-path> <remote-dir> [archive-name]
#   <source-path>  file or directory to back up
#   <remote-dir>   destination folder on Proton Drive (e.g. /backups)
#   [archive-name] optional; defaults to <basename>-<timestamp>.tar.zst
#
# Requires a prior `proton-drive auth login`.

set -euo pipefail

if [ "$#" -lt 2 ]; then
    echo "Usage: proton-backup <source-path> <remote-dir> [archive-name]" >&2
    echo "  Compresses <source-path> to a .tar.zst archive and uploads it to" >&2
    echo "  <remote-dir> on Proton Drive. Run 'proton-drive auth login' first." >&2
    exit 1
fi

src="$1"
remote="$2"
name="${3:-$(basename "$src")-$(date +%Y%m%d-%H%M%S).tar.zst}"

if [ ! -e "$src" ]; then
    echo "proton-backup: source '$src' does not exist" >&2
    exit 1
fi

workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT
archive="$workdir/$name"

echo "proton-backup: compressing '$src' -> $name (zstd -19, multithreaded)…"
tar -I 'zstd -19 -T0' -cf "$archive" -C "$(dirname "$src")" "$(basename "$src")"

size="$(du -h "$archive" | cut -f1)"
echo "proton-backup: archive is $size; uploading to '$remote'…"
proton-drive filesystem upload "$archive" "$remote"

echo "proton-backup: done."
