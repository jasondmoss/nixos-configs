{ config, lib, pkgs, self, ... }: with lib;
let
    versions = builtins.fromJSON(readFile(./versions.json));
    customizeJetbrains = map(pkg:
        (pkg.override ({
            # increase memory
            vmopts = ''
                -server
                -Xms2048m
                -Xmx8192m
            '';
        })).overrideAttrs (attrs:
            # replace version with the one from versions.json
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
                (jetbrains.phpstorm.overrideAttrs (oldAttrs: rec {
                    src = pkgs.fetchurl rec {
                        url = (lib.replaceStrings [ "-no-jbr" ] [ "" ] oldAttrs.src.url);
                    };
                }))
            ]);
    };

    # "sha256": "sha256-Go5HvEnQckGsf6962uu5Hj/xuKjgiC8BRlm7LjXorwA=",

}
