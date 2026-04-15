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
#        fonts
#        roboto
#        roboto-mono
#        blendmodes
        httpcore
        httpx
        fastapi
        uvicorn
        rich
    ]);

    src = fetchFromGitHub {
        owner  = "AUTOMATIC1111";
        repo   = "stable-diffusion-webui";
        rev    = "v1.10.1";  # Pin to stable release; bump as needed
#        sha256 = lib.fakeSha256;  # Replace after first build: nix-build --show-trace 2>&1 | grep "got:"
        sha256 = "sha256-lY+fZQ9yzFBVX5hrmvaIAm/FaRnsIkB2z4WpcJMmL3w=";  # Replace after first build: nix-build --show-trace 2>&1 | grep "got:"
    };

in pkgs.stdenv.mkDerivation {
    pname   = "automatic1111-webui";
    version = "1.10.1";

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
