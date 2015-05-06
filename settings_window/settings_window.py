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

        headerbar = Gtk.HeaderBar()
        self.vbox = Gtk.VBox()
        self.notebook = Gtk.Notebook()

        self.make_view_backgrounds()

        headerbar.set_show_close_button(True)
        self.notebook.append_page(self.background_selector, Gtk.Label('Desktop'))
        self.set_titlebar(headerbar)
        self.resize(840, 580)

        self.vbox.pack_start(self.notebook, True, True, 2)
        self.add(self.vbox)
        self.hide()

    def make_view_backgrounds(self):
        # Permitir que se puedan seleccionar varios fondos, y seleccionar a cada
        # cuantos segundos pasan

        self.background_selector = Gtk.VBox()
        scrolled = Gtk.ScrolledWindow()
        hbox = Gtk.HBox()
        ok_button = Gtk.Button('Ok')#.new_from_stock(Gtk.STOCK_OK)
        box = Gtk.FlowBox()
        backgrounds = G.get_backgrounds()

        for x in backgrounds:
            if not os.path.exists(x):
                continue

            pixbuf = GdkPixbuf.Pixbuf.new_from_file_at_size(x, 300, 150)
            image = Gtk.Image.new_from_pixbuf(pixbuf)
            image.file = x
            box.add(image)

        box.set_homogeneous(True)
        box.set_selection_mode(Gtk.SelectionMode.SINGLE)
        box.unselect_all()

        box.connect('selected-children-changed', self.set_background)

        hbox.pack_end(ok_button, False, False, 2)
        scrolled.add(box)
        self.background_selector.add(scrolled)
        self.background_selector.pack_end(hbox, False, False, 2)

    def set_background(self, widget):
        if widget.get_selected_children():
            image = widget.get_selected_children()[0].get_children()[0]
            file = image.file

            GObject.idle_add(G.set_background, file, True)
