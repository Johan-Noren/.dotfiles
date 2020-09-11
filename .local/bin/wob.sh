#!/usr/bin/env bash

wob_pipe=~/.cache/wobpipe

timeout=2000
max_percentage=100
bar_width=400
bar_height=50
border_offset=0
border_size=1
bar_padding=22
side='center'
anchor_margin=0
background_color=#ff1e1e1e
border_color=#FF5f5a60
bar_color=#ffcf6a4c


[[ -p $wob_pipe ]] || mkfifo $wob_pipe

tail -f $wob_pipe | /usr/bin/wob -t $timeout -m $max_percentage -W $bar_width -H $bar_height -o $border_offset -b $border_size -p $bar_padding -a $side  -M $anchor_margin --border-color="$border_color" --background-color="$background_color" --bar-color="$bar_color" 


