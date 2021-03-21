#!/bin/python

import yaml
import os

SOURCEFILE=os.path.expanduser("~/.config/alacritty/alacritty.yml")

with open(SOURCEFILE) as file:
    settings = yaml.load(file, Loader=yaml.FullLoader)

def to_shell(pre_text, dct, post_text=""):
    for key_name, value in dct.items():  
        if str(value)[:2] == "0x":
            actual_value = value[2:]
        else:
            actual_value = str(value)

        print('export {}{}{}="{}"'.format(pre_text.upper(), key_name.upper(), post_text.upper(), actual_value))

to_shell("theme_font_family_", settings["font"])
to_shell("theme_color_", settings["colors"]["primary"])
to_shell("theme_color_", settings["colors"]["normal"], "_normal")
to_shell("theme_color_", settings["colors"]["bright"], "_bright")
