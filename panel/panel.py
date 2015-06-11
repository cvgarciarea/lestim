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
from gi.repository import Gio
from gi.repository import Wnck
from gi.repository import GObject

import globals as G


class AppButton(Gtk.Button):

    __gtype_name__ = 'AppButton'

    __gsignals__ = {
        'run-app': (GObject.SIGNAL_RUN_FIRST, None, []),
        'favorited': (GObject.SIGNAL_RUN_FIRST, None, []),
        }

    def __init__(self, file, label=None, icon_size=48):
        Gtk.Button.__init__(self)

        self.gapp = Gtk.Application.get_default()
        self.app = G.get_app(file)
        self.file = file
        self.in_favorites = self.file in G.get_settings()['favorites-apps']

        self.popover = self.make_popover()

        vbox = Gtk.VBox()
        self.add(vbox)

        image = Gtk.Image.new_from_pixbuf(G.get_icon(self.app['icon'], icon_size))
        vbox.pack_start(image, True, True, 0)

        self.label = Gtk.Label()
        self.label.set_name('AppButtonLabel')

        if not label:
            self.set_tooltip_text(self.app['name'])

        elif label:
            text = self.app['name']
            text = text[:20] + '...' if len(text) > 20 else text
            self.label.set_label(text)
            vbox.pack_end(self.label, False, False, 0)

        self.connect('button-release-event', self.__button_release_event_cb)

    def __button_release_event_cb(self, widget, event):
        if event.button == 1:
            self.emit('run-app')

        elif event.button == 3:
            self.popover.show_all()

    def make_popover(self):
        self.gmenu = Gio.Menu()
        self.gmenu.append('Open new window', 'app.open')
        self.gmenu.append('Add to favorites' if not self.in_favorites else 'Remove from favorites', 'app.favorited')
        self.gmenu.append('Send to desktop', 'app.desktop')

        open_app_action = Gio.SimpleAction.new('open', None)
        self.gapp.add_action(open_app_action)

        favorited_action = Gio.SimpleAction.new('favorited', None)
        #favorited_action.connect('activate', self.favorited_cb)
        self.gapp.add_action(favorited_action)

        send_to_desktop_action = Gio.SimpleAction.new('desktop', None)
        #favorited_action.connect('activate', self.favorited_cb)
        self.gapp.add_action(send_to_desktop_action)

        popover = Gtk.Popover.new_from_model(self, self.gmenu)
        popover.set_name('AppButtonPopover')

        return popover

    def favorited_cb(self, widget):
        self.in_favorites = not self.in_favorites
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

        self.image = Gtk.Image.new_from_pixbuf(G.get_icon('view-grid-symbolic'))
        self.set_image(self.image)


class IndicatorsArea(Gtk.Box):

    __gtype_name__ = 'IndicatorsArea'

    __gsignals__ = {
        'show-lateral-panel': (GObject.SIGNAL_RUN_FIRST, None, [bool]),
        }

    def __init__(self):
        Gtk.Box.__init__(self)

        self.__panel_visible = False

        self.lateral_panel_button = Gtk.Button()
        self.lateral_panel_button.set_name('ShowPanelButton')
        self.lateral_panel_button.connect('clicked', self.__show_lateral_panel)
        self.pack_end(self.lateral_panel_button, False, False, 1)

    def __show_lateral_panel(self, widget):
        self.__panel_visible = not self.__panel_visible
        self.emit('show-lateral-panel', self.__panel_visible)


class LestimPanel(Gtk.Window):

    __gtype_name__ = 'LestimPanel'

    __gsignals__ = {
        'show-apps': (GObject.SIGNAL_RUN_FIRST, None, []),
        'show-lateral-panel': (GObject.SIGNAL_RUN_FIRST, None, [bool]),
        }

    def __init__(self):
        Gtk.Window.__init__(self)

        self.visible = False
        self.timeout = None
        self.expand = None
        self.orientation = None
        self.box = None
        self.button = None
        self.favorite_area = None
        self.opened_apps_area = None
        self.indicators = None
        self.pos_reseted = False

        self.set_keep_above(True)
        self.set_type_hint(Gdk.WindowTypeHint.DOCK)
        self.set_opacity(0.5)
        self.move(0, G.Sizes.DISPLAY_HEIGHT / 2 - 200)

        self.screen = Wnck.Screen.get_default()
        self.screen.connect('application-closed', self.update_opened_buttons)
        self.screen.connect('application-opened', self.window_opened)

        self.box = Gtk.Box()
        self.box.connect('check-resize', self.reset_pos)
        self.add(self.box)

        self.button = PanelAppsButton()
        self.button.connect('clicked', self.__show_apps)
        self.box.pack_start(self.button, False, False, 2)

        self.favorite_area = Gtk.Box()
        self.box.pack_start(self.favorite_area, False, False, 2)

        self.opened_apps_area = Gtk.Box()
        self.box.pack_start(self.opened_apps_area, False, False, 0)

        self.indicators = IndicatorsArea()
        self.indicators.connect('show-lateral-panel', self.__show_lateral_panel)
        self.box.pack_end(self.indicators, False, False, 0)

        self.connect('configure-event', self.__configure_cb)

        self.show_all()

    def __show_apps(self, *args):
        self.emit('show-apps')

    def __configure_cb(self, window, event):
        if not self.pos_reseted:
            self.reset_pos()
            return

        x, y = event.x, event.y

        if self.orientation in ['Left', 'Top']:
            if (x, y) == (0, 0) and not self.expand:
                print('reset-pos')
                self.reset_pos()

            if (x, y) != (0, 0) and self.expand:
                print('reset-pos')
                self.move(0, 0)

        elif self.orientation == 'Bottom':
            w, h = self.get_size()
            if (x, y) == (0, G.Sizes.DISPLAY_HEIGHT - h) and not self.expand:
                self.reset_pos()

            elif (x, y) != (0, G.Sizes.DISPLAY_HEIGHT - h) and self.expand:
                self.move(0, G.Sizes.DISPLAY_HEIGHT - h)

    def __show_lateral_panel(self, area, show):
        self.emit('show-lateral-panel', show)

    def __reveal(self):
        w, h = self.get_size()
        _x = G.Sizes.DISPLAY_WIDTH / 2.0 - w / 2.0
        _y = G.Sizes.DISPLAY_HEIGHT / 2.0 - h / 2.0

        def move_left():
            x, y = self.get_position()

            if x < 0:
                avance = (w - x) / 2
                x = (x + avance)
                self.move(x if x <= 0 else 0, _y)
                return True

            else:
                self.timeout = None
                return False

        def move_top():
            x, y = self.get_position()

            if y < 0:
                avance = (h - y) / 2
                y = (y + avance)
                self.move(_x, y if y <= 0 else 0)
                return True

            else:
                self.timeout = None
                return False

        def move_bottom():
            x, y = self.get_position()

            if y < G.Sizes.DISPLAY_HEIGHT + h:
                avance = (G.Sizes.DISPLAY_HEIGHT - (y)) / 2
                y = (y + avance)
                self.move(_x, y if y <= G.Sizes.DISPLAY_WIDTH - h else G.Sizes.DISPLAY_HEIGHT - h)
                return True

            else:
                self.timeout = None
                return False

        if self.timeout:
            GObject.source_remove(self.timeout)

        if self.orientation == 'Left':
            move = move_left

        elif self.orientation == 'Top':
            move = move_top

        elif self.orientation == 'Bottom':
            move = move_bottom

        self.timeout = GObject.timeout_add(20, move)

    def __disreveal(self):
        w, h = self.get_size()
        _x = G.Sizes.DISPLAY_WIDTH / 2.0 - w / 2.0
        _y = G.Sizes.DISPLAY_HEIGHT / 2.0 - h / 2.0

        def move_left():
            x, y = self.get_position()

            if x + w > 0:
                avance = (x - w) / 2
                self.move(x + avance, _y)
                return True

            else:
                self.timeout = None
                return False

        def move_top():
            x, y = self.get_position()

            if y + h > 0:
                avance = (y - h) / 2
                self.move(_x, y + avance)
                return True

            else:
                self.timeout = None
                return False

        def move_bottom():
            x, y = self.get_position()

            if y + h < G.Sizes.DISPLAY_HEIGHT:
                avance = (G.Sizes.DISPLAY_HEIGHT - y) / 2
                self.move(_x, y + avance)
                return True

            else:
                self.timeout = None
                return False

        if self.timeout:
            GObject.source_remove(self.timeout)

        if self.orientation == 'Left':
            move = move_left

        elif self.orientation == 'Top':
            move = move_top

        elif self.orientation == 'Bottom':
            move = move_bottom

        self.timeout = GObject.timeout_add(20, move)

    def set_orientation(self, orientation):
        if self.orientation == orientation:
            return

        self.orientation = orientation
        if self.orientation == 'Left':
            gorientation = Gtk.Orientation.VERTICAL

        elif self.orientation in ['Top', 'Bottom']:
            gorientation = Gtk.Orientation.HORIZONTAL

        self.box.set_orientation(gorientation)
        self.favorite_area.set_orientation(gorientation)
        self.opened_apps_area.set_orientation(gorientation)
        self.indicators.set_orientation(gorientation)

        if self.orientation == 'Left':
            self.resize(48, 1)

        GObject.idle_add(self.set_reveal_state, False)

    def set_expand(self, expand):
        self.expand = expand
        if self.expand:
            self.set_size_request(-1, G.Sizes.DISPLAY_HEIGHT)
            x, y = self.get_position()
            self.move(x, 0)

        else:
            self.set_size_request(-1, -1)
            self.resize(1, 1)

    def set_reveal_state(self, visible):
        name = 'go-previous-symbolic' if not visible else 'go-next-symbolic'
        image = Gtk.Image.new_from_pixbuf(G.get_icon(name, 24))
        button = self.indicators.lateral_panel_button
        if button.get_children():
            button.remove(button.get_children()[0])

        button.add(image)
        button.show_all()

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
        self.reset_pos()

    def window_opened(self, screen, window):
        if window.get_name() == 'lestim':
            return

        if type(window) == Wnck.Application:
            window = window.get_windows()[0]

        button = OpenedAppButton(window)
        self.opened_apps_area.pack_start(button, False, False, 0)
        self.show_all()

    def start(self):
        orientation = G.get_settings()['panel-orientation']
        self.set_orientation(orientation)

        GObject.idle_add(self.update_favorite_buttons)
        self.screen.force_update()

        self.show_all()

    def reveal(self, visible):
        if visible == self.visible:
            return

        self.visible = visible
        if not self.visible:
            self.__disreveal()

        else:
            self.__reveal()

    def reset_pos(self, vbox=None):
        width, height = self.get_size()
        x, y = self.get_position()
        _x = G.Sizes.DISPLAY_WIDTH / 2.0 - width / 2.0
        _y = G.Sizes.DISPLAY_HEIGHT / 2.0 - height / 2.0

        if self.orientation == 'Left':
            _x = -width if not self.visible else 0

        elif self.orientation in ['Top', 'Bottom']:
            if self.visible:
                _y = 0 if self.orientation == 'Top' else G.Sizes.DISPLAY_HEIGHT - height

            else:
                _y = -height if self.orientation == 'Top' else G.Sizes.DISPLAY_HEIGHT

        if self.get_position() != (_x, _y):
            self.move(x, y)

