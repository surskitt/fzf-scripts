#!/usr/bin/env bash

emoji_url="https://unicode.org/Public/emoji/12.0/emoji-test.txt"

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

pull_emoji() {
    curl -s "${emoji_url}"|grep 'fully-qualified     #'|sed -n 's/.*# \(.*\)/\1/p'
}

$REFRESH && {
    mkdir -p ~/.cache/emoji
    pull_emoji > ~/.cache/emoji/list.txt
}

if [ -f ~/.cache/emoji/list.txt ]; then
    emoji_list=$(< ~/.cache/emoji/list.txt)
else
    emoji_list=$(pull_emoji)
fi

emoji_selection=$(echo "${emoji_list}"|fzf --layout=reverse-list +m)
[ -z "${emoji_selection}" ] && exit 1

emoji="${emoji_selection%% *}"

echo -n "${emoji}"|xsel -b
