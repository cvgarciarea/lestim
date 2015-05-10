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
from gi.repository import Wnck
from gi.repository import GObject

import globals as G


class AppButtonPopover(Gtk.Popover):

    __gtype_name__ = 'AppButtonPopover'

    __gsignals__ = {
        'favorited': (GObject.SIGNAL_RUN_FIRST, None, [bool]),
        }

    def __init__(self, button, file):
        Gtk.Popover.__init__(self)

        self.set_relative_to(button)

        self.vbox = Gtk.VBox()
        self.favorite_check = Gtk.CheckButton('In favorites')
        self.favorite_check.set_active(file in G.get_settings()['favorites-apps'])
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

        self.popover = AppButtonPopover(self, self.file)
        self.popover.connect('favorited', self.favorited_cb)

        vbox = Gtk.VBox()
        self.add(vbox)

        image = Gtk.Image.new_from_pixbuf(G.get_icon(self.app['icon'], icon_size))
        vbox.pack_start(image, True, True, 0)

        if not label:
            self.set_tooltip_text(self.app['name'])

        elif label:
            text = self.app['name']
            text = text[:20] + '...' if len(text) > 20 else text
            vbox.pack_end(Gtk.Label(text), False, False, 0)

        self.connect('button-release-event', self.__button_release_event_cb)

    def __button_release_event_cb(self, widget, event):
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


class OpenedAppButton(Gtk.Button):

    __gtype_name__ = 'OpenedAppButton'

    def __init__(self, window):
        Gtk.Button.__init__(self)

        self.window = window

        self.image = Gtk.Image.new_from_pixbuf(window.get_icon())
        self.set_image(self.image)
        self.set_tooltip_text(window.get_name())

        self.connect('button-release-event', self.__button_press_event_cb)

    def __button_press_event_cb(self, widget, event):
        if event.button == 1:
            if not self.window.is_active():
                self.window.activate(0)

            else:
                self.window.minimize()


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
        self.lateral_panel_button.set_name('ShowPanelButton')
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

        self.visible = True
        self.timeout = None

        self.set_keep_above(True)
        #self.set_size_request(40, 400)
        self.set_resizable(False)
        self.set_type_hint(Gdk.WindowTypeHint.DOCK)
        self.set_opacity(0.5)
        self.move(0, G.Sizes.DISPLAY_HEIGHT / 2 - 200)

        self.screen = Wnck.Screen.get_default()
        self.screen.connect('application-closed', self.update_opened_buttons)
        self.screen.connect('application-opened', self.window_opened)

        self.box = Gtk.VBox()
        self.box.connect('check-resize', self.reset_y)
        self.add(self.box)

        self.connect('realize', self.__realize_cb)

        self.button = PanelAppsButton()
        self.button.connect('clicked', self.__show_apps)
        self.box.pack_start(self.button, False, False, 2)

        self.favorite_area = Gtk.VBox()
        self.favorite_area.connect('check-resize', self.reset_y)
        self.box.pack_start(self.favorite_area, True, True, 2)

        self.opened_apps_area = Gtk.VBox()
        self.opened_apps_area.connect('check-resize', self.reset_y)
        self.box.pack_start(self.opened_apps_area, True, True, 0)

        self.indicators = IndicatorsArea()
        self.indicators.connect('show-lateral-panel', self.__show_lateral_panel)
        self.box.pack_end(self.indicators, False, False, 0)

        self.update_favorite_buttons()
        self.show_all()
        self.screen.force_update()

    def __realize_cb(self, widget):
        self.reset_y()

    def __show_apps(self, *args):
        self.emit('show-apps')

    def __show_lateral_panel(self, area, show):
        self.emit('show-lateral-panel', show)

    def __run_app(self, button):
        G.run_app(button.app)

    def __reveal(self):
        def move():
            x, y = self.get_position()
            w, h = self.get_size()
            _y = G.Sizes.DISPLAY_HEIGHT / 2.0 - h / 2.0

            if x < 0:
                avance = (w - x) / 2
                x = (x + avance)
                self.move(x if x <= 0 else 0, _y)
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
            w, h = self.get_size()
            _y = G.Sizes.DISPLAY_HEIGHT / 2.0 - h / 2.0

            if x + w > 0:
                avance = (x - w) / 2
                self.move(x + avance, _y)
                return True

            else:
                self.timeout = None
                return False

        if self.timeout:
            GObject.source_remove(self.timeout)

        self.timeout = GObject.timeout_add(20, move)

    def reveal(self, visible):
        if visible == self.visible:
            return

        self.visible = visible
        if not self.visible:
            self.__disreveal()

        else:
            self.__reveal()

    def reset_y(self, vbox=None):
        width, height = self.get_size()
        x, y = self.get_position()
        self.move(x, G.Sizes.DISPLAY_HEIGHT / 2.0 - height / 2.0)

    def window_opened(self, screen, window):
        if window.get_name() == 'Lestim.py':
            return

        if type(window) == Wnck.Application:
            window = window.get_windows()[0]

        button = OpenedAppButton(window)
        self.opened_apps_area.pack_start(button, False, False, 0)
        self.show_all()

    def add_app_button(self, app):
        button = AppButton(app)
        button.popover.set_position(Gtk.PositionType.RIGHT)
        button.connect('run-app', self.__run_app)
        button.connect('favorited', self.update_favorite_buttons)
        self.favorite_area.pack_start(button, False, False, 0)

    def update_favorite_buttons(self, *args):
        while self.favorite_area.get_children():
            self.favorite_area.remove(self.favorite_area.get_children()[-1])

        for app in G.get_settings()['favorites-apps']:
            self.add_app_button(app)

        self.show_all()

    def update_opened_buttons(self, *args):
        while self.opened_apps_area.get_children():
            self.opened_apps_area.remove(self.opened_apps_area.get_children()[-1])

        for window in self.screen.get_windows():
            self.window_opened(None, window)

        self.show_all()
