#!/usr/bin/env bash

storedir=${PASSWORD_STORE_DIR-~/.password-store}

get_entries() {
    while read -r entry; do
        echo "${entry%\.*}"
    done <<< "$(find "${storedir}" -name '*.gpg' -printf '%P\n'|sort)"
}

selection=$(fzf +m --layout=reverse-list <<< "$(get_entries)")
[ -z "${selection}" ] && exit 1

pass "${selection}" -c
