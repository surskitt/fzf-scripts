#!/usr/bin/env bash

trap 'kill $(jobs -p)' EXIT

[ ${#} -lt 1 ] && {
    echo "Error: image directory not passed" >&2
    echo "Usage: $0 WALLPAPER_DIR"
    exit 1
}

IMAGE_DIR="${1}"

[ ! -d "${IMAGE_DIR}" ] && {
    echo "Error: ${IMAGE_DIR} does not exist" >&2
    exit 1
}

imgs=$(find "${IMAGE_DIR}" -type f \( -iname '*.gif' -o -iname '*.png' -o -iname '*.jp*g' -o -iname '*.bmp' \) -printf "%P\n")

# start image display daemon
~/.scripts/img.py -p $$ -w 70 -d &

fzf_opts=("--layout=reverse-list" +m "--margin=0,0,0,69" "--preview-window=left:0")
preview_command="$HOME/.scripts/img.py -p $$ -c -i ${IMAGE_DIR}/{}"

image_selection=$(fzf "${fzf_opts[@]}" --preview="${preview_command}" <<< "${imgs}")
[ -z "${image_selection}" ] && exit 1

img_url=$(curl -s -F"file=@${IMAGE_DIR}/${image_selection}" https://0x0.st)

xsel -b <<< "${img_url}"
