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

			"gitconfig.personal".text = ''
[user]
	name = "Jason D. Moss"
	email = "jason@jdmlabs.com"
			'';

            "gitconfig.gitlab".text = ''
[user]
    name = "Jason Moss"
    email = "work@jdmlabs.com"
            '';
		};

		variables = {
			# Backend logic
			GBM_BACKEND = "nvidia-drm";
			__GLX_VENDOR_LIBRARY_NAME = "nvidia";

			# Performance & Protocol
			__GL_THREADED_OPTIMIZATION = "1";
			__GL_SHADER_CACHE = "1";

			# Tooling & XDG
			XDG_BIN_HOME = "$HOME/.local/bin";
			XDG_CACHE_HOME = "$HOME/.cache";
			XDG_CONFIG_HOME = "$HOME/.config";
			XDG_DATA_HOME = "$HOME/.local/share";

			SSH_ASKPASS = lib.mkForce "ksshaskpass";
			SSH_ASKPASS_REQUIRE = "prefer";
		};

		sessionVariables = {
		    QT_QPA_PLATFORM = "wayland;xcb";
		    # Fixes flickering in WebEngine apps on NVIDIA
            QT_QUICK_BACKEND = "software"; # Fallback if hardware fails, but usually "rhi" is default.
            # Electron/Wayland Overrides (Still needed for some apps)
            NIXOS_OZONE_WL = "1";
            # Validates hardware video acceleration
            LIBVA_DRIVER_NAME = "nvidia";
            # Required for Firefox/Chromium/WebEngine hardware decode
            NVD_BACKEND = "direct";

		    KDE_SESSION_VERSION = "6";
		    # Point to the Qt6 dev headers for IDEs
            Qt6_DIR = "${pkgs.kdePackages.qtbase.dev}/lib/cmake/Qt6";

			ELECTRON_OZONE_PLATFORM_HINT = "wayland";

			DEFAULT_BROWSER = "${lib.getExe pkgs.firefox-nightly}";
			EDITOR = "nano";

            GST_PLUGIN_SYSTEM_PATH_1_0 =
                lib.makeSearchPathOutput "lib" "lib/gstreamer-1.0" (with pkgs.gst_all_1; [
                    gst-editing-services
                    gst-libav
                    gst-plugins-bad
                    gst-plugins-base
                    gst-plugins-good
                    gst-plugins-ugly
                    gstreamer
                ]);
        };
	};
}

# <> #
