{ pkgs }:

# Using the mpv wrapper pattern to inject scripts and custom ffmpeg
pkgs.mpv-unwrapped.wrapper {
    mpv = pkgs.mpv-unwrapped.override {
        waylandSupport = true;
        ffmpeg = pkgs.ffmpeg-full;
    };
    scripts = with pkgs.mpvScripts; [
        acompressor
        autosub
        autosubsync-mpv
        sponsorblock
        uosc
    ];
}
