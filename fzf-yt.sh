#!/usr/bin/env bash

trap 'kill $(jobs -p) 2>/dev/null' EXIT

usage() {
    echo yo
}

get_opts() {
    while getopts 'rdti:o:h' opt; do
      case "$opt" in
        r)
          local REFRESH=true
          ;;
        d)
          local DOWNLOAD=true
          ;;
        t)
          local TSP=true
          ;;
        i)
          local INPUT_FILE="${OPTARG}"
          ;;
        o)
          local OUTPUT_DIR="${OPTARG}"
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

    echo "${REFRESH:-false} ${DOWNLOAD:-false} ${TSP:-false} \
          ${INPUT_FILE:-$HOME/.config/fzf-yt/subs.xml} ${OUTPUT_DIR:-$PWD}"
}

error_and_exit() {
    echo "${@}" >&2
    exit 1
}

rm_tags() {
    local tag out out

    tag="${1}"
    out="${tag#*>}"
    out="${out%<*}"

    echo "${out}"
}

tag_val() {
    local tag count out

    tag="${1}"
    count=$(( ${2} * 2 ))
    out=$(cut -d '"' -f "${count}" <<< "${tag}")

    echo "${out}"
}

feed_items() {
    local feed id uploader published title

    feed="${1}"

    while read -r line; do
        case "${line}" in
            *\<yt:videoId\>*)
                id=$(rm_tags "${line}")
                ;;
            *\<name\>*)
                uploader=$(rm_tags "${line}")
                ;;
            *\<published\>*)
                published=$(rm_tags "${line}")
                ;;
            *\<media:title\>*)
                title=$(rm_tags "${line}")
                echo "${published}	${title} - ${uploader}	${id}"
                ;;
        esac
    done <<< "${feed}"
}

process_feeds() {
    feeds="${1}"

    while read -r feedurl; do
        feed_items "$(curl -s "${feedurl}")" &
    done <<< "${feeds}" | sort -r | cut -d '	' -f 2-
}

extract_feeds() {
    local feedfile

    feedfile="${1}"
    tags=$(grep "xmlUrl=" "${feedfile}")
    while read -r tag; do
        tag_val "${tag}" 4
    done <<< "${tags}"
}

fzf_preview() {
    id="${1}"
    thumb="https://img.youtube.com/vi/${id}/hqdefault.jpg"
    cache_file="$HOME/.cache/yt/${id}.jpg"

    [ ! -f "${cache_file}" ] && curl -s -o "${cache_file}" -O "${thumb}"
    "${HOME}"/.scripts/img.py -p "${IMG_PID}" -c -i "${cache_file}"
}

fzf_handler() {
    local vid_list IMG_PID

    vid_list="${1}"
    IMG_PID="${2}"
    export -f fzf_preview
    export IMG_PID
    selected_vids=$(fzf --preview-window=left:0 --margin=0,0,0,69 --preview='bash -c "fzf_preview {2}"' \
                        -m --layout=reverse-list -d '	' --with-nth=1  <<< "${vid_list}")

    while read -r v; do
        echo "${v##*	}"
    done <<< "${selected_vids}"
}

cache_feeds() {
    local input_file feeds

    input_file="${1}"
    mkdir -p ~/.cache/yt
    [ ! -f "${input_file}" ] && error_and_exit "Error: Input dir does not exist"
    feeds=$(extract_feeds "${input_file}")
    process_feeds "${feeds}" > ~/.cache/yt/vids.tsv
}

download_vids() {
    local ids tsp output_dir
    ids="${1}"
    tsp="${2}"
    output_dir="${3}"

    "${tsp}" && tsp_cmd=tsp

    while read -r id; do
        ${tsp_cmd} youtube-dl -o "${output_dir}/%(title)s - %(uploader)s - %(id)s.%(ext)s" "https://youtu.be/${id}"
    done <<< "${ids}"
}

play_vids() {
    local ids
    ids="${1}"

    while read -r id; do
        echo "https://youtu.be/${id}"
    done <<< "${ids}" | xargs -d '\n' mpv 
}

main() {
    read -r REFRESH DOWNLOAD TSP INPUT_FILE OUTPUT_DIR <<< "$(get_opts "${@}")"

    "${REFRESH}" && cache_feeds "${INPUT_FILE}" && exit

    [ ! -f ~/.cache/yt/vids.tsv ] && error_and_exit "Error: No cache file exists, run refresh (-r)"

    vid_list=$(< ~/.cache/yt/vids.tsv)

    IMG_PID=$$
    # start image display daemon
    ~/.scripts/img.py -p "${IMG_PID}" -w 70 -d &

    vid_selection=$(fzf_handler "${vid_list}" "${IMG_PID}")
    [ -z "${vid_selection}" ] && exit 1

    ids="$(cut -d '	' -f 2 <<< "${vid_selection}")"
    if "${DOWNLOAD}"; then
        download_vids "${ids}" "${TSP}" "${OUTPUT_DIR}"
    else
        play_vids "${ids}"
    fi
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && main "${@}"
