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
from gi.repository import GdkX11
from gi.repository import GObject
from gi.repository import GdkPixbuf

from panel.panel import LestimPanel
from panel.panel import AppButton
from lateral_panel.lateral_panel import LateralPanel
from settings_window.settings_window import SettingsWindow
from apps_view.apps_view import AppsView

import globals as G
G.set_theme()


class LestimWindow(Gtk.ApplicationWindow):

    __gtype_name__ = 'LestimWindow'

    def __init__(self, app):
        Gtk.ApplicationWindow.__init__(self, title='lestim', application=app)

        self.panel_orientation = None
        self.panel_autohide = None
        self.panel_expand = None
        self.panel_space_reserved = None

        #self.set_keep_below(True)
        self.set_type_hint(Gdk.WindowTypeHint.DESKTOP)
        #self.set_position(Gtk.WindowPosition.CENTER_ALWAYS)
        self.set_size_request(G.Sizes.DISPLAY_WIDTH, G.Sizes.DISPLAY_HEIGHT)
        #self.move(0, 0)
        #self.fullscreen()

        self.box = Gtk.VBox()
        self.box.set_name('Canvas')
        self.add(self.box)

        self.work_area = WorkArea()
        self.box.pack_start(self.work_area, True, True, 0)

        self.lateral_panel = LateralPanel()
        self.lateral_panel.set_transient_for(self)
        self.lateral_panel.connect('show-settings', self.__show_settings_cb)
        self.lateral_panel.connect('reveal-changed', self.__reveal_changed_cb)

        self.panel = LestimPanel()
        self.panel.connect('show-apps', self.show_apps)
        self.panel.connect('show-lateral-panel', self.show_lateral_panel)

        self.detector = G.WindowPositionDetector(self.panel)
        self.detector.connect('show-panel', self.__show_panel_from_detector)

        self.apps_view = AppsView(self)
        self.apps_view.connect('run-app', self.run_app)
        self.apps_view.connect('favorited-app', self.update_favorited_buttons)

        self.mouse = G.MouseDetector()
        self.mouse.connect('mouse-motion', self.__mouse_motion_cb)

        self.settings_window = SettingsWindow()
        self.settings_window.connect('settings-changed', self.__settings_changed_cb)

        self.connect('realize', self.__start)
        self.connect('destroy', self.__logout)

        self.show_all()
        self.load_settings()

    def __start(self, window):
        GObject.idle_add(self.panel.start)
        GObject.idle_add(self.mouse.start)
        GObject.idle_add(self.detector.start)

    def __logout(self, widget):
        Gtk.main_quit()
        G.kill_proccess(None, None)

    def __show_settings_cb(self, panel):
        self.settings_window.show_all()

    def __show_panel_from_detector(self, detector):
        self.panel.reveal(True)

    def __mouse_motion_cb(self, detector, x1, y1):
        w, h = self.panel.get_size()
        x2, y2 = self.panel.get_position()

        if self.panel_autohide:
            if self.panel_orientation == 'Left':
                if ((x1 <= 10) and (y1 >= y2) and (y1 <= y2 + h)) and not self.panel.visible:
                    self.panel.reveal(True)

                elif ((x1 >= w) or (y1 <= y2) or (y1 >= y2 + h)) and self.panel.visible:
                    self.panel.reveal(self.detector.panel_visible or self.apps_view.visible)

            elif self.panel_orientation == 'Top':
                if ((y1 <= 10) and (x1 >= x2) and (x1 <= x2 + w)) and not self.panel.visible:
                    self.panel.reveal(True)

                elif ((y1 >= h) or (x1 <= x2) or (x1 >= x2 + w)) and self.panel.visible:
                    self.panel.reveal(self.detector.panel_visible or self.apps_view.visible)

            elif self.panel_orientation == 'Bottom':
                if ((y1 >= G.Sizes.DISPLAY_HEIGHT - 10) and (x1 >= x2) and (x1 <= x2 + w) and not self.panel.visible):
                    self.panel.reveal(True)

                elif ((y1 >= h) or (x1 <= x2) or (x1 >= x2 + w)) and self.panel.visible:
                    self.panel.reveal(self.detector.panel_visible or self.apps_view.visible)

        else:
            self.panel.reveal(True)

    def __reveal_changed_cb(self, panel, visible):
        self.panel.set_reveal_state(visible)

    def __settings_changed_cb(self, window):
        self.load_settings()

    def load_settings(self):
        data = G.get_settings()
        self.panel_orientation = data['panel-orientation']
        self.panel_autohide = data['panel-autohide']
        self.panel_expand = data['panel-expand']
        self.panel_space_reserved = data['panel-space-reserved']

        if self.panel_orientation != self.panel.orientation:
            self.panel.set_orientation(self.panel_orientation)

        if self.panel_autohide != self.panel.get_visible():
            self.panel.reveal(not self.panel_autohide)

        self.panel.set_expand(self.panel_expand)

    def run_app(self, apps_view, app):
        self.apps_view.reveal(False)
        self.lateral_panel.reveal(False)
        G.run_app(app)

    def update_favorited_buttons(self, *args):
        self.panel.update_favorite_buttons()

    def show_apps(self, *args):
        self.apps_view.reveal(not self.apps_view.visible)

    def show_lateral_panel(self, widget, visible):
        self.lateral_panel.reveal(visible)


class WorkArea(Gtk.VBox):

    __gtype_name__ = 'WorkArea'

    def __init__(self):
        Gtk.VBox.__init__(self)

        self.model = Gtk.ListStore(str, GdkPixbuf.Pixbuf)

        self.view = Gtk.IconView()
        self.view.set_selection_mode(Gtk.SelectionMode.MULTIPLE)
        self.view.set_model(self.model)
        self.view.set_text_column(0)
        self.view.set_pixbuf_column(1)
        self.view.set_item_orientation(Gtk.Orientation.VERTICAL)
        self.view.add_events(Gdk.EventMask.KEY_PRESS_MASK |
                             Gdk.EventMask.KEY_RELEASE_MASK |
                             Gdk.EventMask.BUTTON_PRESS_MASK)

        self.scanner = G.ScanFolder()
        self.scanner.connect('files-changed', self.__files_changed)
        self.scanner.start()

        self.add(self.view)

        #self.view.connect('button-press-event', self.__button_press_event_cb)
        #self.view.connect('key-press-event', self.__key_press_event_cb)
        #self.scan_foolder.connect('files-changed', self.agregar_iconos)

    def __files_changed(self, scanner, files):
        GObject.idle_add(self.model.clear)
        for path in files:
            name = G.get_file_name(path)
            pixbuf = G.get_icon(path)
            self.model.append([name, pixbuf])

