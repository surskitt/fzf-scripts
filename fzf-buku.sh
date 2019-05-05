#!/usr/bin/env bash

usage() {
    echo blah
}

while getopts 'th' opt; do
  case "$opt" in
    t)
      SKIP_TAGS=false
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

select_tags() {
    buku --np -t|sed '$ d;s/^ *//;s/. /	/'|fzf --layout=reverse-list -m|grep -o -P '(?<=	).*(?= \()'
}

format_tag_list() {
    echo "${*}"|sed ':a;N;$!ba;s/\n/ + /g'
}

tag_arg="-p"
$SKIP_TAGS || {
    tags=$(select_tags)

    [ -n "${tags}" ] && {
        tag_list=$(format_tag_list "${tags}")
        tag_arg="-t ${tag_list}"
    }
}

ids=$(buku --np "${tag_arg}" -f 3|tac|fzf --layout=reverse-list -m|cut -d '	' -f 1|tr '\n' ' ')

[ -z "${ids}" ] && exit 1

# shellcheck disable=SC2086
buku -o ${ids}
