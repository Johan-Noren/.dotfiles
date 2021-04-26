#!/bin/zsh

BATTERY_CAPACITY_CMD=("/bin/cat" "/sys/class/power_supply/BAT0/capacity")
BATTERY_STATUS_CMD=("/bin/cat" "/sys/class/power_supply/BAT0/status")

# Battery levels
BATTERY_CRITICAL_WARN_LEVEL=7
BATTERY_CRITICAL_SUSPEND_LEVEL=5
BATTERY_CRITICAL_RESET_LEVEL=10


# Initialize main counter variable
BEAT=0

# Main loop
while :
do
	# Add one to main counter
	BEAT=$(( $BEAT +1 ))

	# Fetch current values
	BATTERY_CAPACITY=$($BATTERY_CAPACITY_CMD)
	BATTERY_STATUS=$($BATTERY_STATUS_CMD)

	
	if [[ $BATTERY_CAPACITY -gt $BATTERY_CRITICAL_RESET_LEVEL || $BATTERY_STATUS == "Charging" ]]; then
		ALLOW_NOTIFICATION=1

	# Send warning to user regarding soon suspending
	elif [[ $BATTERY_CAPACITY -le $BATTERY_CRITICAL_WARN_LEVEL && $BATTERY_STATUS == "Discharging" && $ALLOW_NOTIFICATION -eq 1 ]]; then
		/bin/notify-send --urgency=critical "Please plug in AC-adapter!" "\nThe battery is nearing depletion and needs to be recharged. Laptop will automatically suspend in a little while."
		ALLOW_NOTIFICATION=0
	fi

	# If less or equal to  5 and Discharning then suspend.
	if [[ $BATTERY_CAPACITY -le $BATTERY_CRITICAL_SUSPEND_LEVEL && $BATTERY_STATUS == "Discharging" ]]; then
		/bin/systemctl suspend
	fi
	
	sleep 10

done
