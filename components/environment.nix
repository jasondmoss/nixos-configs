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

			# Work Identity File
			"gitconfig.work".text = ''
[user]
	name = "Jason D. Moss (Origin)"
	email = "jmoss@originoutside.com";
			'';

			# Personal Identity File
			"gitconfig.personal".text = ''
[user]
	name = "Jason D. Moss"
	email = "jason@jdmlabs.com"
			'';
		};

		variables = {
			# Backend logic
			GBM_BACKEND = "nvidia-drm";
			__GLX_VENDOR_LIBRARY_NAME = "nvidia";
			LIBVA_DRIVER_NAME = "nvidia";

			# Performance & Protocol
			__GL_THREADED_OPTIMIZATION = "1";
			__GL_SHADER_CACHE = "1";

			# Tooling & XDG
			XDG_BIN_HOME = "$HOME/.local/bin";
			XDG_CACHE_HOME = "$HOME/.cache";
			XDG_CONFIG_HOME = "$HOME/.config";
			XDG_DATA_HOME = "$HOME/.local/share";

			# Electron/Wayland Overrides (Still needed for some apps)
			NIXOS_OZONE_WL = "1";
			ELECTRON_OZONE_PLATFORM_HINT = "wayland";

			# Browser
			DEFAULT_BROWSER = "${lib.getExe pkgs.firefox-nightly}";

			# Google Gemini API
			GEMINI_API_KEY = "$(${pkgs.coreutils}/bin/cat ${config.users.users.me.home}/.config/gemini/api.key)";

			# Integration
			SSH_ASKPASS = lib.mkForce "ksshaskpass";
			SSH_ASKPASS_REQUIRE = "prefer";
		};

		sessionVariables.GST_PLUGIN_SYSTEM_PATH_1_0 =
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
}

# <> #
