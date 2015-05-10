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
from gi.repository import Pango
from gi.repository import GObject

import globals as G


class CalendarItem(Gtk.VBox):

    def __init__(self):
        Gtk.VBox.__init__(self)

        box = Gtk.EventBox()
        box.connect('button-press-event', self.__revealer_calendar)
        self.time_label = Gtk.Label()
        self.time_label.modify_font(Pango.FontDescription('Bold 35'))
        box.add(self.time_label)
        self.pack_start(box, False, False, 0)

        box = Gtk.EventBox()
        box.connect('button-press-event', self.__revealer_calendar)
        self.day_label = Gtk.Label()
        self.day_label.modify_font(Pango.FontDescription('12'))
        box.add(self.day_label)
        self.pack_start(box, False, False, 0)

        self.revealer = Gtk.Revealer()
        self.revealer.set_reveal_child(False)
        calendar = Gtk.Calendar()
        self.revealer.add(calendar)
        self.pack_start(self.revealer, False, False, 0)

        GObject.timeout_add(1000, self.__update_data)

    def __update_data(self):
        self.time_label.set_label(G.get_current_time())
        self.day_label.set_label(G.get_week_day())
        return True

    def __revealer_calendar(self, box, event):
        self.revealer.set_reveal_child(not self.revealer.get_reveal_child())


class ShutdownButton(Gtk.Button):

    __gtype_name__ = 'ShutdownButton'

    def __init__(self):
        Gtk.Button.__init__(self)

        self.image = Gtk.Image.new_from_file(G.Paths.ICON_SHUTDOWN)
        self.set_tooltip_text('Shutdown')
        self.add(self.image)

        self.connect('clicked', self.__clicked_cb)

    def __clicked_cb(self, button):
        os.system('killall lestim')


class RebootButton(Gtk.Button):

    __gtype_name__ = 'RebootButton'

    def __init__(self):
        Gtk.Button.__init__(self)

        self.image = Gtk.Image.new_from_file(G.Paths.ICON_REBOOT)
        self.set_tooltip_text('Reboot')
        self.add(self.image)


class LockButton(Gtk.Button):

    __gtype_name__ = 'LockButton'

    def __init__(self):
        Gtk.Button.__init__(self)

        self.image = Gtk.Image.new_from_file(G.Paths.ICON_LOCK)
        self.set_tooltip_text('Lock')
        self.add(self.image)


class SettingsButton(Gtk.Button):

    __gtype_name__ = 'SettingsButton'

    def __init__(self):
        Gtk.Button.__init__(self)

        self.image = Gtk.Image.new_from_file(G.Paths.ICON_SETTINGS)
        self.set_tooltip_text('Settings')
        self.add(self.image)


class LateralPanel(Gtk.Window):

    __gtype_name__ = 'LateralPanel'

    __gsignals__ = {
        'show-settings': (GObject.SIGNAL_RUN_FIRST, None, [])
        }

    def __init__(self):
        Gtk.Window.__init__(self)

        self.visible = False
        self.timeout = None

        self.vbox = Gtk.VBox()
        self.add(self.vbox)

        self.move(G.Sizes.DISPLAY_WIDTH, 0)
        self.set_keep_above(True)
        self.set_size_request(300, G.Sizes.DISPLAY_HEIGHT)
        self.set_type_hint(Gdk.WindowTypeHint.DOCK)

        calendar = CalendarItem()
        self.vbox.pack_start(calendar, False, False, 10)

        hscale = Gtk.HScale()
        adjust = Gtk.Adjustment(G.get_actual_volume(), 0, 100, 1, 10)
        hscale.set_adjustment(adjust)
        hscale.set_draw_value(False)
        hscale.connect('value-changed', self.__volume_changed)
        image = Gtk.Image.new_from_pixbuf(G.get_icon('audio-volume-muted', 24))
        self.add_widgets(image, hscale)

        scale = Gtk.HScale()
        #adjust = Gtk.Adjustment(G.get_actual_brightness(), 10, 100, 1, 10)
        #scale.set_adjustment(adjust)
        scale.set_draw_value(False)
        image = Gtk.Image.new_from_pixbuf(G.get_icon('display-brightness-symbolic', 24))
        self.add_widgets(image, scale)

        hbox = Gtk.HBox()
        self.vbox.pack_end(hbox, False, False, 10)

        shutdown_button = ShutdownButton()
        hbox.pack_start(shutdown_button, True, True, 10)

        reboot_button = RebootButton()
        hbox.pack_start(reboot_button, True, True, 10)

        lock_button = LockButton()
        hbox.pack_start(lock_button, True, True, 10)

        settings_button = SettingsButton()
        settings_button.connect('clicked', self.__show_settings)
        hbox.pack_start(settings_button, True, True, 10)

        self.connect('focus-out-event', self.__focus_out_event_cb)

        self.show_all()

    def __focus_out_event_cb(self, window, event):
        self.reveal()

    def __volume_changed(self, scale):
        G.set_volume(scale.get_value())

    def __brightness_changed(self, scale):
        G.set_brightness(scale.get_value())

    def __reveal(self):
        def move():
            x, y = self.get_position()
            if x > G.Sizes.DISPLAY_WIDTH - 300:
                avance = (x - (G.Sizes.DISPLAY_WIDTH - 300)) / 2
                self.move(x - avance, 0)
                return True

            else:
                self.timeout = None
                return False

        if self.timeout:
            GObject.source_remove(self.timeout)

        self.timeout = GObject.timeout_add(20, move)

    def __disreveal(self):
        def move():
            x, y = self.get_position()
            if x < G.Sizes.DISPLAY_WIDTH:
                avance = (x - G.Sizes.DISPLAY_WIDTH) / 2
                self.move(x - avance, 0)
                return True

            else:
                self.timeout = None
                return False

        if self.timeout:
            GObject.source_remove(self.timeout)

        self.timeout = GObject.timeout_add(20, move)

    def __show_settings(self, button):
        self.emit('show-settings')

    def add_widgets(self, icon, widget):
        hbox = Gtk.HBox()
        hbox.pack_start(icon, False, False, 1)
        hbox.pack_start(widget, True, True, 0)
        self.vbox.pack_start(hbox, False, False, 1)

    def reveal(self, visible):
        if visible != self.visible:
            self.visible = visible

            if visible:
                self.__reveal()

            else:
                self.__disreveal()
