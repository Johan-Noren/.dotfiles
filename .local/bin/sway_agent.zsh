#!/bin/zsh

# Wifi interface
WIFI_INTERFACE=$(cat /proc/net/wireless | tail -n +3 | cut -d ":" -f1 | cut -d " " -f 2)

# Battery levels
BATTERY_CRITICAL_WARN_LEVEL=7
BATTERY_CRITICAL_SUSPEND_LEVEL=4
BATTERY_CRITICAL_RESET_LEVEL=10


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

	# Beat 4: 
	if [[ $(( $BEAT % 4  )) == 0 ]]; then

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

	# Beat 9:
	if [[ $(( $BEAT % 9  )) == 0 ]]; then

	fi

	# Beat 10: Handle low battery situationsudevadm monitor --property
	
	if [[ $(( $BEAT % 10  )) == 0 ]]; then
		if [[ $BATTERY_STATUS == "Discharging" && $BATTERY_CAPACITY -lt $BATTERY_CRITICAL_WARN_LEVEL && $LOW_BATTERY_WARNING_SENT -eq 0 ]]; then
			/bin/notify-send "Plug in AC-adapter" "Battery capacity is getting dangerously low. Please plug in AC-adapter or laptop will be suspended"

			# We don't want to spam with notifications. One is enough.
			LOW_BATTERY_WARNING_SENT=1
		fi

		# If battery has been restored then it's fine to sent notifications again.
		if [[ $BATTERY_CAPACITY -gt $BATTERY_CRITICAL_RESET_LEVEL ]]; then
			LOW_BATTERY_WARNING_SENT=0

		fi

		# Put in suspend
		if [[ $BATTERY_STATUS == "Discharging" && $BATTERY_CAPACITY -lt $BATTERY_CRITICAL_SUSPEND_LEVEL ]]; then
			echo "Suspending because of critical battery levels" | /bin/systemd-cat -t sway_agent
			/bin/systemctl suspend

		fi

	fi



    # Print out the statusline
    #echo "$(wifi_bar)$_AND_$(battery_bar)%$_AND_$(time_bar) "
    echo "$WIFI_BAR$_AND_$BATTERY_BAR$_AND_$TIME_BAR"

	# Sleep for one second
    sleep 1
done


