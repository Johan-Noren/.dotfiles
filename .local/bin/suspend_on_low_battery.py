#!/usr/bin/python3

import time
import os
import sys
import subprocess
import argparse


def is_charging():
    """ Checks if power cord is connected and returns true/false """
    output = subprocess.run(['cat','/sys/class/power_supply/BAT0/status'], capture_output=True, text=True)
    output = output.stdout.strip('\n')

    if output == 'Charging':
        return True
    else:
        return False


def current_level():
    """ Checks current battery level """
    output = subprocess.run(['cat','/sys/class/power_supply/BAT0/capacity'], capture_output=True, text=True)
    output = output.stdout.strip('\n')

    return int(output)


def notify(header, body):
    """ Sends notification" """
    subprocess.run(['notify-send','-u', 'critical', header, body])


def suspend():
    """ Suspends the system """
    subprocess.run(['/bin/systemctl','suspend'])



if __name__ == '__main__':
    # Init argparse
    parser = argparse.ArgumentParser(description='Warns when battery is getting low and suspends laptop if needed')

    parser.add_argument('-w','--warn_level', 
                        help='At which battery percentage should a notification be sent.', 
                        default=7, type=int )

    parser.add_argument('-s','--suspend_level', 
                        help='At which battery percentage should laptop be suspended', 
                        default=5, type=int)

    args = vars(parser.parse_args())

    # Store arg-values in ny variables
    header = 'Battery Critically Low'
    body = 'Plug in to AC or the laptop will suspend itself in a little while'
    warn_level = args["warn_level"]
    suspend_level = args["suspend_level"]

    # Since we don't want to spam with notification.
    reset_level = warn_level + 10
    user_has_been_warned = False

    # Start eternal loop
    while True:

        if is_charging() == True or current_level() >= reset_level:
            user_has_been_warned = True

        if is_charging() == False and current_level() <= warn_level and user_has_been_warned == False:
            notify(header, body)
            user_has_been_warned = True
            
        if is_charging() == False and current_level() <= suspend_level:
            notify(header, 'Suspending')
            #suspend()

        time.sleep(5)


    






