#!/usr/bin/python3

import time
import os
import sys
import subprocess


def read_sensor():
    """
    Returns current sensor value as an integer. 
    """
    value = subprocess.run(['cat','/sys/devices/platform/applesmc.768/light'], capture_output=True, text=True)
    value = value.stdout.strip('()\n')
    value = value.split(',')[0]

    value = round(int(value)/2.56, 0)
    
    return value


def write_new_light_values(display, keyboard):
    """
    Sets kbd and display to new values. (using light)
    """

    if display:
        subprocess.run(['light','-s', 'sysfs/backlight/intel_backlight', '-S' , str(display)])
    
    if keyboard:
        subprocess.run(['light','-s', 'sysfs/leds/smc::kbd_backlight', '-S' , str(keyboard)])


def read_current_light_values():
    """
    Reads kbd and display values. Returns a dict with two values
    """

    current_display  = float(subprocess.run(['light','-s', 'sysfs/backlight/intel_backlight', '-G'], capture_output=True, text=True).stdout.strip('\n'))
    current_keyboard = float(subprocess.run(['light','-s', 'sysfs/leds/smc::kbd_backlight', '-G'], capture_output=True, text=True).stdout.strip('\n'))

    current_display = int(round(current_display,0))
    current_keyboard = int(round(current_keyboard,0))

    return current_display, current_keyboard

def check_if_manually_overriden():
    


def target_display(sensor_reading, current_display):
    current = current_display
    
    if 0 <= sensor_reading <= 50:
        target = 40
    else:
        target = 90

    if target > current:
        return current + 1
    elif target < current:
        return current - 1
    elif target == current:
        return False


def target_kbd(sensor_reading, current_kbd):
    current = current_kbd
    
    if 0 <= sensor_reading <= 3:
        target = 40
    else:
        target = 0

    if target > current:
        return current + 1
    elif target < current:
        return current - 1
    elif target == current:
        return False


def notify(header, body):
    subprocess.run(['notify-send','-u', 'critical', header, body])


if __name__ == '__main__':
    
    main = []
    
    sample_size = 6

    while True:
        sensor_reading = read_sensor()
        current_display, current_keyboard = read_current_light_values()

        main = main + [sensor_reading]
        
        if len(main) >= sample_size:
            main = main[-sample_size:]

        rolling_average = int(round(sum(main[-sample_size:])/sample_size,0))
    
        write_new_light_values(target_display(rolling_average, current_display), target_kbd(rolling_average, current_keyboard))

        print('sensor_reading: ', sensor_reading)
        print('rolling_average: ', rolling_average)
        print('display: ', current_display)
        print('keyboard: ', current_keyboard)

        time.sleep(1)

