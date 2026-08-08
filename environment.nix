{ config, lib, pkgs, identity, ... }: {
	environment = {
		etc = {
			"1password/custom_allowed_browsers" = {
				text = ''
firefox
google-chrome-stable
				'';
				mode = "0755";
			};

			"gitconfig.work".text = ''
[user]
	name = Jason D. Moss
	email = ${identity.emailOrigin};
			'';

			"gitconfig.personal".text = ''
[user]
	name = Jason D. Moss
	email = ${identity.emailPersonal}
			'';

            "gitconfig.gitlab".text = ''
[user]
    name = Jason D. Moss
    email = ${identity.emailWork}
            '';

            "gitconfig.bitbucket".text = ''
[user]
    name = Jason D. Moss
    email = ${identity.emailOrigin}
            '';
		};

		variables = {
			SSH_ASKPASS = lib.mkForce "ksshaskpass";
			SSH_ASKPASS_REQUIRE = "prefer";
		};
		pathsToLink = [
            "/home/me/Mega/Images/Icons/Apps/"
            "/share/applications"
            "/share/icons"
            "/share/pixmaps"
        ];

		sessionVariables = {
            # XDG Base Directory Specification.
            XDG_BIN_HOME    = "$HOME/.local/bin";
            XDG_CACHE_HOME  = "$HOME/.cache";
            XDG_CONFIG_HOME = "$HOME/.config";
            XDG_DATA_HOME   = "$HOME/.local/share";

            # Development.
            Qt6_DIR = "${pkgs.kdePackages.qtbase.dev}/lib/cmake/Qt6";
#            EDITOR = "nvim";

            # AI — HuggingFace-based tools cache models on the Repository drive.
            HF_HOME = "/home/me/Repository/ai/huggingface";

            # Electron/Ozone.
            NIXOS_OZONE_WL = "1";
            ELECTRON_OZONE_PLATFORM_HINT = "auto";

            # Browser setup.
            # firefox-stable is a wrapper installed by packages/firefox-stable,
            # not a pkgs attribute — reference it via the system profile.
#            DEFAULT_BROWSER = "/run/current-system/sw/bin/firefox-stable";
            DEFAULT_BROWSER = "/run/current-system/sw/bin/firefox";

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
