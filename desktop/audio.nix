# audio.nix
#
# PipeWire audio stack with ALSA, PulseAudio and JACK compatibility; rtkit
# lets its threads take realtime scheduling.
{ ... }: {
    services.pipewire = {
        enable = true;
        audio.enable = true;
        jack.enable = true;
        pulse.enable = true;
        alsa.enable = true;
    };

    security.rtkit.enable = true;
}

# <> #
