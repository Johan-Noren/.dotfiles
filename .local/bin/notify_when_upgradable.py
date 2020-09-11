#!/usr/bin/python3

import time
import os
import sys
import subprocess
import random

def check_updates():
    a = subprocess.run(['checkupdates'], capture_output=True, text=True)
    a = [x.split(' ')[0] for x in a.stdout.split('\n')]
    a.remove('')

    return a

def notify(header, body):
    subprocess.run(['/usr/bin/notify-send --category=checkupdates', header, body])


if __name__ == '__main__':

    try:
        delay = int(sys.argv[1])
    except:
        delay = 43200

    time.sleep(random.randint(120,999))

    while True:

        updates = check_updates()
        header = 'There are ' + str(len(updates)) + ' available updates'
        body = [' -'+ str(x) for x in updates]
        body = '\n'.join(body)

        if len(updates) != 0:
            notify(header, body)

        time.sleep(delay)
