#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# Copyright (C) 2015, Cristian García <cristian99garcia@gmail.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

import os
import time
import json
import datetime
import threading
import subprocess
import configparser
from Xlib import display

try:
    import PIL
    from PIL import Image as image

except:
    image = None

from gi.repository import Gtk
from gi.repository import Gdk
from gi.repository import Gio
from gi.repository import GLib
from gi.repository import GObject
from gi.repository import GdkPixbuf



_SCREEN = Gdk.Screen.get_default()
_CSS_PROVIDER = Gtk.CssProvider()
_STYLE_CONTEXT = Gtk.StyleContext()
_DISPLAY = display.Display()
_ICON_THEME = Gtk.IconTheme.get_for_screen(_SCREEN)
_WEEK_DAYS = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']


class Sizes:
    DISPLAY_WIDTH = _SCREEN.width()
    DISPLAY_HEIGHT = _SCREEN.height()
    DISPLAY_SIZE = (DISPLAY_WIDTH, DISPLAY_HEIGHT)


class Paths:
    WORK_DIR = os.path.expanduser('~/.config/lestim/')
    SETTINGS_PATH = os.path.join(WORK_DIR, 'settings.json')
    THEME_PATH = os.path.join(WORK_DIR, 'theme.css')
    LOCAL_THEME_PATH = os.path.join(os.path.dirname(__file__), 'theme.css')

    BACKGROUNDS_DIR = os.path.join(WORK_DIR, 'backgrounds')
    BACKGROUND_PATH = os.path.join(WORK_DIR, 'background')
    LOCAL_BACKGROUND_PATH = os.path.join(os.path.dirname(__file__), 'backgrounds/colorful.jpg')
    LOCAL_BACKGROUNDS_DIR = os.path.join(os.path.dirname(__file__), 'backgrounds')
    IMAGES_DIR = GLib.get_user_special_dir(GLib.USER_DIRECTORY_PICTURES)

    SYSTEM_BACKGROUNDS_DIR = '/usr/share/backgrounds'
    APPS_DIR = '/usr/share/applications'

    ICON_SHUTDOWN = os.path.join(os.path.dirname(__file__), 'icons/shutdown.svg')
    ICON_REBOOT = os.path.join(os.path.dirname(__file__), 'icons/reboot.svg')
    ICON_LOCK = os.path.join(os.path.dirname(__file__), 'icons/lock.svg')
    ICON_SETTINGS = os.path.join(os.path.dirname(__file__), 'icons/settings.svg')


class MouseDetector(GObject.GObject):

    __gsignals__ = {
        'mouse-motion': (GObject.SIGNAL_RUN_FIRST, None, [int, int]),
    }

    def __init__(self):
        GObject.GObject.__init__(self)

        self.position = (0, 0)

        GObject.timeout_add(200, self.__detect_position)

    def __detect_position(self):
        coord = _DISPLAY.screen().root.query_pointer()._data
        x, y = coord['root_x'], coord['root_y']
        if (x, y) != self.position:
            self.position = (x, y)
            self.emit('mouse-motion', x, y)

        return True


class BatteryDeamon(GObject.GObject):

    __gsignals__ = {
        'percentage-changed': (GObject.SIGNAL_RUN_FIRST, None, [int]),
        'state-changed': (GObject.SIGNAL_RUN_FIRST, None, [str])
    }

    def __init__(self):
        GObject.GObject.__init__(self)

        self.percentage = 0
        self.state = None

    def start(self):
        GObject.timeout_add(1000, self.check)

    def check(self):
        GObject.idle_add(self.check_state)
        GObject.idle_add(self.check_percentage)
        return True

    def check_state(self):
        with open('/sys/class/power_supply/BAT1/status') as _file:
            text = _file.read().replace(' ', '').replace('\n', '')

        if text != self.state:
            self.state = text
            self.emit('state-changed', text)

    def check_percentage(self):
        command = "upower -i $(upower -e | grep BAT) | grep --color=never -E percentage|xargs|cut -d' ' -f2|sed s/%//"
        percentage = subprocess.Popen(['/bin/bash', '-c', command], stdout=subprocess.PIPE)
        out, err = percentage.communicate()
        if int(out) != self.percentage:
            self.percentage = int(out)
            self.emit('percentage-changed', self.percentage)


def check_paths():
    if not os.path.isdir(Paths.WORK_DIR):
        os.makedirs(Paths.WORK_DIR)

    if not os.path.isdir(Paths.BACKGROUNDS_DIR):
        os.makedirs(Paths.BACKGROUNDS_DIR)

        for x in os.listdir(Paths.LOCAL_BACKGROUNDS_DIR):
            p = os.path.join(Paths.LOCAL_BACKGROUNDS_DIR, x)
            os.system('cp %s %s' % (p, Paths.BACKGROUNDS_DIR))

    if not os.path.islink(Paths.BACKGROUND_PATH):
        if os.path.exists(Paths.BACKGROUND_PATH):
            os.remove(Paths.BACKGROUND_PATH)

        os.symlink(Paths.LOCAL_BACKGROUND_PATH, Paths.BACKGROUND_PATH)

    if not os.path.isfile(Paths.THEME_PATH):
        os.system('cp %s %s' % (Paths.LOCAL_THEME_PATH, Paths.THEME_PATH))

    if not os.path.isfile(Paths.SETTINGS_PATH):
        data = {'icon-size': 48,
                'ever-panel-visible': True,
                'favorites-apps': []}

        with open(Paths.SETTINGS_PATH, 'w') as file:
            file.write(json.dumps(data))
            file.close()


def set_theme():
    _STYLE_CONTEXT.remove_provider_for_screen(_SCREEN, _CSS_PROVIDER)
    _CSS_PROVIDER.load_from_path(Paths.THEME_PATH)
    _STYLE_CONTEXT.add_provider_for_screen(
        _SCREEN,
        _CSS_PROVIDER,
        Gtk.STYLE_PROVIDER_PRIORITY_USER)


def get_icon(path, size=48):
    pixbuf = _ICON_THEME.load_icon('gtk-file', size, 0)

    if '/' in path:
        file = Gio.File.new_for_path(path)
        info = file.query_info('standard::icon',
                               Gio.FileQueryInfoFlags.NOFOLLOW_SYMLINKS, None)

        icon = info.get_icon()
        types = icon.get_names()

        if 'image-x-generic' in types:
            pixbuf = GdkPixbuf.Pixbuf.new_from_file_at_size(path, size, size)

        else:
            if path.endswith('.desktop'):
                cfg = configparser.ConfigParser()
                cfg.read([path])

                if cfg.has_option('Desktop Entry', 'Icon'):
                    if '/' in cfg.get('Desktop Entry', 'Icon'):
                        data = cfg.get('Desktop Entry', 'Icon')
                        pixbuf = GdkPixbuf.Pixbuf.new_from_file_at_size(
                            data, size, size)

                    else:
                        pixbuf = _ICON_THEME.load_icon(cfg.get('Desktop Entry',
                                                               'Icon'), size, 0)

                else:
                    pixbuf = _ICON_THEME.load_icon('gtk-file', size, 0)

            else:
                try:
                    pixbuf = _ICON_THEME.choose_icon(types, size, 0).load_icon()

                except:
                    pixbuf = _ICON_THEME.load_icon('gtk-file', size, 0)

    else:
        if '.' in path:
            path = path.split('.')[0]

        pixbuf = _ICON_THEME.load_icon(path if _ICON_THEME.has_icon(path) else 'gtk-file', size, 0)

    return pixbuf


def run_app(app):
    def run():
        os.system(app['execute'])

    thread = threading.Thread(target=run)
    thread.start()


def get_current_time():
    _time = time.localtime()
    h = str(_time.tm_hour)
    m = str(_time.tm_min)
    text = ('0' + h if len(h) == 1 else h) + ':' + ('0' + m if len(m) == 1 else m)
    return text


def get_week_day():
    day = datetime.datetime.today().weekday()
    return _WEEK_DAYS[day]


def get_app(file):
    app = None

    if file.endswith('.desktop'):
        file = os.path.join(Paths.APPS_DIR, file)
        cfg = configparser.ConfigParser()
        name = None
        icon = None
        execute = None

        # No use configparser, has errors in this files

        text = open(file, 'r').read()
        for line in text.splitlines():
            if line.startswith('Name') and not name:
                name = line.split('=')[1]

            elif line.startswith('Icon') and not icon:
                icon = line.split('=')[1]

            elif line.startswith('Exec') and not execute:
                execute = line.split('=')[1].split('%')[0]

            if name and icon and execute:
                break

        if not icon:
            icon = 'text-x-preview'

        if name and execute:
            app = {'name': name,
                   'icon': icon,
                   'execute': execute}

    return app


def get_settings():
    check_paths()

    with open(Paths.SETTINGS_PATH) as file:
        return json.load(file)


def set_settings(settings):
    check_paths()

    with open(Paths.SETTINGS_PATH, 'w') as file:
        file.write(json.dumps(settings))
        file.close()


def get_backgrounds():
    check_paths()

    list = []
    images = []
    supported = ['jpg', 'jpeg', 'png', '.gif', '.svg']

    if os.path.exists(Paths.SYSTEM_BACKGROUNDS_DIR):
        for x in os.listdir(Paths.SYSTEM_BACKGROUNDS_DIR):
            path = os.path.join(Paths.SYSTEM_BACKGROUNDS_DIR, x)

            if os.path.isdir(path):
                for _x in os.listdir(path):
                    if '.' in _x and _x.split('.')[-1] in supported:
                        list.append(os.path.join(path, _x))

            elif os.path.isfile(path):
                if '.' in path and path.split('.')[-1] in supported:
                    list.append(path)

    for x in os.listdir(Paths.BACKGROUNDS_DIR):
        path = os.path.join(Paths.BACKGROUNDS_DIR, x)
        if '.' in x and path.split('.')[-1] in supported:
            list.append(path)

    for x in os.listdir(Paths.IMAGES_DIR):
        path = os.path.join(Paths.IMAGES_DIR, x)
        if '.' in x and path.split('.')[-1] in supported:
            list.append(path)

    for image in list:
        if ' ' in image:
            image = image.replace(' ', '\ ')

        images.append(image)

    return images


def set_background(background=Paths.LOCAL_BACKGROUND_PATH, load_theme=False):
    if os.path.exists(Paths.BACKGROUND_PATH):
        os.remove(Paths.BACKGROUND_PATH)

    if image and '.' in background.split('/')[-1]:
        ext = background.split('.')[-1]
        basewidth = Sizes.DISPLAY_WIDTH
        img = image.open(background)
        img = img.resize(Sizes.DISPLAY_SIZE, PIL.Image.ANTIALIAS)
        img.save(Paths.BACKGROUND_PATH + '.' + ext)
        os.system('mv %s %s' % (Paths.BACKGROUND_PATH + '.' + ext, Paths.BACKGROUND_PATH))

    else:
        os.symlink(background, Paths.BACKGROUND_PATH)

    if load_theme:
        set_theme()


def get_actual_volume():
    output = subprocess.Popen(["amixer", "get", 'Master'], stdout=subprocess.PIPE).communicate()[0]
    return int(str(output.splitlines()[-1]).split(' ')[-2][1:-2])


def set_volume(value):
    os.system('amixer set Master,0 ' + str(int(value)) + '%')


def get_actual_brightness():
    valor = subprocess.check_output("xrandr --verbose | grep -i brightness | cut -f2 -d ' '", shell=True)
    if(valor != ""):
        valor = valor.split('\n')[0]
        valor = int(float(valor) * 100)
    else:
        valor = ""
    return valor


def set_brightness(valor):
    monitor = subprocess.check_output("xrandr -q | grep ' connected' | cut -d ' ' -f1", shell=True)
    if(monitor != ""):
        monitor = monitor.split('\n')[0]

    if valor >= 2:
        valor /= 100.0

    cmdStatus = subprocess.check_output("xrandr --output %s --brightness %.2f" % (monitor, valor), shell=True)


def set_process_name():
    from ctypes import cdll, byref, create_string_buffer
    libc = cdll.LoadLibrary('libc.so.6')
    buff = create_string_buffer(7)  # len('lestim') + 1
    buff.value = b'lestim'
    libc.prctl(15, byref(buff), 0, 0, 0)


set_process_name()
check_paths()
