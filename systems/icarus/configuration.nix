{
    services = {
        xserver.dpi = 96;
        printing.enable = false;

        avahi = {
            enable = false;
            # nssmdns4 = true;
            # openFirewall = true;
        };

        # samba = {
        #     enable = true;
        #     securityType = "user";
        #     openFirewall = true;
        # };

        # samba-wsdd = {
        #     enable = true;
        #     openFirewall = true;
        # };
    };
}
