{ config, lib, pkgs, ... }:
let
    # Runtime deps only — no Python package building in Nix
    a1111Deps = with pkgs; [
        python311
        python311Packages.virtualenv
        git
        wget
        ffmpeg
        imagemagick
        stdenv.cc.cc.lib      # libstdc++
        libGL
        libGLU
        glib
    ];

    a1111Launcher = pkgs.writeShellScriptBin "automatic1111" ''
set -e

INSTALL_DIR="$HOME/.local/share/automatic1111"
#REPO_DIR="$INSTALL_DIR/repo"
REPO_DIR="$INSTALL_DIR/sdnext"
VENV_DIR="$INSTALL_DIR/venv"

# First-run: clone and set up
if [ ! -d "$REPO_DIR" ]; then
    echo ">> Cloning AUTOMATIC1111..."
    mkdir -p "$INSTALL_DIR"
    git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui "$REPO_DIR"
fi

# Create venv if missing
if [ ! -d "$VENV_DIR" ]; then
    echo ">> Creating virtualenv..."
    python3.11 -m venv "$VENV_DIR"
    echo ">> Bootstrapping pip/setuptools..."
    "$VENV_DIR/bin/pip" install --upgrade pip wheel "setuptools<71"
    echo ">> Pre-installing build-isolated packages..."
    "$VENV_DIR/bin/pip" install --no-build-isolation \
        https://github.com/openai/CLIP/archive/d50d76daa670286dd6cacf3bcd80b5e4823fc8e1.zip \
        git+https://github.com/CompVis/taming-transformers.git
fi

# Activate and launch
export LD_LIBRARY_PATH=${lib.makeLibraryPath a1111Deps}:${pkgs.cudaPackages.cudatoolkit}/lib:${pkgs.cudaPackages.cudatoolkit}/lib64:/run/opengl-driver/lib:$LD_LIBRARY_PATH
export CUDA_VISIBLE_DEVICES=0

cd "$REPO_DIR"
source "$VENV_DIR/bin/activate"

export GIT_CONFIG_NOSYSTEM=1
export GIT_CONFIG_COUNT=1
export GIT_CONFIG_KEY_0="credential.helper"
export GIT_CONFIG_VALUE_0=""
export STABLE_DIFFUSION_REPO="https://github.com/CompVis/stable-diffusion"

cd "$REPO_DIR"

exec python launch.py \
 --skip-requirements \
 --skip-torch \
 --use-cuda \
 --use-xformers \
 --medvram \
 --api \
 --listen \
 --allowed-paths "$REPO_DIR/html" \
 --data-dir "$INSTALL_DIR/data" \
 "$@"
    '';
in {
    imports = [
        ./packages/ollama
    ];

    environment = {
        variables = {
            CUDA_PATH = "${pkgs.cudaPackages.cudatoolkit}";
        };

        systemPackages = a1111Deps ++ [ a1111Launcher ] ++ (with pkgs; [
            # CUDA.
            cudaPackages.cudatoolkit
            cudaPackages.cudnn

            # AI tools.
            claude-code
            claude-monitor
        ]);
    };

    # Automatic1111 systemd service.
    systemd.user.services.automatic1111 = {
        description = "AUTOMATIC1111 Stable Diffusion WebUI";
        wantedBy = [ "default.target" ];
        after = [ "network.target" ];

        serviceConfig = {
            Type = "simple";
            ExecStart = "${a1111Launcher}/bin/automatic1111";
            WorkingDirectory = "%h/.local/share/automatic1111/repo";
            Restart = "on-failure";
            RestartSec = "10s";
        };
    };

    system.activationScripts.automatic1111Dirs = ''
mkdir -p /home/me/.local/share/automatic1111/{models/Stable-diffusion,models/VAE,outputs,extensions}
chown -R me:users /home/me/.local/share/automatic1111
    '';
}

# <> #
