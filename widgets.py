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

import globals as G
G.set_theme()


class LestimWindow(Gtk.Window):

    __gtype_name__ = 'LestimWindow'

    def __init__(self):
        Gtk.Window.__init__(self)

        self.settings_window = SettingsWindow()

        #self.set_keep_below(True)
        self.set_position(Gtk.WindowPosition.CENTER_ALWAYS)
        self.set_size_request(G.Sizes.DISPLAY_WIDTH, G.Sizes.DISPLAY_HEIGHT)
        self.move(0, 0)

        self.mouse = G.MouseDetector()
        self.mouse.connect('mouse-motion', self.__mouse_motion_cb)

        self.apps_view = AppsView()
        self.apps_view.connect('run-app', self.run_app)
        self.apps_view.connect('favorited-app', self.update_favorited_buttons)

        self.box = Gtk.VBox()
        self.box.set_name('CanvasVBox')
        self.add(self.box)

        self.hbox = Gtk.HBox()
        self.hbox.set_name('CanvasHBox')
        self.box.pack_start(self.hbox, True, True, 0)

        self.work_area = WorkArea()
        self.hbox.pack_start(self.work_area, True, True, 0)

        self.lateral_panel = LateralPanel()
        self.lateral_panel.connect('show-settings', self.__show_settings_cb)
        #self.hbox.pack_end(self.lateral_panel, False, False, 0)

        self.panel = LestimPanel()
        self.panel.connect('show-apps', self.show_apps)
        self.panel.connect('show-lateral-panel', self.show_lateral_panel)
        #self.box.pack_start(self.panel, False, False, 0)

        self.connect('realize', self.__realize_cb)
        self.connect('destroy', self.__logout)

        self.show_all()

    def __realize_cb(self, widget):
        win_x11 = self.get_window()
        win_x11.set_decorations(False)
        win_x11.process_all_updates()

    def __logout(self, widget):
        Gtk.main_quit()

    def __show_settings_cb(self, panel):
        self.settings_window.show_all()

    def __mouse_motion_cb(self, detector, x1, y1):
        w, h = self.panel.get_size()
        x2, y2 = self.panel.get_position()

        if (x1 <= w + 10):
            self.panel.reveal(True)

        else:
            self.panel.reveal(False)

    def run_app(self, apps_view, app):
        self.set_principal_widget(self.work_area)
        G.run_app(app)

    def update_favorited_buttons(self, *args):
        self.panel.update_buttons()

    def show_apps(self, *args):
        if not self.apps_view in self.hbox.get_children():
            self.set_principal_widget(self.apps_view)

        else:
            self.set_principal_widget(self.work_area)

    def show_lateral_panel(self, widget, visible):
        self.lateral_panel.set_show(visible)
        self.panel.indicators.lateral_panel_button.set_label('<' if visible else '>')

    def set_principal_widget(self, widget):
        if widget == self.hbox.get_children()[0]:
            return

        self.hbox.remove(self.hbox.get_children()[0])
        self.hbox.pack_start(widget, True, True, 0)
        self.show_all()
        self.panel.indicators.lateral_panel_button.set_label('>')


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

        self.add(self.view)

        #self.view.connect('button-press-event', self.__button_press_event_cb)
        #self.view.connect('key-press-event', self.__key_press_event_cb)
        #self.scan_foolder.connect('files-changed', self.agregar_iconos)


class AppsEntry(Gtk.Entry):

    __gtype_name__ = 'AppsEntry'

    def __init__(self):
        Gtk.Entry.__init__(self)

        self.set_placeholder_text('Search...')
        self.props.xalign = 0.015


class AppsView(Gtk.VBox):

    __gtype_name__ = 'AppsView'

    __gsignals__ = {
        'run-app': (GObject.SIGNAL_RUN_FIRST, None, [object]),
        'favorited-app': (GObject.SIGNAL_RUN_FIRST, None, []),
        }

    def __init__(self):
        Gtk.VBox.__init__(self)

        self.set_border_width(50)

        self.entry = AppsEntry()
        self.entry.connect('changed', self.search_app)
        self.pack_start(self.entry, False, False, 20)

        scrolled = Gtk.ScrolledWindow()
        self.pack_start(scrolled, True, True, 0)

        self.fbox = Gtk.FlowBox()
        self.fbox.set_max_children_per_line(4)
        scrolled.add(self.fbox)

        GObject.idle_add(self.show_all_apps)

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

        self.show_all()

    def __run_app_cb(self, button):
        self.emit('run-app', button.app)

    def __favorited_app_cb(self, button):
        self.emit('favorited-app')

    def search_app(self, widget):
        for x in self.fbox.get_children():
            button = x.get_children()[0]
            if widget.get_text().lower() in button.app['name'].lower():
                x.show_all()

            else:
                x.hide()
