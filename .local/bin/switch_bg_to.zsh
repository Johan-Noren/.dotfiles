#!/bin/zsh


BGFILE=$(readlink -f $1)

rm "$HOME/.bg.jpg"
ln -s "$BGFILE" "$HOME/.bg.jpg"
