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

from gi.repository import Gtk
from gi.repository import Gdk
from gi.repository import GObject

from panel.panel import AppButton
import globals as G


class AppsEntry(Gtk.Entry):

    __gtype_name__ = 'AppsEntry'

    def __init__(self):
        Gtk.Entry.__init__(self)

        self.set_placeholder_text('Search...')
        self.props.xalign = 0.015


class AppsView(Gtk.Window):

    __gtype_name__ = 'AppsView'

    __gsignals__ = {
        'run-app': (GObject.SIGNAL_RUN_FIRST, None, [object]),
        'favorited-app': (GObject.SIGNAL_RUN_FIRST, None, []),
        }

    def __init__(self, parent):
        Gtk.Window.__init__(self)

        self.visible = False
        self.timeout = None
        self.last_position = (0, 0)
        self.parent = parent
        self.row = 0
        self.column = 0

        #self.set_modal(True)
        self.set_can_focus(True)
        self.set_border_width(10)
        self.set_keep_above(True)
        self.set_transient_for(parent)
        self.add_events(Gdk.EventMask.KEY_PRESS_MASK)

        self.vbox = Gtk.VBox()
        self.vbox.set_name('AppsBox')
        self.add(self.vbox)

        self.entry = AppsEntry()
        self.entry.connect('changed', self.search_app)
        self.vbox.pack_start(self.entry, False, False, 20)

        scrolled = Gtk.ScrolledWindow()
        self.vbox.pack_start(scrolled, True, True, 0)

        self.grid = Gtk.Grid()
        self.grid.set_name('AppsGrid')
        scrolled.add(self.grid)

        self.connect('realize', self.__realize_cb)
        self.connect('focus-out-event', self.__focus_out_event_cb)
        #self.connect('key-press-event', self.__key_press_event_cb)

        GObject.idle_add(self.show_all_apps)
        self.reveal(False)

    def __realize_cb(self, window):
        win_x11 = self.get_window()
        win_x11.set_decorations(False)
        win_x11.process_all_updates()

    def __focus_out_event_cb(self, widget, event):
        self.reveal(False)

    def __run_app_cb(self, button):
        self.emit('run-app', button.app)
        self.reveal(False)

    def __favorited_app_cb(self, button):
        self.emit('favorited-app')

    def __key_press_event_cb(self, window, event):
        val = event.keyval
        if val == Gdk.KEY_Escape:
            self.reveal(False)
            return

        self.entry.grab_focus()

    def show_all_apps(self, title=''):
        self.row = 0
        self.column = -1
        apps = {}

        while self.grid.get_children():
            self.grid.remove(self.grid.get_children()[0])

        for file in os.listdir(G.Paths.APPS_DIR):
            if not G.get_app(file):
                continue

            app = G.get_app(file)
            if not title.lower() in app['name'].lower():
                continue


            apps[app['name']] = file

        names = list(apps.keys())
        names.sort()

        for name in names:
            file = apps[name]

            button = AppButton(file, label=True, icon_size=64)
            button.connect('run-app', self.__run_app_cb)
            button.connect('favorited', self.__favorited_app_cb)

            self.column += 1

            if self.column == 4:
                self.column = 0
                self.row += 1

            self.grid.attach(button, self.column, self.row, 1, 1)

            button.show_all()

        self.grid.show_all()

    def search_app(self, entry):
        GObject.idle_add(self.show_all_apps, entry.get_text())

    def reveal(self, visible):
        if visible != self.visible:
            self.visible = visible

            if visible:
                GObject.idle_add(self.entry.set_text, '')

                x, y = self.parent.panel.get_position()
                w, h = self.parent.panel.get_size()
                self.move(x + w + 10, y)

                self.set_size_request(G.Sizes.DISPLAY_WIDTH / 2, G.Sizes.DISPLAY_HEIGHT - y - 10)

                self.show_all()
                self.entry.grab_focus()

            else:
                self.hide()

