#!/bin/python
# I handle power stuff

import os
import sys
import select
import time
import subprocess

SCREEN_DEVICE = "sysfs/backlight/intel_backlight"
KBD_DEVICE = "sysfs/leds/smc::kbd_backlight"
BATTERY_CAPACITY_DEVICE = "/sys/class/power_supply/BAT0/capacity"
BATTERY_STATE_DEVICE = "/sys/class/power_supply/BAT0/status"
LIGHT_CMD = "/usr/bin/light"

LOCK_VALUE_SCREEN = 0
LOCK_VALUE_KBD = 0
CURRENT_STATE = 'normal' # idle_dim, idle_blank

# Decorator: output to log. For verbose mode
#def output_to_log(func):
#    def wrapper(args):
#        print(f"function: {func.__name__}, args: {args}")
#        return_value = func(args)
#        return return_value
#
#    return wrapper


### Helper functions ###

def _connect_to_fifo(path):
    fifo = open(path)    
    return fifo


def _tell_notifier(message, urgency):
    return None


def _handle_subprocess_output(rvalue):
    rvalue = rvalue.stdout.strip('\n')
    
    try:
        rvalue = int(round(float(rvalue), 0))
    except:
        pass

    return rvalue


def _run_light(cmd):
    rvalue = subprocess.run(cmd, capture_output=True, text=True)
    return _handle_subprocess_output(rvalue)
    

def _convert_relative_string(change):
    try: 
        if change[0] == "+":
            direction_flag = "-A"

        elif change[0] == "-":
            direction_flag = "-U"

    except:
        direction_flag = "-A"

    try:
        value = int(round(change[1:], 0))

    except:
        value = 0

    return direction_flag, value


def _screen_brightness():
    rvalue = _run_light([LIGHT_CMD, "-s", SCREEN_DEVICE, "-G" ])
    return rvalue


def _kbd_brightness():
    rvalue = _run_light([LIGHT_CMD, "-s", KBD_DEVICE, "-G" ])
    return rvalue


def _battery_charge():
    rvalue = subprocess.run(['cat', BATTERY_CAPACITY_DEVICE], capture_output=True, text=True)
    return rvalue


def _battery_is_charging():
    rvalue = subprocess.run(['cat', BATTERY_STATE_DEVICE], capture_output=True, text=True)
    rvalue = rvalue.stdout.strip('\n')

    if rvalue == "Charging":
        return True
    else:
        return False


def _set_static_screen_brightness(new_value):
    new_value = str(int(new_value))
    _run_light([LIGHT_CMD, "-s", SCREEN_DEVICE, "-S", new_value])


def _set_relative_screen_brightness(change):
    direction_flag, value = _convert_relative_string(change)
    _run_light([LIGHT_CMD, "-s", SCREEN_DEVICE, direction_flag, value])

  
def _set_static_kbd_brightness(new_value):
    new_value = str(int(new_value))
    _run_light([LIGHT_CMD, "-s", KBD_DEVICE, "-S", new_value])


def _set_relative_kbd_brightness(change):
    direction_flag, value = _convert_relative_string(change)
    _run_light([LIGHT_CMD, "-s", KBD_DEVICE, direction_flag, value])


def _update_lock_value_screen():
    global LOCK_VALUE_SCREEN
    LOCK_VALUE_SCREEN = _screen_brightness()


def _update_lock_value_kbd():
    global LOCK_VALUE_KBD 
    LOCK_VALUE_KBD = _kbd_brightness()


def _slow_change(current, target, steps, func):

    if current > target:
        steps = 0 - steps
    elif current < target:
        steps = steps

    for new_value in range(current, target, steps):
        func(new_value)
        time.sleep(0.005)


def _slow_dim_screen(target=10):
    _update_lock_value_screen()
    _slow_change(LOCK_VALUE_SCREEN, target, 1, _set_static_screen_brightness)


def _slow_dim_kbd(target=-1):
    _update_lock_value_kbd()
    _slow_change(LOCK_VALUE_KBD, target, 1, _set_static_kbd_brightness)


### Signal functions ###

def signal_idle_dim():
    _slow_dim_screen()    
    _slow_dim_kbd()


def signal_idle_blank():
    _slow_dim_screen(-1)    
    _slow_dim_kbd()

  
def signal_make_screen_brighter():
    current = _screen_brightness()
    _slow_change(current, current + 10, 1, _set_static_screen_brightness)


def signal_make_kbd_brighter():
    current = _kbd_brightness()
    _slow_change(current, current + 10, 1, _set_static_kbd_brightness)


def signal_make_screen_less_bright():
    current = _screen_brightness()
    _slow_change(current, current - 10, 1, _set_static_screen_brightness)


def signal_make_kbd_less_bright():
    current = _kbd_brightness()
    _slow_change(current, current - 10, 1, _set_static_kbd_brightness)


# Otherness
def signal_restore():
    _set_static_screen_brightness(LOCK_VALUE_SCREEN)
    _set_static_kbd_brightness(LOCK_VALUE_KBD)

def signal_unknown(args):
    return None


def passive_worker(args):

    
    return None







def main():

    # Number of seconds between each poll
    heart_rate = 1

    # Connect to fifo
    fifo_path = os.path.expanduser("~/.cache/power_manager_fifo")
    fifo = _connect_to_fifo(fifo_path)

    # Starter values

    fifo_str=""

    # Start main loop
    while True:
        time.sleep(heart_rate)
        fifo_str = fifo.read()

        if fifo_str != "":
            fifo_list = [x.replace("\n","") for x in fifo_str.split(" ") if x !=  ""]
            fifo_signal_name = fifo_list[0]

            if fifo_signal_name == "idle_dim":
                signal_idle_dim()

            elif fifo_signal_name == "idle_blank":
                signal_idle_blank()

            elif fifo_signal_name == "restore":
                signal_restore()
            
            elif fifo_signal_name == "screen_brighter":
                signal_make_screen_brighter()

            elif fifo_signal_name == "screen_less_bright":
                signal_make_screen_less_bright()

            elif fifo_signal_name == "kbd_brighter":
                signal_make_kbd_brighter()

            elif fifo_signal_name == "kbd_less_bright":
                signal_make_kbd_less_bright()



            else:
                # Unknown signal. Do nothing
                signal_unknown(fifo_list[1:])

                    
            
        else:
            # No signal
            passive_worker(None)





if __name__ == '__main__':
    main()
