#!/bin/zsh

CURRENT_VALUE=$(light -G)
STARTING_POINT=${CURRENT_VALUE%.*}

if [[ "$#" -eq 0  ]];                                                                
then
	END_POINT=1
else
	END_POINT=$1
fi


echo "CURRENT_VALUE: $CURRENT_VALUE, STARTING_POINT=$STARTING_POINT, END_POINT=$END_POINT"


if [[ "$STARTING_POINT" -le "$END_POINT" ]]; then
	echo "Nothing to do here"
	exit 1

else
	# Store current value for restoration
	/usr/bin/light -O

	# Loop
	for x in {$STARTING_POINT..$END_POINT}; do
		/usr/bin/light -S $x
		sleep 0.01
	done

fi
