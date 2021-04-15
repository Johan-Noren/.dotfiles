#!/bin/zsh

LAST_FILE=$(ls -1 $HOME/.dotfiles/.docs/docs*tgz.enc | sort -t'_' -n -k2 -r | head -n1)
SOURCE_DIR="$HOME/.dotfiles/.docs"
TARGET_DIR="$HOME/.docs"

cd $HOME
openssl enc -d -aes-256-cbc -salt -pbkdf2 -iter 1000000 -in "$LAST_FILE" | tar --extract --gzip --file - 
