#!/bin/zsh

BATTERY_CAPACITY_PATH="/sys/class/power_supply/BAT0/capacity"
BATTERY_STATUS_PATH="/sys/class/power_supply/BAT0/status"

# Battery levels
BATTERY_CRITICAL_WARN_LEVEL=7
BATTERY_CRITICAL_SUSPEND_LEVEL=4
BATTERY_CRITICAL_RESET_LEVEL=10


# Initialize main counter variable
BEAT=0

# Main loop
while :
do
echo "hi"
	# Add one to main counter
	BEAT=$(( $BEAT +1 ))

	# Beat 1: Refresh time
	if [[ $(( $BEAT % 10  )) == 0 || $BEAT == 1 ]]; then
		BATTERY_CAPACITY="$(cat $BATTERY_CAPACTIY_PATH)"
		BATTERY_STATUS="$(cat $BATTERY_STATUS_PATH)"

	fi

	sleep 1
	echo "$BEAT"

echo "$BATTERY_CAPACITY"
echo "$BATTERY_STATUS"
done
