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
import sys

INSTALL_DIR = '/usr/share/lestim'

EXECUTABLE_PATH = '/usr/bin/lestim'
LOCAL_EXECUTABLE_PATH = os.path.join(os.path.dirname(__file__), 'lestim')

# Directories needed
APPS_VIEW_DIR = os.path.join(os.path.dirname(__file__), 'apps_view')
BACKGROUNDS_DIR = os.path.join(os.path.dirname(__file__), 'backgrounds')
ICONS_DIR = os.path.join(os.path.dirname(__file__), 'icons')
LATERAL_PANEL_DIR = os.path.join(os.path.dirname(__file__), 'lateral_panel')
MODULES_DIR = os.path.join(os.path.dirname(__file__), 'modules')
PANEL_DIR = os.path.join(os.path.dirname(__file__), 'panel')
SETTINGS_WINDOW_DIR = os.path.join(os.path.dirname(__file__), 'settings_window')
DIRECTORIES_NEEDED = [APPS_VIEW_DIR,
                      BACKGROUNDS_DIR,
                      ICONS_DIR,
                      LATERAL_PANEL_DIR,
                      MODULES_DIR,
                      PANEL_DIR,
                      SETTINGS_WINDOW_DIR]

# Files needed
GLOBALS_FILE = os.path.join(os.path.dirname(__file__), 'globals.py')
LESTIM_FILE = os.path.join(os.path.dirname(__file__), 'Lestim.py')
LICENSE_FILE = os.path.join(os.path.dirname(__file__), 'LICENSE')
THEME_FILE = os.path.join(os.path.dirname(__file__), 'theme.css')
WIDGETS_FILE = os.path.join(os.path.dirname(__file__), 'widgets.py')
FILES_NEEDED = [GLOBALS_FILE,
                LESTIM_FILE,
                LICENSE_FILE,
                THEME_FILE,
                WIDGETS_FILE]

DESKTOP_FILE_PATH = '/usr/share/xsessions'
DESKTOP_FILE = '''[Desktop Entry]
Encoding=UTF-8
Name=Lestim
Comment=Lestim Desktop Environment
Exec=lestim
Icon=
Type=Application
'''

if os.path.isdir(INSTALL_DIR):
    if os.access(INSTALL_DIR, os.W_OK):
        os.system('rm -r %s' % INSTALL_DIR)

    else:
        sys.exit('Error: You must execute this script with user root permissions')

# Creating install directory
if os.access(path, os.W_OK):
    os.makedirs(INSTALL_DIR)
    print('%s created successfully' % INSTALL_DIR)

else:
    sys.exit('Error: You must execute this script with user root permissions')

if not os.path.isdir(DESKTOP_FILE_PATH):
    os.makedirs(DESKTOP_FILE_PATH)
    print('%s created successfully' % DESKTOP_FILE_PATH)

# Creating executable file
os.system('cp %s %s' % (LOCAL_EXECUTABLE_PATH, EXECUTABLE_PATH))
print('%s created successfully' % EXECUTABLE_PATH)

os.system('chmod +x %s' % EXECUTABLE_PATH)
print('%s permissions given successfully' % EXECUTABLE_PATH)

# Creating the xsessions file
_file = open(os.path.join(DESKTOP_FILE_PATH, 'lestim.desktop'), 'w')
_file.write(DESKTOP_FILE)
_file.close()

print('%s created successfully' % DESKTOP_FILE_PATH)

# Copying needed directories and files
for directory in DIRECTORIES_NEEDED:
    os.system('cp -r %s %s' % (directory, INSTALL_DIR))
    print('%s created successfully' % os.path.join(INSTALL_DIR, directory))

for _file in FILES_NEEDED:
    os.system('cp %s %s' % (_file, INSTALL_DIR))
    print('%s created successfully' % os.path.join(INSTALL_DIR, _file))
