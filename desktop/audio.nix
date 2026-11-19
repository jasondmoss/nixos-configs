# audio.nix
#
# PipeWire audio stack with ALSA and PulseAudio compatibility; rtkit lets its
# threads take realtime scheduling. JACK clients run through the `pw-jack`
# wrapper (e.g. `pw-jack ardour`) instead of a global LD_LIBRARY_PATH.
{ config, ... }: {
    services.pipewire = {
        enable = true;
        audio.enable = true;
        # Deprecated: injects pipewire-jack into every session's LD_LIBRARY_PATH.
        # Nothing installed needs JACK by default; use pw-jack per app instead.
        # jack.enable = true;
        pulse.enable = true;
        alsa.enable = true;
    };

    # pw-jack wrapper for the occasional JACK-only app.
    environment.systemPackages = [ config.services.pipewire.package.jack ];

    security.rtkit.enable = true;
}

# <> #
