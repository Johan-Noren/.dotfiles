#!/bin/zsh

cd $HOME

rmdir Desktop
rmdir Documents
rmdir Pictures
rmdir Videos
rmdir Templates
rmdir Music

ln -s .docs/Build
ln -s .docs/Documents
ln -s .docs/Pictures
ln -s .docs/Videos
