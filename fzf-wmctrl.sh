#!/usr/bin/env bash

window_list=$(wmctrl -l)

window=$(echo "${window_list}"|fzf --layout=reverse-list +m --with-nth='4..')

wmctrl -i -a "${window%% *}"
