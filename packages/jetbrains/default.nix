self: pkgs:
let
  # PhpStorm 2026.1.x requires JBR 25.0.2 b329.72 + JCEF branch 261 for the
  # isRemoteEnabled() API and cef_server binary. nixos-25.11's JBR 21.0.9-b1163.86
  # predates these and causes a NoSuchMethodError crash.
  #
  # <nixpkgs> in NIX_PATH is permanently mapped to the stable nixos channel
  # (nixpkgs=/nix/.../channels/nixos), so we use the explicit path to root's
  # nixpkgs channel (nixpkgs-unstable) which carries JBR 25.0.2.
  unstable = import /nix/var/nix/profiles/per-user/root/channels/nixpkgs {
    config = {
      allowUnfree = true;
      jetbrains.vmopts = ''
-server
-Xms6144m
-Xmx6144m
-Dide.browser.jcef.gpu.disable=true
      '';
    };
    system = pkgs.stdenv.hostPlatform.system;
  };
in
{
  phpstorm = unstable.jetbrains.phpstorm.overrideAttrs (_old: {
    version = "2026.1.2";
    buildNumber = "261.24374.185";

    src = pkgs.fetchurl {
      url = "https://download.jetbrains.com/webide/PhpStorm-2026.1.2.tar.gz";
      sha256 = "sha256-VbXsfKahp1X4AwAC10VghE+ZkxThovnYHHYyvkOTtFc=";
    };
  });
}

# <> #