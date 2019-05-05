#!/usr/bin/env bash

trap 'kill $(jobs -p)' EXIT

[ ${#} -lt 1 ] && {
    echo "Error: wallpaper directory not passed" >&2
    echo "Usage: $0 WALLPAPER_DIR"
    exit 1
}

WALLPAPER_DIR="${1}"

[ ! -d "${WALLPAPER_DIR}" ] && {
    echo "Error: ${WALLPAPER_DIR} does not exist" >&2
    exit 1
}

imgs=$(find "${WALLPAPER_DIR}" -type f \( -iname '*.png' -o -iname '*.jp*g' -o -iname '*.bmp' \) -printf "%P\n")

# start image display daemon
~/.scripts/img.py -p $$ -w 70 -d &

fzf_opts=("--layout=reverse-list" -m "--margin=0,0,0,69" "--preview-window=left:0")
preview_command="$HOME/.scripts/img.py -p $$ -c -i ${WALLPAPER_DIR}/{}"

wallpaper_selection=$(fzf "${fzf_opts[@]}" --preview="${preview_command}" <<< "${imgs}")
[ -z "${wallpaper_selection}" ] && exit 1

cat -n <<< "${wallpaper_selection}"|while read -r n f; do
    ln -sf "${WALLPAPER_DIR}/${f}" "$HOME/.wallpaper${n}"
    echo "${WALLPAPER_DIR}/${f}"
done|xargs -d '\n' feh --bg-fill
