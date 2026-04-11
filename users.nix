{ ... }: {
    users = {
        users = {
            me = {
                isNormalUser = true;
                home = "/home/me";
                createHome = false;
                uid = 1000;
                group = "users";
                description = "Jason D. Moss";

                extraGroups = [
                    "33"
                    "audio"
                    "docker"
                    "mlocate"
                    "mysql"
                    "navidrome"
                    "networkmanager"
                    "power"
                    "video"
                    "wheel"
                    "wwwrun"
                ];

                openssh.authorizedKeys.keys = [
                    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCS88Xk/JyfLE8t332d33f9WMFllZLUX5Ig6lhaFdMBMhw0xwg/c+X2BtT5Xt7zrjwk4WmPaFVawzW8hT78bAWdxM72oEJ4nXf1fD+y9Yv6yr3sDwvVJYOsmoZRdvogRr0l6PuGbiE7iqtakAwAH/5fvDUoKHXmBRia573TZtCBdQOmNQfhOEePD/UhT9xiZ4d5/zvlNopiAU88IwvdXQcnGanS4K1LXLgP3DTblFr4mP0xdsSZo6gtsdu9w+eMfsNwFK7JymKBUj59p4IDFowTSKTodCGjKHKmM9aDeefvtt3nKGip8E06Mg1UuXJXsiWPBB+zDSBi6rGa7mooLLnZdlBAvAgB9fSp3DGS3mnFHj6IsFbuHjFF+n4bxiYFAsTSbXGl6A1DqMzMXsyPqaUwWc7KlntBYEHEDR6YoeX+GWe0/26l+polhzbi1ujq63/sPgtw26MoEKO4g7RHWD3Bz83QLNPTpKjwZiu5QWKbLu6wESfroVNTY5MOl6JM5wE= jmoss@MMGY2002"
                ];
            };
        };
    };
}

# <> #
