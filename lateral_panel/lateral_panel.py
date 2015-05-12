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

    __gtype_name__ = 'CalendarItem'

    def __init__(self):
        Gtk.VBox.__init__(self)

        box = Gtk.EventBox()
        box.connect('button-press-event', self.__revealer_calendar)
        self.pack_start(box, False, False, 0)

        self.time_label = Gtk.Label()
        self.time_label.set_name('TimeLabel')
        box.add(self.time_label)

        box = Gtk.EventBox()
        box.connect('button-press-event', self.__revealer_calendar)
        self.pack_start(box, False, False, 0)

        self.day_label = Gtk.Label()
        self.day_label.set_name('DayLabel')
        box.add(self.day_label)

        self.revealer = Gtk.Revealer()
        self.revealer.set_reveal_child(False)
        self.pack_start(self.revealer, False, False, 0)

        calendar = Gtk.Calendar()
        calendar.set_name('LateralCalendar')
        self.revealer.add(calendar)

        GObject.timeout_add(1000, self.__update_data)

    def __update_data(self):
        self.time_label.set_label(G.get_current_time())
        self.day_label.set_label(G.get_week_day())
        return True

    def __revealer_calendar(self, box, event):
        self.revealer.set_reveal_child(not self.revealer.get_reveal_child())


class MonitorsItem(Gtk.HBox):

    def __init__(self):
        Gtk.HBox.__init__(self)

        if os.path.exists('/sys/class/power_supply/'):
            if len(os.listdir('/sys/class/power_supply/')):
                self.make_battery_item()

        self.network_item = Gtk.VBox()
        self.pack_start(self.network_item, True, True, 10)

        icon = Gtk.Image.new_from_pixbuf(G.get_icon('network-wireless-signal-excellent-symbolic', 24))
        self.network_item.pack_start(icon, False, False, 2)

        self.network_label = Gtk.Label()
        self.network_item.pack_start(self.network_label, False, False, 0)

    def __percentage_changed_cb(self, deamon, percentage):
        self.battery_percentage = percentage
        self.battery_label.set_label(str(self.battery_percentage) + '%')
        self.check_battery_state()

    def __battery_changed_cb(self, deamon, state):
        self.battery_state = state
        self.check_battery_state()

    def make_battery_item(self):
        self.battery_state = None
        self.battery_percentage = 0

        self.battery_deamon = G.BatteryDeamon()
        self.battery_deamon.connect('percentage-changed', self.__percentage_changed_cb)
        self.battery_deamon.connect('state-changed', self.__battery_changed_cb)
        self.battery_deamon.start()

        self.battery_item = Gtk.VBox()
        self.pack_start(self.battery_item, True, True, 10)
        self.battery_item.pack_start(Gtk.Image(), False, False, 2)

        self.battery_label = Gtk.Label(str(self.battery_deamon.percentage) + '%')
        self.battery_item.pack_end(self.battery_label, False, False, 0)

    def check_battery_state(self):
        # Possible battery states: Charging, Discharging
        if self.battery_percentage <= 2:
            icon = 'battery-empty-charging-symbolic'

        elif self.battery_percentage <= 15:
            icon = 'battery-caution-charging-symbolic'

        elif self.battery_percentage <= 30:
            icon = 'battery-low-charging-symbolic'

        elif self.battery_percentage <= 50:
            icon = 'battery-good-charging-symbolic'

        elif self.battery_percentage <= 100:
            icon = 'battery-full-charging-symbolic'

        if self.battery_state == 'Discharging':
            icon = icon.replace('charging-', '')

        self.battery_item.remove(self.battery_item.get_children()[0])
        icon = Gtk.Image.new_from_pixbuf(G.get_icon(icon, 24))
        self.battery_item.pack_start(icon, False, False, 2)
        self.battery_item.show_all()


class PrevSongButton(Gtk.Button):

    __gtype_name__ = 'PrevSongButton'

    def __init__(self):
        Gtk.Button.__init__(self)


class PlayPauseButton(Gtk.Button):

    __gtype_name__ = 'PlayPauseButton'

    def __init__(self):
        Gtk.Button.__init__(self)


class NextSongButton(Gtk.Button):

    __gtype_name__ = 'NextSongButton'

    def __init__(self):
        Gtk.Button.__init__(self)


class PlayerControllerItem(Gtk.VBox):

    def __init__(self):
        Gtk.VBox.__init__(self)

        self.song_name = Gtk.Label()
        self.pack_start(self.song_name, False, False, 10)

        self.button_box = Gtk.HButtonBox()
        self.button_box.set_layout(Gtk.ButtonBoxStyle.CENTER)
        self.pack_start(self.button_box, False, False, 0)

        self.prev_button = PrevSongButton()
        self.button_box.add(self.prev_button)

        self.play_pause_button = PlayPauseButton()
        self.button_box.add(self.play_pause_button)

        self.next_button = NextSongButton()
        self.button_box.add(self.next_button)


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
        'show-settings': (GObject.SIGNAL_RUN_FIRST, None, []),
        'reveal-changed': (GObject.SIGNAL_RUN_FIRST, None, [bool])
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

        self.monitors = MonitorsItem()
        self.vbox.pack_start(self.monitors, False, False, 0)

        #self.player = PlayerControllerItem()
        #self.vbox.pack_start(self.player, False, False, 0)

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
        lock_button.connect('clicked', self.__disreveal_from_button)
        hbox.pack_start(lock_button, True, True, 10)

        settings_button = SettingsButton()
        settings_button.connect('clicked', self.__show_settings)
        settings_button.connect('clicked', self.__disreveal_from_button)
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
        self.emit('reveal-changed', True)

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
        self.emit('reveal-changed', False)

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

    def __disreveal_from_button(self, button):
        self.reveal(False)

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
