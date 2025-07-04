{
    lib, linkFarm, fetchurl, fetchgit, runCommandLocal, zig,
    name ? "zig-packages"
}:
with builtins;
with lib;
let
    unpackZigArtifact = { name, artifact }:
        runCommandLocal name { nativeBuildInputs = [ zig ]; } ''
hash="$(zig fetch --global-cache-dir "$TMPDIR" ${artifact})"
mv "$TMPDIR/p/$hash" "$out"
chmod 755 "$out"
        '';

    fetchZig = { name, url, hash }:
        let
            artifact = fetchurl { inherit url hash; };
        in
            unpackZigArtifact { inherit name artifact; };

    fetchGitZig = {
            name, url, hash,
            rev ? throw "rev is required, remove and regenerate the zon2json-lock file",
        }:
        let
            parts = splitString "#" url;
            url_base = elemAt parts 0;
            url_without_query = elemAt (splitString "?" url_base) 0;
        in
            fetchgit {
                inherit name rev hash;
                url = url_without_query;
                deepClone = false;
            };

    fetchZigArtifact = { name, url, hash, ... }@args:
        let
            parts = splitString "://" url;
            proto = elemAt parts 0;
            path = elemAt parts 1;
            fetcher = {
                "git+http" = fetchGitZig (
                    args
                    // {
                        url = "http://${path}";
                    }
                );
                "git+https" = fetchGitZig (
                    args
                    // {
                        url = "https://${path}";
                    }
                );
                http = fetchZig {
                    inherit name hash;
                    url = "http://${path}";
                };
                https = fetchZig {
                    inherit name hash;
                    url = "https://${path}";
                };
            };
        in
            fetcher.${proto};
in
linkFarm name [
    {
        name = "122062d301a203d003547b414237229b09a7980095061697349f8bef41be9c30266b";
        path = fetchZigArtifact {
            name = "clap";
            url = "https://github.com/Hejsil/zig-clap/archive/refs/tags/0.9.1.tar.gz";
            hash = "sha256-7qxm/4xb+58MGG+iUzssUtR97OG2dRjAqyS0BAet4HY=";
        };
    }
    {
        name = "12209b971367b4066d40ecad4728e6fdffc4cc4f19356d424c2de57f5b69ac7a619a";
        path = fetchZigArtifact {
            name = "zigini";
            url = "https://github.com/Kawaii-Ash/zigini/archive/0bba97a12582928e097f4074cc746c43351ba4c8.tar.gz";
            hash = "sha256-OdaJ5tqmk2MPwaAbpK4HRD/CcQCN+Cjj8U63BqUcFMs=";
        };
    }
    {
        name = "1220b0979ea9891fa4aeb85748fc42bc4b24039d9c99a4d65d893fb1c83e921efad8";
        path = fetchZigArtifact {
            name = "ini";
            url = "https://github.com/ziglibs/ini/archive/e18d36665905c1e7ba0c1ce3e8780076b33e3002.tar.gz";
            hash = "sha256-RQ6OPJBqqH7PCL+xiI58JT7vnIo6zbwpLWn+byZO5iM=";
        };
    }
]
