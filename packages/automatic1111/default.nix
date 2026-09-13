{ lib, pkgs, fetchFromGitHub, python3Packages, ... }:

let
    python = pkgs.python311;
    pythonEnv = python.withPackages (ps: with ps; [
        torch
        torchvision
        torchaudio
        transformers
        accelerate
        diffusers
        xformers
        pillow
        numpy
        gradio
        safetensors
        omegaconf
        einops
        kornia
        requests
        pyyaml
        psutil
        httpcore
        httpx
        fastapi
        uvicorn
        rich
    ]);

    ## Version + hash come from manifest.json — refresh it with ./update.sh
    ## (same workflow as packages/claude-desktop and packages/vivaldi-snapshot),
    ## then rebuild.
    manifest = lib.importJSON ./manifest.json;

    src = fetchFromGitHub {
        owner  = "AUTOMATIC1111";
        repo   = "stable-diffusion-webui";
        rev    = "v${manifest.version}";
        inherit (manifest) hash;
    };
in pkgs.stdenv.mkDerivation {
    pname   = "automatic1111-webui";

    inherit (manifest) version;

    inherit src;

    buildInputs = [ pythonEnv pkgs.git pkgs.ffmpeg ];
    nativeBuildInputs = [ pkgs.makeWrapper ];

    installPhase = ''
mkdir -p $out/share/automatic1111
cp -r . $out/share/automatic1111/

mkdir -p $out/bin
makeWrapper ${pythonEnv}/bin/python $out/bin/automatic1111 \
 --add-flags "$out/share/automatic1111/launch.py" \
 --add-flags "--skip-python-version-check" \
 --add-flags "--medvram" \
 --add-flags "--xformers" \
 --add-flags "--api" \
 --set PYTHONPATH "$out/share/automatic1111" \
 --set CUDA_VISIBLE_DEVICES "0"
    '';

    meta = {
        description = "AUTOMATIC1111 Stable Diffusion WebUI";
        homepage    = "https://github.com/AUTOMATIC1111/stable-diffusion-webui";
        license     = lib.licenses.lgpl3;
        platforms   = lib.platforms.linux;
    };
}

# <> #
