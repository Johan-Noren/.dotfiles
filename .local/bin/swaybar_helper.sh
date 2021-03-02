#!/bin/sh

_AND_="    "

time_bar() 
{
    echo "$TIME"

}

wifi_bar()
{
    echo "$WIFI_SSID ($WIFI_DB%)"

}    

battery_bar()
{
    echo "$BATTERY_CHARGE"

}


# MAIN LOOP

while :
do
    TIME="$(date +'%H:%M')"
    BATTERY_CHARGE=$(cat /sys/class/power_supply/BAT0/capacity)
    WIFI_SSID=$(iw dev wlp3s0  link | awk '/SSID/{print $2}')
    WIFI_DB=$(iw dev wlp3s0 link | grep signal | cut -d' ' -f 2 | cut -d'-' -f 2)

    # ECHO OUT THE STATUSLINE
    echo "$(wifi_bar)$_AND_$(battery_bar)%$_AND_$(time_bar) "

    sleep 1
done
