# audio.nix
#
# PipeWire audio stack with ALSA (32-bit too), PulseAudio and JACK
# compatibility; rtkit lets its threads take realtime scheduling.
{ ... }: {
    services.pipewire = {
        enable = true;
        audio.enable = true;
        jack.enable = true;
        pulse.enable = true;

        alsa = {
            enable = true;
            support32Bit = true;
        };
    };

    security.rtkit.enable = true;
}

# <> #
