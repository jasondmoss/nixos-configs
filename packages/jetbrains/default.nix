self: pkgs:
let
  # Version, build number and checksum come from manifest.json — refresh it
  # with ./update.sh (same workflow as packages/claude-desktop and
  # packages/vivaldi-snapshot), then rebuild. Unattended refreshes stay inside
  # the pinned feature series because the JCEF fixup below is series-specific;
  # see the comment in update.sh.
  manifest = pkgs.lib.importJSON ./manifest.json;
  baseUrl = "https://download.jetbrains.com/webide";

  # <nixpkgs> in NIX_PATH is permanently mapped to the stable nixos channel
  # (nixpkgs=/nix/.../channels/nixos), so we use the explicit path to root's
  # nixpkgs channel (nixpkgs-unstable) which carries JBR 25.0.2.
  unstable = import /nix/var/nix/profiles/per-user/root/channels/nixpkgs {
    config = {
      allowUnfree = true;
      # WLToolkit: run the IDE as a native Wayland client (no XWayland). Declared
      # here so it no longer depends on the per-version custom vmoptions file in
      # ~/.config/JetBrains/PhpStorm<ver>/phpstorm64.vmoptions.
      jetbrains.vmopts = ''
-server
-Xms6144m
-Xmx6144m
-Dawt.toolkit.name=WLToolkit
-Dide.browser.jcef.gpu.disable=true
      '';
    };
    system = pkgs.stdenv.hostPlatform.system;
  };
in
{
  phpstorm = unstable.jetbrains.phpstorm.overrideAttrs (old: {
    inherit (manifest) version;
    buildNumber = manifest.build;

    src = pkgs.fetchurl {
      url = "${baseUrl}/${manifest.filename}";
      inherit (manifest) sha256;
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
