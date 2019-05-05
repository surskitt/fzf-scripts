#!/usr/bin/env bash

trap 'kill $(jobs -p) 2>/dev/null' EXIT

fsum() {
    fn="${1}"
}

preview() {
    fn="${*}"

    # if [[ "${fn}" = "*.pdf" ]]; then
    if true; then
        cache_path="$HOME/.cache/fzf-books/$(echo -n "${fn}"|sha1sum|cut -d ' ' -f 1)"

        if [ ! -f "${cache_path}.jpg" ]; then
            pdftoppm -f 1 -l 1 -scale-to-x 1920 -scale-to-y -1 -singlefile \
                -jpeg -tiffcompression jpeg "${fn}" "${cache_path}" || cache_path='null'
        fi
    else
        cache_path='null'
    fi

    "${HOME}"/.scripts/img.py -p "${preview_pid}" -c -i "${cache_path}.jpg"
}
export -f preview

if [ "${#}" -lt 1 ]; then
    echo "Error: Books directory needs to be passed" >&2
    exit 1
fi

export preview_pid=$$

~/.scripts/img.py -p "${preview_pid}" -w 70 -H 28 -d &

BOOK_DIR="${1}"

# selected_vids=$(fzf --preview-window=left:0 --margin=0,0,0,69 --preview='bash -c "fzf_preview {2}"' \
#                     -m --layout=reverse-list -d '	' --with-nth=1  <<< "${vid_list}")
book="$(find "${BOOK_DIR}" -name '*.pdf'|fzf +m --layout=reverse-list --preview-window=left:0 \
                                             --margin=0,0,0,69 --preview='bash -c "preview {}"')"
[ -z "${book}" ] && exit 1

nohup zathura "${book}" >/dev/null & disown
