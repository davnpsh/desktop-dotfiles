#! /bin/sh
#
## Author : davnpsh 
## Github : https://github.com/davnpsh
#
## Rofi   : Monitor modes
#

# Current Theme
dir="$HOME/.config/rofi/monitor-modes/"
theme='style'

# Monitors
internal_monitor=eDP-1
external_monitor=HDMI-1-0

# Number of desktops to give to external monitor
desktops_number=2 # <-- MUST BE > 1
# This has to be in accordance with the bspwmrc script
# desktops_number = desktops to regenerate on external monitor

# Options
extend='󰹑'
duplicate='󰍺'
single='󰍹'

## SCRIPTS FOR THE SCREEN

extend_screen() {
    # If external monitor is not connected, do nothing
    if ! [[ $(xrandr -q | grep -w "$external_monitor connected") ]]; then
        exit 1
    fi

    # If external monitor is connected:
    #
    # How many desktops on virtual external monitor
    desktops_on_external=$(bspc query -D -m $external_monitor | wc -l)
    
    # Create virtual screen for external monitor
    xrandr --output $internal_monitor --auto --primary --output $external_monitor --auto --right-of $internal_monitor

    # Reload polybar, picom and the wallpaper
    picom &
    $HOME/.config/polybar/launch.sh > /dev/null 2>&1 &
    $HOME/.fehbg &
    
    # If there are already desktops on the external monitor, do nothing
    if [[ $desktops_on_external != 0 ]]; then
        # I subtracted 1 because I won't count the automatic generated Desktop when doing xrandr
        exit 1
    fi

    # Select the last two desktops on the internal monitor
    desktops_to_give=$(bspc query -D -m $internal_monitor | tail -n $desktops_number)

    # Give them to the external monitor
    for desktop in $desktops_to_give; do
        bspc desktop $desktop --to-monitor $external_monitor
    done

    # Remove temp desktop created
    bspc desktop Desktop --remove
}

duplicate_screen() {

    # If external monitor is not connected, do nothing
    if ! [[ $(xrandr -q | grep -w "$external_monitor connected") ]]; then
        exit 1
    fi

    # Go to single screen
    (single_screen)
    
    # Duplicate screen
    xrandr --output $external_monitor --auto --same-as $internal_monitor

    # Remove temp desktop created
    bspc monitor $external_monitor -r
}

single_screen() {
    # Turn off external monitor
    xrandr --output $internal_monitor --auto --primary --output $external_monitor --off

    # Reload polybar
    $HOME/.config/polybar/launch.sh > /dev/null 2>&1 &

    # How many desktops on virtual external monitor
    desktops_on_external=$(bspc query -D -m $external_monitor | wc -l)
    
    # If there are not desktops on the external monitor, do nothing
    if [[ $desktops_on_external == 0 ]]; then
        exit 1
    fi

    # Select all the desktops to return on the external monitor 
    desktops_to_return=$(bspc query -D -m $external_monitor)

    # Create temp desktop (rule to move all other desktops)
    bspc monitor $external_monitor -a Desktop
    
    # Return all desktops to internal monitor
    for desktop in $desktops_to_return; do
        bspc desktop $desktop --to-monitor $internal_monitor
    done

    # Remove temp desktop created
    bspc monitor $external_monitor -r
}

## SCRIPTS FOR ROFI

# Rofi CMD
rofi_cmd() {
	rofi -dmenu \
		-theme ${dir}/${theme}.rasi
}

# Pass options
run_rofi() {
	# Removed \n$suspend
	echo -e "$extend\n$duplicate\n$single" | rofi_cmd
}

# Execute command
run_cmd() {
    if [[ $1 == '--extend' ]]; then
        extend_screen
    elif [[ $1 == '--duplicate' ]]; then
        duplicate_screen
    elif [[ $1 == '--single' ]]; then
        single_screen 
    fi
}

# Actions
chosen="$(run_rofi)"
case ${chosen} in
    $extend)
		run_cmd --extend
        ;;
    $duplicate)
		run_cmd --duplicate
        ;;
    $single)
		run_cmd --single
        ;;
esac
