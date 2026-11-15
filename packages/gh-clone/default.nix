{ pkgs }:

pkgs.writeShellApplication {
    name = "gh-clone";
    runtimeInputs = [ pkgs.git pkgs.coreutils ];

    text = ''
if [ $# -lt 1 ]; then
    echo "usage: gh-clone <owner/repo | GitHub URL> [target-dir]" >&2
    exit 64
fi

# Clean the input: remove 'git@github.com:' (or a host alias) and '.git'
REPO=$(echo "$1" | sed 's|.*github\.com[^:/]*[:/]||; s|\.git$||')
TARGET="''${2:-}"
CURRENT_DIR=$(pwd)

# Match the new organization directory
WORK_DIR="/home/me/Repository/work/origin"

if [[ "$CURRENT_DIR" == "$WORK_DIR"* ]]; then
    echo "🏗️  Work directory detected..."
    REMOTE="git@github.com-work:$REPO.git"
else
    echo "🏠 Personal directory detected. Using default profile..."
    REMOTE="git@github.com:$REPO.git"
fi

echo "Fetching from: $REMOTE"
if [ -n "$TARGET" ]; then
    git clone "$REMOTE" "$TARGET"
else
    git clone "$REMOTE"
fi
    '';
}

# <> #
