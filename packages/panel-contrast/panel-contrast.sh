# panel-contrast — keep Plasma panel icons legible over the wallpaper.
#
# Samples the wallpaper region behind the panel and sets Panel Colorizer's
# foreground colour to the light colour (dark wallpaper) or the dark colour
# (light wallpaper), editing only those fields of its settings so changes made
# in its own settings window stay. Re-evaluates when Plasma rewrites its applet
# config (a wallpaper change, or a Panel Colorizer settings change that reset
# the colour), when the activity changes, and when plasmashell (re)appears on
# the session bus (login, restart). Both Plasma scripts write only on a
# difference, so their own config write settles on the next pass.
#
#   panel-contrast            watch and apply (the user unit)
#   panel-contrast --once     evaluate and apply once
#   panel-contrast --dry-run  print the decision, apply nothing
#
# Before the colour it brings the widget settings (Panel Colorizer tray icons,
# sensor face, …) in line with PANEL_CONTRAST_WIDGET_SCRIPT.
#
# Settings come from PANEL_CONTRAST_* (see the NixOS module).

light_color=${PANEL_CONTRAST_LIGHT_COLOR:-#ffffff}
dark_color=${PANEL_CONTRAST_DARK_COLOR:-#000000}
color_script=${PANEL_CONTRAST_COLOR_SCRIPT:?PANEL_CONTRAST_COLOR_SCRIPT must point at the colour script}
threshold=${PANEL_CONTRAST_THRESHOLD:-0.5}
region=${PANEL_CONTRAST_REGION:-2%x40%+0+0}
gravity=${PANEL_CONTRAST_GRAVITY:-NorthEast}
screen=${PANEL_CONTRAST_SCREEN:-0}
screen_size=${PANEL_CONTRAST_SCREEN_SIZE:-3840x2160}
widget_script=${PANEL_CONTRAST_WIDGET_SCRIPT:-}

config_dir=${XDG_CONFIG_HOME:-$HOME/.config}
appletsrc_name=plasma-org.kde.plasma.desktop-appletsrc
appletsrc=$config_dir/$appletsrc_name

plasma_script() {
    busctl --user call org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell \
        evaluateScript s "$1" 2>&1
}

current_activity() {
    busctl --user call org.kde.ActivityManager /ActivityManager/Activities \
        org.kde.ActivityManager.Activities CurrentActivity 2>/dev/null \
        | sed -n 's/^s "\(.*\)"$/\1/p'
}

# Image= of the desktop containment on $screen for the given activity (any
# activity when empty), only while its wallpaper plugin is the plain image one.
wallpaper_setting() {
    awk -v screen="$screen" -v activity="$1" '
        /^\[Containments\]\[[0-9]+\]$/ {
            match($0, /[0-9]+/); id = substr($0, RSTART, RLENGTH); section = "containment"; next
        }
        /^\[Containments\]\[[0-9]+\]\[Wallpaper\]\[org\.kde\.image\]\[General\]$/ {
            match($0, /[0-9]+/); id = substr($0, RSTART, RLENGTH); section = "image"; next
        }
        /^\[/ { section = ""; next }
        section == "containment" && /^activityId=/      { act[id] = substr($0, 12) }
        section == "containment" && /^lastScreen=/      { scr[id] = substr($0, 12) }
        section == "containment" && /^wallpaperplugin=/ { plugin[id] = substr($0, 17) }
        section == "image" && /^Image=/                 { image[id] = substr($0, 7) }
        END {
            for (i in image)
                if (scr[i] == screen && (plugin[i] == "" || plugin[i] == "org.kde.image") \
                    && (activity == "" || act[i] == activity)) {
                    print image[i]
                    exit
                }
        }
    ' "$appletsrc"
}

# Resolve an Image= value to an image file: file:// URLs, plain paths, and
# wallpaper packages (a directory, or a bare package name under share/wallpapers).
wallpaper_file() {
    local image=$1 dir

    if [[ $image == file://* ]]; then
        image=${image#file://}
        image=$(printf '%b' "${image//%/\\x}")
    fi

    if [[ $image != /* ]]; then
        local IFS=:
        # shellcheck disable=SC2086  # split XDG_DATA_DIRS on ':'
        for dir in "${XDG_DATA_HOME:-$HOME/.local/share}" ${XDG_DATA_DIRS:-/run/current-system/sw/share}; do
            if [[ -d $dir/wallpapers/$image ]]; then
                image=$dir/wallpapers/$image
                break
            fi
        done
    fi

    if [[ -d $image ]]; then
        local exact
        exact=$(find "$image/contents/images" -maxdepth 1 -type f -name "$screen_size.*" 2>/dev/null | head -n1)
        if [[ -n $exact ]]; then
            image=$exact
        else
            image=$(find "$image/contents/images" -maxdepth 1 -type f -printf '%s\t%p\n' 2>/dev/null \
                | sort -rn | head -n1 | cut -f2-)
        fi
    fi

    [[ -n $image && -f $image ]] && printf '%s\n' "$image"
}

# Mean luminance (0..1) of the panel region. The image is first fitted to the
# screen the way Plasma's default "Scaled and Cropped" mode does, at quarter
# resolution — plenty for an average.
region_luma() {
    local w=${screen_size%x*} h=${screen_size#*x}
    local canvas="$((w / 4))x$((h / 4))"
    magick "$1[0]" -auto-orient -resize "$canvas^" -gravity center -extent "$canvas" \
        -gravity "$gravity" -crop "$region" +repage \
        -colorspace Gray -format '%[fx:mean]' info: 2>/dev/null
}

# Write the widget settings (Panel Colorizer tray icons, sensor face, …)
# into the panel widgets; sets widgets_changed=1 when anything was written.
widgets_changed=0
apply_widget_settings() {
    local result
    widgets_changed=0
    [[ -n $widget_script && -f $widget_script ]] || return 0
    if ! result=$(plasma_script "$(<"$widget_script")"); then
        echo "could not apply widget settings: $result"
        return 0
    fi
    if [[ $result == *updated* ]]; then
        echo "widget settings: ${result#s }"
        widgets_changed=1
    fi
    return 0
}

# Set the foreground colour in every Panel Colorizer widget; sets
# color_changed=1 when a widget was actually rewritten.
color_changed=0
apply_color() {
    local result
    color_changed=0
    if ! result=$(plasma_script "var color = \"$1\";
$(<"$color_script")"); then
        echo "could not set the panel colour: $result"
        return 0
    fi
    [[ $result == *recoloured* ]] && color_changed=1
    return 0
}

evaluate() {
    local mode=$1 activity setting image luma preset color other

    activity=$(current_activity)
    setting=$(wallpaper_setting "$activity")
    if [[ -z $setting ]]; then
        echo "no image wallpaper for screen $screen${activity:+ in activity $activity}"
        return 0
    fi
    if ! image=$(wallpaper_file "$setting"); then
        echo "wallpaper not found: $setting"
        return 0
    fi
    if ! luma=$(region_luma "$image") || [[ -z $luma ]]; then
        echo "could not sample $image"
        return 0
    fi

    if awk -v l="$luma" -v t="$threshold" 'BEGIN { exit !(l < t) }'; then
        preset=light-icons color=$light_color other=$dark_color
    else
        preset=dark-icons color=$dark_color other=$light_color
    fi

    if [[ $mode == dry-run ]]; then
        echo "$image: luma $luma (threshold $threshold) -> $preset"
        return 0
    fi

    apply_widget_settings
    if [[ $widgets_changed == 1 ]]; then
        # A widget that rebuilt its content (a new sensor face) shows the
        # theme's colours until Panel Colorizer recolours it, which it only
        # does when the colour changes: pass through the other colour.
        apply_color "$other"
        sleep 1
    fi
    apply_color "$color"
    if [[ $color_changed == 1 || $widgets_changed == 1 ]]; then
        echo "$image: luma $luma -> $preset"
    fi
}

events() {
    inotifywait --monitor --quiet --event close_write --event moved_to \
        --format 'file %f' "$config_dir" &
    dbus-monitor --session \
        "type='signal',interface='org.kde.ActivityManager.Activities',member='CurrentActivityChanged'" \
        "type='signal',sender='org.freedesktop.DBus',interface='org.freedesktop.DBus',member='NameOwnerChanged',arg0='org.kde.plasmashell'" &
    # Either source ending leaves the watch incomplete: stop both and let
    # systemd restart the unit.
    wait -n || true
    # shellcheck disable=SC2046
    kill $(jobs -p) 2>/dev/null || true
}

case ${1:-} in
    --once)    evaluate apply || true; exit 0 ;;
    --dry-run) evaluate dry-run || true; exit 0 ;;
    "")        ;;
    *)         echo "usage: panel-contrast [--once|--dry-run]" >&2; exit 2 ;;
esac

evaluate apply || true

while IFS= read -r line; do
    case $line in
        "file $appletsrc_name" | *member=CurrentActivityChanged* | *member=NameOwnerChanged*) ;;
        *) continue ;;
    esac
    # Plasma writes in bursts, and a fresh plasmashell needs a moment to load
    # its widgets: settle first.
    while IFS= read -r -t 2 line; do :; done
    evaluate apply || true
done < <(events)

echo "event sources ended"
exit 1
