{ lib, stdenvNoCC }:

# Perseverance — local SDDM greeter theme, forked from EliverLara's "Ocean"
# (Plasma 6 variant). See ./README.md for provenance.
#
# The theme is plain QML + assets: nothing to compile, so this is a copy into
# the layout SDDM expects. `services.displayManager.sddm.theme` resolves names
# against ThemeDir = /run/current-system/sw/share/sddm/themes, which the sddm
# module populates via `environment.pathsToLink = [ "/share/sddm" ]` — so this
# package only has to land in environment.systemPackages (it goes through the
# customPkgs attrset in ../../packages.nix) for `theme = "Perseverance"` to
# find it.
#
# src is a local path, so every edit under ./theme changes the derivation hash
# and the next `nixos-rebuild` picks it up. To preview without logging out:
#
#     sddm-greeter-qt6 --test-mode \
#       --theme ~/Repository/system/nixos/configs/packages/sddm-perseverance/theme
#
# That reads the working tree directly — no rebuild needed between iterations.
# The path must be absolute or relative to your cwd, not to this file.
#
# Note that test mode does NOT report QML load errors (verified): a theme with
# a bogus import runs silently. See ./README.md for the qmllint check that
# actually validates imports.
stdenvNoCC.mkDerivation {
    pname = "sddm-perseverance";
    version = "0.1";

    src = ./theme;

    # QML is interpreted by the greeter at runtime; there is nothing to build.
    dontConfigure = true;
    dontBuild = true;

    installPhase = ''
runHook preInstall

mkdir -p $out/share/sddm/themes/Perseverance
cp -r . $out/share/sddm/themes/Perseverance/

runHook postInstall
    '';

    meta = {
        description = "Perseverance SDDM theme (Plasma 6/Qt 6), forked from EliverLara's Ocean";
        homepage = "https://github.com/EliverLara/Juno/tree/ocean/kde/sddm";
        license = with lib.licenses; [ gpl3Plus lgpl2Plus ];
        platforms = lib.platforms.linux;
    };
}

# <> #
