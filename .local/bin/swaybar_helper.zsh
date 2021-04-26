#!/bin/zsh

# Wifi interface
WIFI_INTERFACE=$(cat /proc/net/wireless | tail -n +3 | cut -d ":" -f1 | cut -d " " -f 2)

# Separator
_AND_="       "

# Initialize main counter variable
BEAT=0

# Main loop
while :
do
	# Add one to main counter 
	BEAT=$(( $BEAT +1 ))

	# Beat 1: Refresh time
	if [[ $(( $BEAT % 1  )) == 0 || $BEAT == 1 ]]; then
	    TIME="$(date +'%H:%M')"
		TIME_BAR="$TIME"
	fi

	# Beat 5: Update WIFI and Battey values
	if [[ $(( $BEAT % 5  )) == 0 || $BEAT == 1 ]]; then
    	BATTERY_CAPACITY="$(cat /sys/class/power_supply/BAT0/capacity)"
		BATTERY_STATUS="$(cat /sys/class/power_supply/BAT0/status)"
    	WIFI_SSID="$(iw dev ${WIFI_INTERFACE}  link | grep 'SSID' | cut -d ':' -f 2)"
    	WIFI_DB="$(iw dev ${WIFI_INTERFACE} link | grep signal | cut -d' ' -f 2 | cut -d'-' -f 2)"

		BATTERY_BAR="$BATTERY_CAPACITY%"
		WIFI_BAR="$WIFI_SSID ($WIFI_DB%)"

	fi

    # Print out the statusline
    echo "$WIFI_BAR$_AND_$BATTERY_BAR$_AND_$TIME_BAR"

	# Sleep for one second
    sleep 1
done


#   TEMPLATE
#	# Beat 9:
#	if [[ $(( $BEAT % 9  )) == 0 ]]; then
#
#	fi
