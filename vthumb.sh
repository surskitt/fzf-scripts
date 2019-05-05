#!/usr/bin/env bash

OUTPUT_DIR=~/.thumbnails/video
VERBOSE=false
while getopts 'vo:h' opt; do
  case "$opt" in
    o)
      OUTPUT_DIR="${OPTARG}"
      ;;
    v)
      VERBOSE=true
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

# [ -z "${OUTPUT_DIR}" ] && {
#     echo "Error: please provide thumb output dir" >&2
#     exit 1
# }

mkdir -p "${OUTPUT_DIR}"

VIDEO_FN="${1/#\~/$HOME}"
vsum=$(echo -n "${VIDEO_FN}"|sha1sum|cut -d ' ' -f 1)


[ -f "${OUTPUT_DIR}/${vsum}.jpg" ] || {
    ffmpegthumbnailer -i "$1" -o "${OUTPUT_DIR}/${vsum}.jpg" -s 0
}

$VERBOSE && echo "${OUTPUT_DIR}/${vsum}.jpg"
