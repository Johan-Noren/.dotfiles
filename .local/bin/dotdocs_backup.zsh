#!/bin/zsh

UNIX_TIME=$(date +%s)
TARGET_DIR="$HOME/.dotfiles/.docs"

cd $TARGET_DIR

if [ "$PWD" = "$TARGET_DIR" ]; then 
	# Keep only 5 newest
	ls -tp | grep -v '/$' | tail -n +6 | xargs -d '\n' -r rm --
fi

# Backup
cd $HOME
tar --create --file - --gzip -- ".docs" | openssl enc -e -aes-256-cbc -salt -pbkdf2 -iter 1000000 -out "$TARGET_DIR/docs_$UNIX_TIME.tgz.enc"

