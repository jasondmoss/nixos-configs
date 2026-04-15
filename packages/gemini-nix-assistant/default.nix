{ pkgs, ... }:

pkgs.writeShellApplication {
    name = "gemini-nix";

    runtimeInputs = with pkgs; [ gemini-cli findutils ];

    text = ''
# The path to your configuration repository
REPO_PATH="$HOME/Repository/system/nixos"

if [ $# -eq 0 ]; then
    echo "Usage: gemini-nix 'your question about the system'"
    exit 1
fi

echo "--- Gathering NixOS Context from $REPO_PATH ---"

# mapfile reads find's output into a bash array
mapfile -t NIX_FILES < <(find "$REPO_PATH" -name "*.nix")

# We use double single-quotes (''${) to escape the $ in Nix
if [ "''${#NIX_FILES[@]}" -eq 0 ]; then
    echo "No .nix files found in $REPO_PATH"
    exit 1
fi

# Pass the user prompt followed by the list of files
# Again, escaping the array expansion
gemini "$*" "''${NIX_FILES[@]}"
    '';
}
