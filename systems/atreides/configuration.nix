{
    services = {
        xserver.dpi = 162;
    };

    programs = {
        steam = {
            enable = true;
            remotePlay.openFirewall = true;
            dedicatedServer.openFirewall = true;
        };
    };
}
