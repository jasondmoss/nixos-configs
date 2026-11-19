# audio.nix
#
# PipeWire audio stack with ALSA and PulseAudio compatibility; rtkit lets its
# threads take realtime scheduling.
{ config, ... }: {
    services.pipewire = {
        enable = true;
        audio.enable = true;
        pulse.enable = true;
        alsa.enable = true;
    };

    # pw-jack wrapper for the occasional JACK-only app.
    environment.systemPackages = [ config.services.pipewire.package.jack ];

    security.rtkit.enable = true;
}

# <> #
