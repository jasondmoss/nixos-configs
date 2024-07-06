{ config, lib, pkgs, self, ... }: with lib;
let
    versions = builtins.fromJSON(readFile(./versions.json));

    customizeJetbrains = map(pkg:
        (pkg.override ({
            # Increase memory.
            vmopts = ''
                -server
                -Xms4096m
                -Xmx4096m
            '';
        })).overrideAttrs (attrs:
            # Replace version with the one from versions.json
            let v = versions.linux.${attrs.pname} or {};
            in if v != {} then rec {
                src = pkgs.fetchurl rec {
                    version = v.version;
                    url = v.url;
                    sha256 = v.sha256;
                };
            } else
                attrs
        ));
in {
    imports = [];

    environment = {
        systemPackages = with pkgs;

        customizeJetbrains ([
            # (jetbrains.gateway.overrideAttrs (oldAttrs: rec {
            #     src = pkgs.fetchurl rec {
            #         url = (lib.replaceStrings [ "-no-jbr" ] [ "" ] oldAttrs.src.url);
            #     };
            # }))

            (jetbrains.phpstorm.overrideAttrs (oldAttrs: rec {
                src = pkgs.fetchurl rec {
                    url = (lib.replaceStrings [ "-no-jbr" ] [ "" ] oldAttrs.src.url);
                };
            }))
        ]);
    };
}
