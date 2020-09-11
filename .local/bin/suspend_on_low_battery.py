#!/usr/bin/python3

import time
import os
import sys
import subprocess


def is_charging():
    a = subprocess.run(['cat','/sys/class/power_supply/BAT0/status'], capture_output=True, text=True)
    a = a.stdout.strip('\n')

    if a == 'Charging':
        return True
    else:
        return False

def current_level():
    a = subprocess.run(['cat','/sys/class/power_supply/BAT0/capacity'], capture_output=True, text=True)
    a = a.stdout.strip('\n')

    return int(a)

def notify(header, body):
    subprocess.run(['notify-send','-u', 'critical', header, body])


def suspend():
    subprocess.run(['/bin/systemctl','suspend'])


if __name__ == '__main__':

    #time.sleep(20)
    
    header = 'Battery Critically Low'
    body = 'Plug in to AC or the laptop will suspend itself in a little while'

    while True:

        if is_charging() == False and current_level() < 6:
            notify(header, body)
            
            time.sleep(60)

            if is_charging() == False:
                notify(header, 'Suspending')
                suspend()

        time.sleep(5)


    






