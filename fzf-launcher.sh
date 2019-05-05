#!/usr/bin/env bash


kv() {
    local entry="${1}"
    local key="${2}"

    line=$(grep "^${key}=" <<< "${entry}"|head -1)
    echo "${line#*=}"
}

get_apps() {
    desktop_files=$(find ~/.local/share/applications /usr/share/applications -name '*.desktop')
    while read -r df; do
        contents=$(< "${df}")
        name=$(kv "${contents}" "Name")
        cmd=$(kv "${contents}" "Exec")

        echo "${name}	${cmd}"
    done <<< "${desktop_files}"
}

main () {
    apps=$(get_apps)

    selection=$(fzf +m -d '	' --with-nth=1 <<< "${apps}")

    executable="${selection% \%*}"
    nohup "${executable#*	}" &
}

main
