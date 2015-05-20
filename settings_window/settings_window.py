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

        self.stack = Gtk.Stack()
        self.stack.set_transition_type(Gtk.StackTransitionType.SLIDE_LEFT_RIGHT)
        self.stack.set_transition_duration(200)
        self.stack.set_hexpand(True)
        self.vbox.pack_start(self.stack, True, True, 0)

        self.stack_switcher = Gtk.StackSwitcher()
        self.stack_switcher.set_stack(self.stack)
        self.headerbar.set_custom_title(self.stack_switcher)

        self.make_backgrounds_section()
        self.make_panel_section()

        self.connect('delete-event', self.__delete_event_cb)

        self.hide()

    def __delete_event_cb(self, window, event):
        self.hide()
        return True

    def make_backgrounds_section(self):
        # Permitir que se puedan seleccionar varios fondos, y seleccionar a cada
        # cuantos segundos pasan

        vbox = Gtk.VBox()

        scrolled = Gtk.ScrolledWindow()
        vbox.pack_start(scrolled, True, True, 0)

        box = Gtk.FlowBox()
        box.first_time = True
        box.set_homogeneous(True)
        box.set_selection_mode(Gtk.SelectionMode.SINGLE)
        box.connect('selected-children-changed', self.background_changed)
        scrolled.add(box)

        backgrounds = G.get_backgrounds()

        for x in backgrounds:
            if not os.path.exists(x):
                continue

            pixbuf = GdkPixbuf.Pixbuf.new_from_file_at_size(x, 200, 100)
            image = Gtk.Image.new_from_pixbuf(pixbuf)
            image.file = x
            box.add(image)

        self.stack.add_titled(vbox, 'background', 'Background')

    def make_panel_section(self):
        def make_row(label):
            row = Gtk.ListBoxRow()
            box.add(row)

            hbox = Gtk.HBox()
            hbox.set_border_width(10)
            hbox.pack_start(Gtk.Label(label), False, False, 0)
            row.add(hbox)

            return (row, hbox)

        settings = G.get_settings()

        vbox = Gtk.VBox()
        vbox.set_border_width(30)

        box = Gtk.HBox()
        vbox.add(box)

        scrolled = Gtk.ScrolledWindow()
        scrolled.set_size_request(400, -1)
        box.pack_start(scrolled, True, False, 0)

        box = Gtk.ListBox()
        box.set_selection_mode(Gtk.SelectionMode.NONE)
        scrolled.add(box)

        row, hbox = make_row('Orientation')
        combo = Gtk.ComboBoxText()
        combo.append_text('Top')
        combo.append_text('Bottom')
        combo.append_text('Left')
        combo.set_active({'Top': 0, 'Bottom': 1, 'Left': 2}[settings['panel-orientation']])
        combo.connect('changed', self.panel_orientation_changed)
        hbox.pack_end(combo, False, False, 0)

        row, hbox = make_row('Autohide')
        switch = Gtk.Switch()
        switch.set_active(settings['panel-autohide'])
        switch.connect('notify::active', self.panel_autohide_changed)
        hbox.pack_end(switch, False, False, 0)

        row, hbox = make_row('Expand')
        switch = Gtk.Switch()
        switch.set_active(settings['panel-expand'])
        switch.connect('notify::active', self.panel_expand_changed)
        hbox.pack_end(switch, False, False, 0)

        row, hbox = make_row('Reserve screen space')
        switch = Gtk.Switch()
        switch.set_active(settings['panel-space-reserved'])
        switch.connect('notify::active', self.panel_reserve_space_changed)
        hbox.pack_end(switch, False, False, 0)

        self.stack.add_titled(vbox, 'panel', 'Panel')

    def background_changed(self, widget):
        if widget.first_time:
            widget.first_time = False
            widget.unselect_all()
            return

        if widget.get_selected_children():
            image = widget.get_selected_children()[0].get_children()[0]
            file = image.file

            if os.path.isfile(file):
                GObject.idle_add(G.set_background, file, True)

    def panel_orientation_changed(self, combo):
        values = {0: 'Top', 1: 'Bottom', 2: 'Left'}
        value = values[combo.get_active()]
        G.set_a_setting('panel-orientation', value)

    def panel_autohide_changed(self, switch, gparam):
        G.set_a_setting('panel-autohide', switch.get_active())

    def panel_expand_changed(self, switch, gparam):
        G.set_a_setting('panel-expand', switch.get_active())

    def panel_reserve_space_changed(self, switch, gparam):
        G.set_a_setting('panel-space-reserved', switch.get_active())

