#!/bin/bash
# Customize based on session name or other details
set -eou pipefail

# get the name of the current session
name="$(tmux display-message -p '#S')"

# https://unix.stackexchange.com/a/779936
if [[ "$PWD" = /Users/michael.lisitsa/Documents/web ]]; then
  # Colour pallete for tmux is https://i.sstatic.net/e63et.png
  tmux set status-bg colour0
  echo "Web"
elif [[ "$PWD" = /Users/michael.lisitsa/Documents/diary ]]; then
  tmux set status-bg colour236 # grey
  echo "Diary"
elif [[ "$PWD" = /Users/michael.lisitsa/.dotfiles ]]; then
  tmux set status-bg colour95 # dark brown
  echo "Dotfiles"
fi
