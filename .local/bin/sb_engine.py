#!/bin/python3 -u

import json
import time
import datetime
import os
import subprocess
import re

default_color='#282828'
default_background='#458588'
default_background_alert='#cc241d'
default_background_inactive='#928374'
default_background_active='#98971a'
default_border='#252323'
default_align='center'
default_padding=4
default_min_width=10

#def mockup(name, color=default_color, background=default_background, border=default_border, align=default_align, min_width=default_min_width):
#    full_text='time'
#    return {'name':name, 'background':background,'color':color,'border':border,'full_text':full_text, 'align':align, 'min_width':full_text+(default_padding*' ')}

def mwireguard(name, color=default_color, background=default_background, border=default_border, align=default_align, min_width=default_min_width):
    mwg = subprocess.run(['ip','a','show'], capture_output=True, text=True)

    if 'mullvad' in mwg.stdout:
        full_text = ' Wireguard ON' 
    else:
        full_text = ' Wireguard OFF'
        if counter % 2: 
            background = default_background_alert
        else:
            background = default_background

    return {'name':name, 'background':background,'color':color,'border':border,'full_text':full_text, 'align':align, 'min_width':full_text+(default_padding*' ')}

def mbattery(name, color=default_color, background=default_background, border=default_border, align=default_align, min_width=default_min_width):
    bat_capacity = subprocess.run(['cat','/sys/class/power_supply/BAT0/capacity'], capture_output=True, text=True)
    bat_capacity = int([s for s in bat_capacity.stdout.split('\n')][0])  
    bat_status = subprocess.run(['cat','/sys/class/power_supply/BAT0/status'], capture_output=True, text=True)
    bat_status = bat_status.stdout.strip('\n')  


    if   bat_capacity >= 85:       full_text = 'i ' + str(bat_capacity) + '%'
    elif 60 <= bat_capacity <= 84: full_text = '  ' + str(bat_capacity) + '%'
    elif 40 <= bat_capacity <= 59: full_text = '  ' + str(bat_capacity) + '%'
    elif 15 <= bat_capacity <= 39: full_text = '  ' + str(bat_capacity) + '%'
    elif bat_capacity < 15 and bat_status != 'Charging':        
        full_text = '  ' + str(bat_capacity) + '%' 
        if counter % 2: 
            background = default_background_alert
        else:
            background = default_background

    return {'name':name, 'background':background,'color':color,'border':border,'full_text':full_text, 'align':align, 'min_width':full_text+(default_padding*' ')}

def mtime(name, color=default_color, background=default_background, border=default_border, align=default_align, min_width=default_min_width):
    full_text = ' ' + datetime.datetime.now().strftime("%H:%M") 
    return {'name':name, 'background':background,'color':color,'border':border,'full_text':full_text, 'align':align, 'min_width':full_text+(default_padding*' ')}


def mwifi(name, color=default_color, background=default_background, border=default_border, align=default_align, min_width=default_min_width):
    dev_status = subprocess.run(['iw', 'dev', 'wlp3s0', 'link'], capture_output=True, text=True)
    dev_status = [s for s in dev_status.stdout.split('\n')]  
    dev_status = [re.sub(r'\s', '', r) for r in dev_status[1:] if r is not '']

    result = [{}]
    for item in dev_status:
        key, val = item.split(":", 1)
        if key in result[-1]:
            result.append({})
        result[-1][key] = val
    
    SSID = result[0]['SSID']
    DB = int(result[0]['signal'].replace('-','').replace('dBm','')) // 20


    STRENGTH = DB * ' ' + (5 - DB) * ' '

    full_text = STRENGTH + SSID 
    return {'name':name, 'background':background,'color':color,'border':border,'full_text':full_text, 'align':align, 'min_width':full_text+(default_padding*' ')}


def mrecording(name, color=default_color, background=default_background, border=default_border, align=default_align, min_width=default_min_width):
    #    IS_RECORDING=$(pgrep wf-recorder > /dev/null 2>&1 && echo 'YES' || echo 'NO') 
    rec = subprocess.run(['pgrep','wf-recorder'],capture_output=True, text=True)
    rec = rec.stdout.strip('\n')

    if rec == '':
        full_text = ' Not recording'
        background = default_background_inactive
    else:
        full_text = ' Recording'
        background = default_background_active
    
    return {'name':name, 'background':background,'color':color,'border':border,'full_text':full_text, 'align':align, 'min_width':'  Not recording  '+(default_padding*' ')}


if __name__=='__main__':
    # Print header-string
    time.sleep(2)
    print('{"version":"1"}')
    print('[')
    counter = 0

    while True:
       

        collect = [mrecording('recording'), mwireguard('wireguard'), mwifi('wifi'), mbattery('battery'), mtime('time')]
        print(json.dumps(collect)+',')

        time.sleep(1)
        counter = counter + 1
        
