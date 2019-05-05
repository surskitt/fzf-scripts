#!/usr/bin/env bash

trap 'kill $(jobs -p) 2>/dev/null' EXIT

INPUTFILE="$HOME/.config/fzf-vlive/channels.txt"
REFRESH=false
DOWNLOAD=false
TSP=false
PLAYER="mpv"
OUTPUT_DIR="${PWD}"
while getopts 'i:rdtpo:h' opt; do
  case "$opt" in
    i)
      INPUTFILE="${OPTARG}"
      ;;
    r)
      REFRESH=true
      ;;
    d)
      DOWNLOAD=true
      ;;
    t)
      TSP=true
      ;;
    p)
      PLAYER="${OPTARG}"
      ;;
    o)
      OUTPUT_DIR="${OPTARG}"
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

[ ! -f "${INPUTFILE}" ] && {
    echo "Error: Input file does not exist" >&2
    exit 1
}

[ ! -d "${OUTPUT_DIR}" ] && {
    echo "Error: Output dir does not exist" >&2
    exit 1
}

get_vids() {
    local inputfile="${1}"
    while read -r url; do
        youtube-dl --ignore-config --playlist-end 10 -j "${url}"|
            jq -r '[.title, .id, .webpage_url, .thumbnail]|join("	")' &
    done < "${inputfile}" | sort -t '	' -k 2 -n -r
}

mkdir -p ~/.cache/vlive
$REFRESH && {
    get_vids "${INPUTFILE}" > ~/.cache/vlive/vids.tsv
    exit
}

if [ -f ~/.cache/vlive/vids.tsv ]; then
    vid_list=$(< ~/.cache/vlive/vids.tsv)
else
    vid_list=$(get_vids "${INPUTFILE}")
fi

# start image display daemon
~/.scripts/img.py -p $$ -w 70 -d &

preview() {
    url="${1}"
    cache_file="$HOME/.cache/vlive/${2}.jpg"
    echo "
    [ ! -f ${cache_file} ] && curl -s -o ${cache_file} -O ${url}
    $HOME/.scripts/img.py -p $$ -c -i ${cache_file}
    "
}
vid_selection=$(fzf --layout=reverse-list -m -d '	' --with-nth=1 --preview-window=left:0 --margin=0,0,0,69 --preview="$(preview '{4}' '{2}')" <<< "${vid_list}")
[ -z "${vid_selection}" ] && exit 1

if "${DOWNLOAD}"; then
    "${TSP}" && tsp_cmd="tsp"
    while IFS='	' read -r _ _ url _; do
        ${tsp_cmd} youtube-dl -o "${OUTPUT_DIR}/%(title)s.%(ext)s" "${url}"
    done <<< "${vid_selection}"
else
    urls=$(cut -d '	' -f 3 <<< "${vid_selection}")
    # shellcheck disable=SC2086
    xargs -d '\n' ${PLAYER} <<< "${urls}"
fi
