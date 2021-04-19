#!/bin/zsh

WIFI_INTERFACE=$(cat /proc/net/wireless | tail -n +3 | cut -d ":" -f1 | cut -d " " -f 2)

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
    WIFI_SSID="$(iw dev ${WIFI_INTERFACE}  link | grep 'SSID' | cut -d ':' -f 2)"
    WIFI_DB=$(iw dev ${WIFI_INTERFACE} link | grep signal | cut -d' ' -f 2 | cut -d'-' -f 2)

    # ECHO OUT THE STATUSLINE
    echo "$(wifi_bar)$_AND_$(battery_bar)%$_AND_$(time_bar) "

    sleep 1
done
