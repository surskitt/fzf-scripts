#!/usr/bin/env bash

nerdfont_url="https://raw.githubusercontent.com/ryanoasis/nerd-fonts/gh-pages/_includes/css/nerd-fonts.css"

REFRESH=false
while getopts 'rh' opt; do
  case "$opt" in
    r)
      REFRESH=true
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

pull_nerdfonts() {
    curl -s "${nerdfont_url}"|while read -r line; do
        case "$line" in
            .*:before*)
                name="${line##.}"
                name="${name%%:before*}"
                ;;
            *content:*)
                id="${line#*: \"}"
                id="${id%%\"*}"
                id="${id:1}"
                # shellcheck disable=SC2059
                [ -n "${name}" ] && printf '\u'"${id}	${name}\n"
                ;;
        esac
    done
}

$REFRESH && {
    mkdir -p ~/.cache/nerdfont_list
    pull_nerdfonts > ~/.cache/nerdfont_list/list.txt
}

if [ -f ~/.cache/nerdfont_list/list.txt ]; then
    nerdfont_list=$(< ~/.cache/nerdfont_list/list.txt)
else
    nerdfont_list=$(pull_nerdfonts)
fi

nerdfont_selection=$(echo "${nerdfont_list}"|fzf --layout=reverse-list +m)
[ -z "${nerdfont_selection}" ] && exit 1

nerdfont="${nerdfont_selection%%	*}"

echo -n "${nerdfont}"|xsel -b
