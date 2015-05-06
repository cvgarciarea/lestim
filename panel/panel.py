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

from gi.repository import Gtk
from gi.repository import Gdk
from gi.repository import GObject

import globals as G


class AppButtonPopover(Gtk.Popover):

    __gtype_name__ = 'AppButtonPopover'

    __gsignals__ = {
        'favorited': (GObject.SIGNAL_RUN_FIRST, None, [bool]),
        }

    def __init__(self, button, app):
        Gtk.Popover.__init__(self)

        self.set_relative_to(button)

        self.vbox = Gtk.VBox()
        self.favorite_check = Gtk.CheckButton('En favoritos')
        #self.favorite_check.set_active(app in Globales.get_settings()['favorites-apps'])
        self.favorite_check.connect('toggled', self.__favorited)
        self.vbox.pack_start(self.favorite_check, True, True, 1)

        self.add(self.vbox)

    def __favorited(self, *args):
        self.emit('favorited', self.favorite_check.get_active())


class AppButton(Gtk.Button):

    __gtype_name__ = 'AppButton'

    __gsignals__ = {
        'run-app': (GObject.SIGNAL_RUN_FIRST, None, []),
        'favorited': (GObject.SIGNAL_RUN_FIRST, None, []),
        }

    def __init__(self, file, label=None, icon_size=48):
        Gtk.Button.__init__(self)

        self.app = G.get_app(file)
        self.file = file

        self.popover = AppButtonPopover(self, self.app)
        self.popover.connect('favorited', self.favorited_cb)

        vbox = Gtk.VBox()
        image = Gtk.Image.new_from_pixbuf(G.get_icon(self.app['icon'], icon_size))
        vbox.pack_start(image, True, True, 0)

        if not label:
            self.set_tooltip_text(self.app['name'])

        elif label:
            text = self.app['name']
            text = text[:20] + '...' if len(text) > 20 else text
            vbox.pack_end(Gtk.Label(text), False, False, 0)

        self.connect('button-release-event', self.button_press_event_cb)

        self.add(vbox)

    def button_press_event_cb(self, widget, event):
        if event.button == 1:
            self.emit('run-app')

        elif event.button == 3:
            self.popover.show_all()

    def favorited_cb(self, widget, favorite):
        settings = G.get_settings()

        if favorite:
            settings['favorites-apps'].append(self.file)

        elif not favorite and self.file in settings['favorites-apps']:
            settings['favorites-apps'].remove(self.file)

        G.set_settings(settings)
        self.emit('favorited')


class PanelAppsButton(Gtk.Button):

    __gtype_name__ = 'PanelAppsButton'

    def __init__(self):
        Gtk.Button.__init__(self)

        self.image = Gtk.Image.new_from_pixbuf(G.get_icon('distributor-logo'))
        self.set_image(self.image)


class IndicatorsArea(Gtk.VBox):

    __gtype_name__ = 'IndicatorsArea'

    __gsignals__ = {
        'show-lateral-panel': (GObject.SIGNAL_RUN_FIRST, None, [bool]),
        }

    def __init__(self):
        Gtk.VBox.__init__(self)

        self.lateral_panel_button = Gtk.Button('>')
        self.lateral_panel_button.connect('clicked', self.__show_lateral_panel)
        self.pack_end(self.lateral_panel_button, False, False, 1)

    def __show_lateral_panel(self, widget):
        if widget.get_label() == '>':
            widget.set_label('<')
            self.emit('show-lateral-panel', True)

        elif widget.get_label() == '<':
            widget.set_label('>')
            self.emit('show-lateral-panel', False)


class LestimPanel(Gtk.Window):

    __gtype_name__ = 'LestimPanel'

    __gsignals__ = {
        'show-apps': (GObject.SIGNAL_RUN_FIRST, None, []),
        'show-lateral-panel': (GObject.SIGNAL_RUN_FIRST, None, [bool]),
        }

    def __init__(self):
        Gtk.Window.__init__(self)

        self.box = Gtk.VBox()
        self.box.connect('check-resize', self.reset_y)
        self.add(self.box)

        self.set_keep_above(True)
        #self.set_size_request(40, 400)
        self.set_resizable(False)
        self.set_type_hint(Gdk.WindowTypeHint.DOCK)
        self.set_opacity(0.5)
        #self.move(0, G.Sizes.DISPLAY_HEIGHT / 2 - 200)

        self.connect('realize', self.__realize_cb)

        self.button = PanelAppsButton()
        self.button.connect('clicked', self.__show_apps)
        self.box.pack_start(self.button, False, False, 2)

        self.buttons_area = Gtk.VBox()
        self.box.pack_start(self.buttons_area, True, True, 2)

        self.indicators = IndicatorsArea()
        self.indicators.connect('show-lateral-panel', self.__show_lateral_panel)
        self.box.pack_end(self.indicators, False, False, 0)

        self.update_buttons()
        self.show_all()

    def __realize_cb(self, widget):
        self.reset_y()

    def __show_apps(self, *args):
        self.emit('show-apps')

    def __show_lateral_panel(self, area, show):
        self.emit('show-lateral-panel', show)

    def reset_y(self, vbox=None):
        width, height = self.get_size()
        self.move(0, G.Sizes.DISPLAY_HEIGHT / 2.0 - height / 2.0)

    def add_app_button(self, app):
        button = AppButton(app)
        button.connect('favorited', self.update_buttons)
        self.buttons_area.pack_start(button, False, False, 0)

    def update_buttons(self, *args):
        while self.buttons_area.get_children():
            self.buttons_area.remove(self.buttons_area.get_children()[-1])

        for app in G.get_settings()['favorites-apps']:
            self.add_app_button(app)

        self.show_all()