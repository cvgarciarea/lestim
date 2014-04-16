#!/usr/bin/env python
# -*- coding: utf-8 -*-

#  brightness.py por:
#     Cristian García: cristian99garcia@gmail.com
#
#  Basado en:
#      http://bazaar.launchpad.net/~indicator-brightness/indicator-brightness/trunk/view/head:/indicator-brightness

import subprocess
import commands


def get_min_brightness():

    return 0


def get_max_brightness():

    try:
        maximo = int(commands.getoutput('/usr/lib/gnome-settings-daemon/gsd-backlight-helper --get-max-brightness'))

    except:
        maximo = 0

    return maximo


def get_current_brightness():

    try:
        actual = int(commands.getoutput('/usr/lib/gnome-settings-daemon/gsd-backlight-helper --get-brightness'))

    except:
        actual = 0

    return actual


def set_brightness(brillo):

    subprocess.call(['pkexec','/usr/lib/gnome-settings-daemon/gsd-backlight-helper','--set-brightness',"%d" % brillo])