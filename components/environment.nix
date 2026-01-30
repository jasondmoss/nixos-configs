{ config, lib, pkgs, ... }: {
    environment = {
        etc = {
            "1password/custom_allowed_browsers" = {
                text = ''
firefox-nightly
google-chrome-stable
vivaldi-snapshot
wavebox
                '';
                mode = "0755";
            };

            "gitconfig.work".text = ''
[user]
name = "Jason D. Moss (Origin)"
email = "jmoss@originoutside.com";
            '';
        };

        variables = {
            _JAVA_AWT_WM_NONREPARENTING = "1";
            __GL_ALLOW_UNOFFICIAL_PROTOCOL = "1";
            __GL_GSYNC_ALLOWED = "1";
            __GL_SHADER_CACHE = "1";
            __GL_THREADED_OPTIMIZATION = "1";
            __GL_VRR_ALLOWED = "0";
            __GLX_VENDOR_LIBRARY_NAME = "nvidia";
            __NV_DISABLE_EXPLICIT_SYNC = "1";

            DISABLE_QT5_COMPAT = "1";
            EGL_PLATFORM = "wayland";
            ELECTRON_OZONE_PLATFORM_HINT = "wayland";
            GBM_BACKEND = "nvidia-drm";
            GBM_BACKENDS_PATH = "/run/opengl-driver/lib/gbm";
            LIBVA_DRIVER_NAME = "nvidia";
            NIXOS_OZONE_WL = "1";
            NVD_BACKEND = "direct";
            SDL_VIDEODRIVER = "wayland";
            VDPAU_DRIVER = "va_gl";
            WLR_BACKEND = "vulkan";
            WLR_DRM_DEVICES = "/dev/dri/card0";
            WLR_DRM_NO_ATOMIC = "1";
            WLR_NO_HARDWARE_CURSORS = "1";

            QT_AUTO_SCREEN_SCALE_FACTOR = "1";
            QT_ENABLE_HIGHDPI_SCALING="1";

            QT_QPA_PLATFORM = "wayland;xcb";
            QT_QPA_PLATFORMTHEME = lib.mkForce "qt6ct";
            QT_SCALE_FACTOR = "1";
            QT_SCALE_FACTOR_ROUNDING_POLICY = "RoundPreferFloor";
            QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";

            KWIN_TRIPLE_BUFFER = "1";

            PLASMA_USE_QT_SCALING = "1";

            GSK_RENDERER = "ngl";

            GTK_IM_MODULE = lib.mkForce null;
            QT_IM_MODULE = lib.mkForce null;
#            QT_QPA_PLATFORM = lib.mkForce null;

            MOZ_DISABLE_GMP_SANDBOX = "1";
            MOZ_DISABLE_RDD_SANDBOX = "1";
            MOZ_ENABLE_WAYLAND = "1";
            MOZ_X11_EGL = "1";

            SSH_ASKPASS = lib.mkForce "/run/current-system/sw/bin/ksshaskpass";
            SSH_ASKPASS_REQUIRE = "prefer";

            XDG_BIN_HOME = "${config.users.users.me.home}/.local/bin";
            XDG_CACHE_HOME = "${config.users.users.me.home}/.cache";
            XDG_CONFIG_HOME = "${config.users.users.me.home}/.config";
            XDG_DATA_HOME = "${config.users.users.me.home}/.local/share";
            XDG_SESSION_TYPE = "wayland";
            XDG_CURRENT_DESKTOP = "KDE";
            XDG_MENU_PREFIX = "kde-";

            XCURSOR_THEME = "ComixCursors";

            GST_PLUGIN_SYSTEM_PATH_1_0 = lib.makeSearchPathOutput "lib" "lib/gstreamer-1.0" [
                pkgs.gst_all_1.gst-editing-services
                pkgs.gst_all_1.gst-libav
                pkgs.gst_all_1.gst-plugins-bad
                pkgs.gst_all_1.gst-plugins-base
                pkgs.gst_all_1.gst-plugins-good
                pkgs.gst_all_1.gst-plugins-ugly
                pkgs.gst_all_1.gstreamer
            ];

            DEFAULT_BROWSER = "/run/current-system/sw/bin/firefox-nightly";

            GEMINI_API_KEY = "$(${pkgs.coreutils}/bin/cat ${config.users.users.me.home}/.config/gemini/api.key)";
        };
    };
}

# <> #
