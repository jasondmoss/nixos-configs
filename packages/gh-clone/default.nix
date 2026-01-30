{ pkgs }:

pkgs.writeShellApplication {
    name = "gh-clone";
    runtimeInputs = [ pkgs.git pkgs.coreutils ];

    text = ''
# Clean the input: remove 'git@github.com:' or '.git' suffixes
RAW_INPUT="$1"
REPO=$(echo "$RAW_INPUT" | sed 's|.*github.com[:/]||; s|\.git$||')

TARGET=''${2:-""}
CURRENT_DIR=$(pwd)
WORK_DIR="/home/me/Repository/origin"

if [[ "$CURRENT_DIR" == "$WORK_DIR"* ]]; then
    echo "🏗️  Work directory detected. Using work profile..."
    # This uses the alias defined in services.nix
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
