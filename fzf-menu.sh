#!/usr/bin/env bash

main() {
    local json="${1}"

    key=$(jq -r 'keys_unsorted|.[]' <<< "${json}"|fzf +m --layout=reverse-list)
    [ -z "${key}" ] && return 1

    item=$(jq ".\"${key}\"" <<< "${json}")
    item_type=$(jq -r 'type' <<< "${item}")

    case "${item_type}" in
        string)
            cmd=$(echo "${item}"|cut -d '"' -f 2)
            eval "${cmd}" || main "${json}"
            ;;
        object)
            main "${item}" || main "${json}"
            ;;
        *)
            return 1
            ;;
    esac
}

if [ "${#}" -lt 1 ]; then
    jsonfile=~/.config/fzf-menu/menu.json
else
    jsonfile="${1}"
fi

[ ! -f "${jsonfile}" ] && {
    echo "Error: ${jsonfile} does not exist" >&2
    exit 1
}

json=$(< "${jsonfile}")

main "${json}"
