{ pkgs, ... }: {
    hardware = {
        bluetooth = {
            enable = true;

            settings = {
                General = {
                    Experimental = "true";
                };
            };
        };

        keyboard.qmk.enable = true;
    };

    services = {
        smartd = {
            enable = true;
            autodetect = true;
        };

        udev = {
            enable = true;
            packages = [ pkgs.via ];
        };

        # No CUPS: the only printer was cups-pdf, used once (2025-10). Apps
        # print to PDF themselves. To add a real printer, bring back
        # printing = { enable = true; browsing = false; startWhenNeeded = true; };
    };
}

# <> #
