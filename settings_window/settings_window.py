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
from gi.repository import GObject
from gi.repository import GdkPixbuf

import globals as G


class SettingsWindow(Gtk.Window):

    __gtype_name__ = 'SettingsWindow'

    def __init__(self):
        Gtk.Window.__init__(self)

        self.headerbar = Gtk.HeaderBar()
        self.headerbar.set_show_close_button(True)

        self.vbox = Gtk.VBox()
        self.add(self.vbox)

        self.set_titlebar(self.headerbar)
        self.resize(840, 580)
        self.make_view_backgrounds()

        self.stack = Gtk.Stack()
        self.stack.set_transition_type(Gtk.StackTransitionType.SLIDE_LEFT_RIGHT)
        self.stack.set_transition_duration(200)
        self.stack.set_hexpand(True)
        self.stack.add_titled(self.background_selector, 'background', 'Background')
        self.vbox.pack_start(self.stack, True, True, 0)

        self.stack_switcher = Gtk.StackSwitcher()
        self.stack_switcher.set_stack(self.stack)
        self.headerbar.add(self.stack_switcher)

        self.connect('delete-event', self.__delete_event_cb)

        self.hide()

    def __delete_event_cb(self, window, event):
        self.hide()
        return True

    def make_view_backgrounds(self):
        # Permitir que se puedan seleccionar varios fondos, y seleccionar a cada
        # cuantos segundos pasan

        self.background_selector = Gtk.VBox()
        scrolled = Gtk.ScrolledWindow()
        box = Gtk.FlowBox()
        backgrounds = G.get_backgrounds()

        for x in backgrounds:
            if not os.path.exists(x):
                continue

            pixbuf = GdkPixbuf.Pixbuf.new_from_file_at_size(x, 200, 100)
            image = Gtk.Image.new_from_pixbuf(pixbuf)
            image.file = x
            box.add(image)

        box.first_time = True
        box.set_homogeneous(True)
        box.set_selection_mode(Gtk.SelectionMode.SINGLE)
        box.connect('selected-children-changed', self.set_background)

        scrolled.add(box)
        self.background_selector.add(scrolled)

    def set_background(self, widget):
        if widget.first_time:
            widget.first_time = False
            widget.unselect_all()
            return

        if widget.get_selected_children():
            image = widget.get_selected_children()[0].get_children()[0]
            file = image.file

            if os.path.isfile(file):
                GObject.idle_add(G.set_background, file, True)
