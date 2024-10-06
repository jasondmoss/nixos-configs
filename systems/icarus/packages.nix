{ config, lib, pkgs, ... }: {

    environment = {
        systemPackages = (with pkgs; [

            cups
            kdePackages.print-manager

        ]);
    };

}
