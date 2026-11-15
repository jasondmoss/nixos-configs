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

        #printing = {
        #    enable = true;
        #    browsing = false;
        #    startWhenNeeded = true;
        #};
    };
}

# <> #
