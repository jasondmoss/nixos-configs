{ pkgs, ... }: {
    environment = {
        systemPackages = (with pkgs; [

            # cups
            # kdePackages.print-manager
            # samba4Full

        ]);
    };
}
