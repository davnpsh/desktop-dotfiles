#!/bin/bash

internal_monitor=eDP-1
external_monitor=HDMI-1-0

# Terminate already running bar instances
killall -q polybar

# Launch Polybar, using default config location ~/.config/polybar/config.ini

# primary bar on laptop screen
MONITOR=$internal_monitor polybar primary 2>&1 | tee -a /tmp/polybar.log & disown

# secondary bar on external monitor if connected
if [[ $(xrandr -q | grep -w "$external_monitor connected") ]];
then
    MONITOR=$external_monitor polybar secondary 2>&1 | tee -a /tmp/polybar.log & disown 
fi

