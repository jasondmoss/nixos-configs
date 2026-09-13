#!/usr/bin/env nix
#!nix shell --ignore-environment .#cacert .#coreutils .#curl .#jq .#nix-prefetch-github .#bash --command bash

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

OWNER="nanogenomic"
REPO="ClaudeCodeBrowser"
BRANCH="main"

## Named repin.sh, NOT update.sh, deliberately: nxmanifest only sweeps package
## directories holding both manifest.json *and* update.sh, so this package is
## skipped by `nxup` entirely and never auto-updates.
##
## The reason is that upstream publishes no tags or releases, so the only
## thing an automatic update could track is whatever is at the tip of main —
## and this package installs a Firefox native-messaging host with <all_urls>
## reach. Bumping it is a decision to make while looking at the diff, not a
## side effect of a system upgrade.
##
## Run with no argument it only reports how far main has moved. Re-pin with:
##     ./repin.sh <rev>            (a full commit sha)
##     ./repin.sh $BRANCH          (explicitly accept current tip)
HEAD_SHA="$(curl -fsSL "https://api.github.com/repos/$OWNER/$REPO/commits/$BRANCH" | jq -r .sha)"
PINNED_REV="$(jq -r '.rev // ""' manifest.json 2>/dev/null || true)"

if [ -z "${1:-}" ]; then
    if [ -z "$PINNED_REV" ]; then
        echo "claude-code-browser: no manifest yet — pin one with ./repin.sh <rev>" >&2
        exit 1
    fi
    if [ "$PINNED_REV" = "$HEAD_SHA" ]; then
        echo "claude-code-browser $(jq -r .version manifest.json) (already current)"
        exit 0
    fi
    echo "claude-code-browser: upstream $BRANCH has moved to ${HEAD_SHA:0:12}; keeping the reviewed pin ${PINNED_REV:0:12}." >&2
    echo "claude-code-browser: review https://github.com/$OWNER/$REPO/compare/$PINNED_REV...$HEAD_SHA" >&2
    echo "claude-code-browser: then re-pin with: ./repin.sh $HEAD_SHA" >&2
    exit 1
fi

## Explicit re-pin. Resolve whatever was given (sha or branch) to a commit.
COMMIT="$(curl -fsSL "https://api.github.com/repos/$OWNER/$REPO/commits/$1")"
REV="$(jq -r .sha <<< "$COMMIT")"
DATE="$(jq -r '.commit.committer.date | split("T")[0]' <<< "$COMMIT")"

if [ -z "$REV" ] || [ "$REV" = "null" ]; then
    echo "claude-code-browser: could not resolve '$1' to a commit" >&2
    exit 1
fi

HASH="$(nix-prefetch-github "$OWNER" "$REPO" --rev "$REV" | jq -r .hash)"

if [ -z "$HASH" ] || [ "$HASH" = "null" ]; then
    echo "claude-code-browser: nix-prefetch-github returned no hash for $REV" >&2
    exit 1
fi

cat > manifest.json << EOF
{
  "version": "1.0.0-unstable-$DATE",
  "rev": "$REV",
  "hash": "$HASH"
}
EOF

echo "claude-code-browser 1.0.0-unstable-$DATE (${REV:0:12})"
