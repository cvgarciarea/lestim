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
import re
import sys
import time
import json
import signal
import datetime
import threading
import subprocess
import configparser
from Xlib import display

from ctypes import cdll
from ctypes import byref
from ctypes import create_string_buffer

try:
    import PIL
    from PIL import Image as image

except:
    image = None

from gi.repository import Gtk
from gi.repository import Gdk
from gi.repository import Gio
from gi.repository import GLib
from gi.repository import Wnck
from gi.repository import GObject
from gi.repository import GdkPixbuf


_SCREEN = Gdk.Screen.get_default()
_CSS_PROVIDER = Gtk.CssProvider()
_STYLE_CONTEXT = Gtk.StyleContext()
_DISPLAY = display.Display()
_ICON_THEME = Gtk.IconTheme.get_for_screen(_SCREEN)
_WEEK_DAYS = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']
_ORIGIN_STDOUT = sys.stdout
_OUT_FILE = open('/tmp/lestim.log', 'w')

sys.stdout = _OUT_FILE


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
    LOCAL_BACKGROUND_PATH = os.path.join(os.path.dirname(__file__), 'backgrounds/robocopred.jpg')
    LOCAL_BACKGROUNDS_DIR = os.path.join(os.path.dirname(__file__), 'backgrounds')
    IMAGES_DIR = GLib.get_user_special_dir(GLib.USER_DIRECTORY_PICTURES)

    SYSTEM_BACKGROUNDS_DIR = '/usr/share/backgrounds'
    APPS_DIR = '/usr/share/applications'

    ICON_SHUTDOWN = os.path.join(os.path.dirname(__file__), 'icons/shutdown.svg')
    ICON_REBOOT = os.path.join(os.path.dirname(__file__), 'icons/reboot.svg')
    ICON_LOCK = os.path.join(os.path.dirname(__file__), 'icons/lock.svg')
    ICON_SETTINGS = os.path.join(os.path.dirname(__file__), 'icons/settings.svg')

    DESKTOP_DIR = GLib.get_user_special_dir(GLib.USER_DIRECTORY_DESKTOP)

    CALENDAR_PATH = os.path.join(WORK_DIR, 'calendar_data.json')


class MouseDetector(GObject.GObject):

    __gsignals__ = {
        'mouse-motion': (GObject.SIGNAL_RUN_FIRST, None, [int, int]),
    }

    def __init__(self):
        GObject.GObject.__init__(self)

        self.position = (0, 0)

    def start(self):
        GObject.timeout_add(200, self.__detect_position)

    def __detect_position(self):
        x, y = self.get_position()
        if (x, y) != self.position:
            self.position = (x, y)
            self.emit('mouse-motion', x, y)

        return True

    def get_position(self):
        coord = _DISPLAY.screen().root.query_pointer()._data
        x, y = coord['root_x'], coord['root_y']
        return(x, y)


class WindowPositionDetector(GObject.GObject):

    __gsignals__ = {
        'show-panel': (GObject.SIGNAL_RUN_FIRST, None, []),
        'hide-panel': (GObject.SIGNAL_RUN_FIRST, None, [])
    }

    def __init__(self, panel):
        GObject.GObject.__init__(self)

        self.panel = panel
        self.panel_visible = True
        self.screen = Wnck.Screen.get_default()

    def start(self):
        GObject.timeout_add(200, self.__detect_position)

    def __detect_position(self):
        for window in self.screen.get_windows():
            if not window.is_active() or window.get_name() == 'lestim':
                continue

            x1, y1, w1, h1 = window.get_geometry()
            x2, y2 = self.panel.get_position()
            w2, h2 = self.panel.get_size()

            if self.panel.visible and (x1 <= x2 + w2):# and ((y1 >= y2) or ((y1 + w1 >= y2) and (y1 + w1 <= y2 + h2))):
                self.panel_visible = False
                self.emit('hide-panel')

            elif not self.panel.visible and (x1 > w2):
                self.panel_visible = True
                self.emit('show-panel')

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


class ScanFolder(GObject.GObject):

    __gsignals__ = {
        'files-changed': (GObject.SIGNAL_RUN_FIRST, None, [object]),
        'realized-searching': (GObject.SIGNAL_RUN_FIRST, None, []),
        }

    def __init__(self, folder=None, timeout=500):

        GObject.GObject.__init__(self)

        self.folder = folder if folder else Paths.DESKTOP_DIR
        self.time_lapsus = timeout
        self.files = []
        self.show_hidden_files = False
        self.can_scan = True
        self.mounts = {}

    def __natural_sort(self, _list):
        convert = lambda text: int(text) if text.isdigit() else text.lower()
        alphanum_key = lambda key: [convert(c) for c in re.split('([0-9]+)', key)]
        return sorted(_list, key=alphanum_key)

    def start(self):
        GObject.timeout_add(self.time_lapsus, self.scan)

    def scan(self, force=False):
        if not self.can_scan:
            return True

        files = []
        directories = []

        if (self.files != self.get_files()) or force:
            self.files = self.get_files()

            self.emit('files-changed', self.files)

        self.emit('realized-searching')

        return True

    def set_folder(self, folder):
        self.folder = folder
        GObject.idle_add(self.scan)

    def get_files(self):
        directories = []
        files = []
        if os.path.isdir(self.folder):
            _files = os.listdir(self.folder)

        else:
            self.folder = get_parent_directory(self.folder)
            return

        for name in _files:
            filename = os.path.join(self.folder, name)

            if (not name.startswith('.') and not name.endswith('~')) or \
                    self.show_hidden_files:

                if os.path.isdir(filename):
                    directories.append(filename)

                elif os.path.isfile(filename):
                    files.append(filename)

        directories = self.__natural_sort(directories)
        files = self.__natural_sort(files)

        return directories + files

    def set_show_hidden_files(self, if_show):
        if type(if_show) != bool:
            raise TypeError(_('The parameter must to be a bool'))

        self.show_hidden_files = if_show
        GObject.idle_add(self.scan)


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
                'panel-orientation': 'Left',
                'panel-autohide': True,
                'panel-expand': False,
                'panel-space-reserved': False,
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


def get_name(path):
    # In cases where directories ending in '/', when directory.split('/')[-1]
    # will return '', but this function returns the correct name.

    name = '/'
    for x in path.split('/'):
        if not x:
            continue

        name = x

    return name


def get_file_name(path):
    if path.endswith('.desktop'):
        cfg = configparser.ConfigParser()
        cfg.read([path])

        if cfg.has_option('Desktop Entry', 'Name'):
            return cfg.get('Desktop Entry', 'Name')

    return get_name(path)


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


def set_a_setting(setting, value):
    settings = get_settings()
    settings[setting] = value
    set_settings(settings)


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
    value = subprocess.check_output("xrandr --verbose | grep -i brightness | cut -f2 -d ' '", shell=True)
    value = str(value)

    if(value != ''):
        value = int(float(value[2:-3]) * 100)

    else:
        value = 50

    return value


def set_brightness(value):
    monitor = subprocess.check_output("xrandr -q | grep ' connected' | cut -d ' ' -f1", shell=True)
    monitor = str(monitor)

    if(monitor != ''):
        monitor = monitor[2:-3]

    if value >= 2:
        value /= 100.0

    cmdStatus = subprocess.check_output("xrandr --output %s --brightness %.2f" % (monitor, value), shell=True)


def get_saved_events(date):
    check_paths()

    if not os.path.exists(Paths.CALENDAR_PATH) or not open(Paths.CALENDAR_PATH).read():
        return {}

    with open(Paths.CALENDAR_PATH) as file:
        data = json.load(file)
        return data[date] if date in data else {}


def save_event(date, name, description):
    """
    Event structur:
        {
            date1: {
                name1.1: description1.1,
                name1.2: description1.2,
                name1.3: description1.3
            },

            date2: {
                name2.1: description2.1,
                name2.2: description2.2,
                name2.3: description2.3
            },
        }
    """

    check_paths()

    if not os.path.exists(Paths.CALENDAR_PATH) or not open(Paths.CALENDAR_PATH).read():
        data = {}

    else:
        with open(Paths.CALENDAR_PATH) as file:
            data = json.load(file)

    if not date in data:
        date[data] = []

    data[date].append({name: description})

    with open(Paths.CALENDAR_PATH, 'w') as file:
        file.write(json.dumps(data))


def kill_proccess(signal, frame):
    sys.stdout = _ORIGIN_STDOUT
    _OUT_FILE.close()
    sys.exit(0)


def set_process_name():
    libc = cdll.LoadLibrary('libc.so.6')
    buff = create_string_buffer(7)  # len('lestim') + 1
    buff.value = b'lestim'
    libc.prctl(15, byref(buff), 0, 0, 0)


set_process_name()
check_paths()
signal.signal(signal.SIGTERM, kill_proccess)
