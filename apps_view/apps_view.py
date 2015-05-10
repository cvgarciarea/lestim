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

    def __init__(self):
        Gtk.Window.__init__(self)

        self.visible = False
        self.timeout = None
        self.last_position = (0, 0)

        self.set_can_focus(True)
        self.set_border_width(50)
        self.set_keep_above(True)
        self.set_type_hint(Gdk.WindowTypeHint.SPLASHSCREEN)
        self.set_size_request(G.Sizes.DISPLAY_WIDTH, G.Sizes.DISPLAY_HEIGHT)
        self.move(-G.Sizes.DISPLAY_WIDTH, 0)
        self.add_events(Gdk.EventMask.KEY_PRESS_MASK)
        #print(self.get_position())

        self.vbox = Gtk.VBox()
        self.vbox.set_name('AppsBox')
        self.add(self.vbox)

        self.entry = AppsEntry()
        self.entry.connect('changed', self.search_app)
        self.vbox.pack_start(self.entry, False, False, 20)

        scrolled = Gtk.ScrolledWindow()
        self.vbox.pack_start(scrolled, True, True, 0)

        self.fbox = Gtk.FlowBox()
        self.fbox.set_name('AppsGrid')
        self.fbox.set_max_children_per_line(4)
        scrolled.add(self.fbox)

        self.connect('key-press-event', self.__key_press_event_cb)

        GObject.idle_add(self.show_all_apps)
        self.hide()

    def __run_app_cb(self, button):
        self.emit('run-app', button.app)
        self.reveal(False)

    def __favorited_app_cb(self, button):
        self.emit('favorited-app')

    def __key_press_event_cb(self, window, event):
        val = event.keyval
        print(val)
        if val == Gdk.KEY_Escape:
            self.reveal(False)

    def __reveal(self):
        self.show_all()
        def move():
            x, y = self.get_position()
            if x < 0:
                avance = (G.Sizes.DISPLAY_WIDTH - x) / 10.0
                x = x + avance
                self.move(x if x <= 0 else 0, 0)
                return True

            else:
                self.timeout = None
                return False

        if self.timeout:
            GObject.source_remove(self.timeout)

        self.timeout = GObject.timeout_add(20, move)

    def __disreveal(self):
        self.entry.set_text('')

        def move():
            x, y = self.get_position()
            if x > -G.Sizes.DISPLAY_WIDTH:
                avance = (x - G.Sizes.DISPLAY_WIDTH) / 10.0
                x = x + avance
                self.move(x if x >= -G.Sizes.DISPLAY_WIDTH else -G.Sizes.DISPLAY_WIDTH, 0)
                if self.get_position() != self.last_position:
                    self.last_position = self.get_position()

                else:
                    self.hide()
                    self.timeout = None
                    return False

                return True

            else:
                self.hide()
                self.timeout = None
                return False

        if self.timeout:
            GObject.source_remove(self.timeout)

        self.timeout = GObject.timeout_add(20, move)

    def show_all_apps(self, *args):
        for file in os.listdir(G.Paths.APPS_DIR):
            if not G.get_app(file):
                return

            button = AppButton(file, label=True, icon_size=64)
            button.set_hexpand(False)
            button.set_vexpand(False)
            button.connect('run-app', self.__run_app_cb)
            button.connect('favorited', self.__favorited_app_cb)
            self.fbox.add(button)
            button.show_all()

        self.show_all()

    def search_app(self, widget):
        for x in self.fbox.get_children():
            button = x.get_children()[0]
            if widget.get_text().lower() in button.app['name'].lower():
                x.show_all()

            else:
                x.hide()

    def reveal(self, visible):
        if visible != self.visible:
            self.visible = visible

            if visible:
                self.__reveal()

            else:
                self.__disreveal()
