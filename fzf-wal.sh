#!/usr/bin/env bash

type fzf >/dev/null || {
    echo "Error: fzf not installed" >&2
    exit 1
}

wal_dirs=(
    /usr/lib/python3.7/site-packages/pywal/colorschemes
    ~/.config/wal/colorschemes
)

set_wal() {
    theme=${1#*/}
    echo $theme
    [[ $1 == light/* ]] && lightflag="-l"
    wal -q -f $theme $lightflag -o ~/.scripts/qutebrowser_reload.py -s
}

themes=$(find ${wal_dirs[*]} -type f -name '*.json'|rev|cut -d '/' -f 1-2|rev|cut -d '.' -f 1|sort)
theme=$(fzf +m <<< "${themes}") || exit

i3_workspace=$(i3-msg -t get_workspaces | jq -r '.[] | select(.focused==true).name')

set_wal "${theme}"

kill -USR1 $(fuser /usr/bin/xst 2>/dev/null)
sleep 1
i3-msg workspace "${i3_workspace}" > /dev/null

killall dunst 2>/dev/null
