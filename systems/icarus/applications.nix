{ config, lib, pkgs, ... }:
{
    # imports = [
    #     ../../custom/nvidia
    # ];

    # nixpkgs = {
    #     config = {
    #         allowUnfreePredicate = pkg: builtins.elem (pkgs.lib.getName pkg) [
    #             "steam"
    #             "steam-run"
    #             "steam-original"
    #         ];
    #     };
    # };

    environment = {
        systemPackages = (with pkgs; [

            cups
            kdePackages.print-manager

        ]);
    };
}
