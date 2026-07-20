self: pkgs:
let
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
  phpstorm = unstable.jetbrains.phpstorm.overrideAttrs (old: {
    version = "2026.2";
    buildNumber = "262.8665.265";

    src = pkgs.fetchurl {
      url = "https://download.jetbrains.com/webide/PhpStorm-2026.2.tar.gz";
      sha256 = "sha256-gBfmdO+eUtiFnls2W1yYFlfq9NPVfgG8uPDTENUPXqI=";
    };

    # 2026.2 bundles JCEF as an IDE plugin (jcef-plugin) instead of shipping it
    # inside the JBR, so libcef.so's Chromium dependencies must be patched to
    # real store paths. libjawt.so is supplied by the JVM at runtime.
    buildInputs =
      (old.buildInputs or [ ])
      ++ (with unstable; [
        alsa-lib
        at-spi2-atk
        at-spi2-core
        atk
        cairo
        cups
        dbus
        expat
        libdrm
        libgbm
        libx11
        libxcb
        libxcomposite
        libxdamage
        libxext
        libxfixes
        libxkbcommon
        libxrandr
        nspr
        nss
        pango
        udev
      ]);
    autoPatchelfIgnoreMissingDeps = [ "libjawt.so" ];

    # nixpkgs deletes the remote-dev selfcontained libs from $out only after
    # install; auto-patchelf still finds them in the /build source tree during
    # fixup and writes dangling /build RPATHs. Remove them up front so the
    # buildInputs above are used instead.
    postPatch = (old.postPatch or "") + ''
rm -rf plugins/remote-dev-server/selfcontained
    '';
  });
}

# <> #
