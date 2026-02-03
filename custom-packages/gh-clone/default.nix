{ pkgs }:

pkgs.writeShellApplication {
    name = "gh-clone";
    runtimeInputs = [ pkgs.git pkgs.coreutils ];

    text = ''
# Clean the input: remove 'git@github.com:' or '.git' suffixes
REPO=$(echo "$1" | sed 's|.*github.com[:/]||; s|\.git$||')
CURRENT_DIR=$(pwd)

# Match the new organization directory
WORK_DIR="/home/me/Repository/origin"

if [[ "$CURRENT_DIR" == "$WORK_DIR"* ]]; then
    echo "🏗️  Work directory detected..."
    REMOTE="git@github.com-origin:$REPO.git"
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
