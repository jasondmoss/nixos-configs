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
			SSH_ASKPASS = lib.mkForce "ksshaskpass";
			SSH_ASKPASS_REQUIRE = "prefer";
		};

		sessionVariables = {
            # XDG Base Directory Specification.
            XDG_BIN_HOME    = "$HOME/.local/bin";
            XDG_CACHE_HOME  = "$HOME/.cache";
            XDG_CONFIG_HOME = "$HOME/.config";
            XDG_DATA_HOME   = "$HOME/.local/share";

            # Development.
            Qt6_DIR = "${pkgs.kdePackages.qtbase.dev}/lib/cmake/Qt6";
#            EDITOR = "nvim";

            # Electron/Ozone.
            NIXOS_OZONE_WL = "1";
            ELECTRON_OZONE_PLATFORM_HINT = "auto";

            # Browser setup.
            DEFAULT_BROWSER = "${lib.getExe pkgs.firefox-nightly}";

            GST_PLUGIN_SYSTEM_PATH_1_0 =
                lib.makeSearchPathOutput "lib" "lib/gstreamer-1.0" (with pkgs.gst_all_1; [
                    gst-plugins-base
                    gst-plugins-good
                    gst-plugins-bad
                    gst-plugins-ugly
                    gst-libav
                    gstreamer
                ]);
        };
	};
}

# <> #
