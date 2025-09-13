{ pkgs, ... }: {

    environment.systemPackages = (with pkgs; [
#        python313Full
    ]) ++ (with pkgs.python313Packages; [
        rapidocr-onnxruntime
        torch
    ]);

}
