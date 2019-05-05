#!/usr/bin/env bash

usage() {
    echo sup
}

user_svc=false
use_icons=false
restart_svc=false
while getopts "uirh" opt; do
    case "${opt}" in
        u) user_svc=true ;;
        i) use_icons=true ;;
        r) restart_svc=true ;;
        h) usage ;;
        *) usage ;;
    esac
done
shift $(( OPTIND - 1 ))
svc="${*}"

svc_status() {
    svc="${1}"
    user_svc="${2}"
    icons="${3}"
    "${user_svc}" && user_flag=--user

    if systemctl status ${user_flag} "${svc}" >/dev/null; then
        if "${icons}"; then
            echo " ${svc}"
        else
            echo "${svc} - running"
        fi
    else
        if "${icons}"; then
            echo " ${svc}"
        else
            echo "${svc} - stopped"
        fi
    fi
}

toggle() {
    in="${1}"
    user_svc="${2}"
    "${user_svc}" && user_flag=--user

    svc="${in#* }"
    svc="${svc% - *}"

    if systemctl status ${user_flag} "${svc}" >/dev/null; then
        systemctl stop ${user_flag} "${svc}"
    else
        systemctl start ${user_flag} "${svc}"
    fi
}

statuses=$({
    for i in ${svc}; do
        svc_status "${i}" "${user_svc}" "${use_icons}"
    done
})

selected="$(fzf -m --layout=reverse-list <<< "${statuses}")"
[ -z "${selected}" ] && exit 1

while read -r s; do
    if "${restart_svc}"; then
        :
    else
        toggle "${s}" "${user_svc}"
    fi
done <<< "${selected}"
