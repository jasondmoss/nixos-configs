{ pkgs, lib, ... }:

#-- gps-signature — Cryptonomicon-style location line for the email signature.
#--
#-- A localhost-only HTTP daemon (127.0.0.1:47121) publishes the machine's
#-- current coordinates; a Violentmonkey userscript running in Wavebox swaps a
#-- "[[GPS]]" placeholder in the Proton Mail signature for that line whenever
#-- the composer opens. See README.md in this directory for the browser side.
#--
#-- Location sources, in order: optional JSON file (phone relay), gpsd (USB
#-- receiver, not enabled here), GeoClue2 (WiFi → beacondb.net; needs the WiFi
#-- radio on for anything better than IP accuracy), IP geolocation fallback.

let
    pythonEnv = pkgs.python3.withPackages (ps: [ ps.pygobject3 ]);

    server = pkgs.writeShellApplication {
        name = "gps-signature-server";
        runtimeInputs = [ pythonEnv ];
        text = ''
exec python3 ${./gps-signature-server.py} "$@"
        '';
    };

    #-- Where a phone relay (GPSLogger / OwnTracks → MEGA) could drop a fix.
    #-- Skipped silently while the file does not exist.
    relayFile = "%h/Mega/System/location.json";
in {
    environment.systemPackages = [ server ];

    #-- GeoClue2 as the primary source. `isSystem = true` lets the daemon start
    #-- a client without a per-user authorization agent (Plasma ships none).
    services.geoclue2 = {
        enable = true;
        enableWifi = true;
        appConfig.gps-signature = {
            isAllowed = true;
            isSystem = true;
            users = [ "1000" ];
        };
    };

    systemd.user.services.gps-signature = {
        description = "Location daemon for the Proton Mail GPS signature";
        after = [ "graphical-session.target" ];
        wantedBy = [ "graphical-session.target" ];
        partOf = [ "graphical-session.target" ];

        environment = {
            GPS_SIGNATURE_PORT = "47121";
            GPS_SIGNATURE_REFRESH = "300";
            GPS_SIGNATURE_FILE = relayFile;
            # Fields: lat lon lat_abs lon_abs lat_hemi lon_hemi acc alt time source place
            GPS_SIGNATURE_FORMAT = "{lat_abs:.5f}° {lat_hemi}, {lon_abs:.5f}° {lon_hemi} (±{acc:.0f} m)";
            #GPS_SIGNATURE_FORMAT = "{lat_abs:.5f}° {lat_hemi}, {lon_abs:.5f}° {lon_hemi} (±{acc:.0f} m) · {time}";
        };

        serviceConfig = {
            Type = "simple";
            ExecStart = "${server}/bin/gps-signature-server";
            Restart = "on-failure";
            RestartSec = "10s";
            # Hardening: loopback listener, outbound HTTPS for the IP fallback only.
            NoNewPrivileges = true;
            PrivateTmp = true;
            ProtectSystem = "strict";
            ProtectHome = "read-only";
        };
    };
}
