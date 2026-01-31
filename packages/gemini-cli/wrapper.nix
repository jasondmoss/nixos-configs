{ pkgs, ... }:

let
    # Reference the base package we built earlier
    base-gemini = pkgs.callPackage ./default.nix {};
in
pkgs.writeShellScriptBin "gemini" ''
KEY_FILE="$HOME/.config/gemini/api.key"

if [ -f "$KEY_FILE" ]; then
    # Inject the key at runtime
    export GEMINI_API_KEY=$(cat "$KEY_FILE")
else
    echo "Warning: Gemini API key file not found at $KEY_FILE"
    echo "Falling back to interactive login..."
fi

# Execute the real gemini binary with all passed arguments ($@)
exec ${base-gemini}/bin/gemini "$@"
''
