#!/usr/bin/env bash
# Drop-down terminal: start it on first use, then show/hide it.
if ! hyprctl clients -j | jq -e '.[] | select(.class == "scratchterm")' >/dev/null; then
    kitty --class scratchterm &
    sleep 0.3
fi
hyprctl dispatch 'hl.dsp.workspace.toggle_special("term")'
