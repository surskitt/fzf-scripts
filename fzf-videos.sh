#!/usr/bin/env bash

trap 'kill $(jobs -p) 2>/dev/null' EXIT

SORT_BY_DATE=false
DELETE=false
while getopts 'i:mp:dh' opt; do
  case "$opt" in
    i)
      INPUT_DIR="${OPTARG}"
      ;;
    m)
      SORT_BY_DATE=true
      ;;
    p)
      PLAYER="${OPTARG}"
      ;;
    d)
      DELETE=true
      ;;
    h)
      usage
      exit
      ;;
    ?)
      usage
      exit 1
      ;;
  esac
done
shift $(( OPTIND - 1 ))

[ -z "${INPUT_DIR}" ] && {
    echo "Error: Input dir must be passed" >&2
    exit 1
}

[ ! -d "${INPUT_DIR}" ] && {
    echo "Error: Input dir does not exist" >&2
    exit 1
}

if $SORT_BY_DATE; then
    vid_list=$(find "${INPUT_DIR}" \( -iname '*.mp4' -o -iname '*.mkv' -o -iname '*.avi' \) -printf "%T+\t%P\n"|sort -nr|cut -d '	' -f 2)
else
    vid_list=$(find "${INPUT_DIR}" \( -iname '*.mp4' -o -iname '*.mkv' -o -iname '*.avi' \) -printf "%P\n")
fi

# start image display daemon
"$HOME/.scripts/img.py" -p $$ -w 70 -d &

vid_selection=$(fzf --layout=reverse-list -m --preview-window=left:0 --margin=0,0,0,69 --preview="~/.scripts/vthumb.sh -v ${INPUT_DIR}/{}|$HOME/.scripts/img.py -p $$ -c -s" <<< "${vid_list}")
[ -z "${vid_selection}" ] && exit 1

if "${DELETE}"; then
    while read -r fn; do
        rm "${INPUT_DIR}/${fn%.*}"*
    done <<< "${vid_selection}"
else
    set -f
    # shellcheck disable=SC2086
    while read -r fn; do
        echo "${INPUT_DIR}/${fn}"
    done <<< "${vid_selection}"|xargs -d '\n' ${PLAYER:-mpv}
fi
