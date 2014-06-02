#!/usr/bin/env python
# -*- coding: utf-8 -*-

#  Lestin.py por:
#     Cristian García: cristian99garcia@gmail.com

import os
import sys
import thread
import Globals as G

from gi.repository import Gtk
from gi.repository import Gdk
from gi.repository import GdkPixbuf

from Widgets import Canvas
from Widgets import Area
from Widgets import Panel
from Widgets import SettingsWindow
from Widgets import FavouriteApplications


screen = Gdk.Screen.get_default()
css_provider = Gtk.CssProvider()
style = os.path.join(os.path.dirname(__file__), 'Lestim.css')
context = Gtk.StyleContext()

css_provider.load_from_path(style)

context.add_provider_for_screen(
    screen,
    css_provider,
    Gtk.STYLE_PROVIDER_PRIORITY_USER
)


class Lestim(Gtk.Window):

    def __init__(self):

        Gtk.Window.__init__(self)

        self.directorio = self.get_directory()

        self.vbox = Canvas()
        self.panel = Panel()
        self.area = Area()
        self.panel_aplicaciones_favoritas = FavouriteApplications()
        self.aplicaciones = self.panel.get_applications_menu()
        self.menu_de_usuario = self.panel.get_user_menu()

        self.set_icon_from_file(G.main_window_icon)
        self.set_title('Lestim')
        self.area.set_direccion(self.directorio)

        self.connect('delete-event', lambda w, e: sys.exit(0))
        self.panel.connect('show-panel', self.show_hide_panel)
        self.area.connect('show-panel', self.show_hide_panel)
        self.panel_aplicaciones_favoritas.connect('open-application', self.app_exec)
        self.aplicaciones.connect(
            'open-application', lambda *a: self.aplicaciones.hide())
        self.aplicaciones.connect('open-application', self.app_exec)
        self.menu_de_usuario.connect(
            'open-settings-window', lambda x: self.menu_de_usuario.hide())
        self.menu_de_usuario.connect('open-settings-window', self.settings_window)
        self.menu_de_usuario.connect('close', lambda x: sys.exit(0))

        self.vbox.pack_start(self.panel, False, False, 0)
        self.vbox.pack_start(self.area, True, True, 0)
        self.vbox.pack_start(self.panel_aplicaciones_favoritas, False, False, 0)

        self.add(self.vbox)
        self.show_all()
        self.set_defaults()

    def set_defaults(self):

        win = self.get_window()
        width, height = G.get_display_dimensions()

        self.set_size_request(width, height)
        self.resize(width, height)

        win.set_decorations(0)
        win.process_all_updates()

        self.move(0, 0)

        self.set_targets()

    def settings_window(self, widget):

        win = SettingsWindow()
        win.connect('settings-changed', self.settings_changed)

    def settings_changed(self, widget, dicc):

        self.area.set_panel_visible(dicc['panel-siempre-visible'])

    def show_hide_panel(self, widget, if_show):

        if if_show:
            self.panel_aplicaciones_favoritas.show_all()

        else:
            self.panel_aplicaciones_favoritas.hide()

    def app_exec(self, widget, app):

        def _exec(app):

            os.system(app['ejecutar'])

        thread.start_new_thread(_exec, (app,))

    def close_application(self, canvas):

        pass

    def get_directory(self):

        return G.get_desktop_directory()

    def set_targets(self):

        #targets = self.aplicaciones.area.drag_source_get_target_list()
        #targets.add_image_targets(G.ICONVIEW_PIXBUF_COLUMN, True)

        #self.panel_aplicaciones_favoritas.drag_dest_set_target_list(None)
        #self.aplicaciones.area.drag_source_set_target_list(None)

        #self.panel_aplicaciones_favoritas.drag_source_set(Gdk.ModifierType.BUTTON1_MASK, [], Gdk.DragAction.COPY)
        #self.panel_aplicaciones_favoritas.drag_source_set_target_list(targets)
        #self.panel_aplicaciones_favoritas.drag_dest_set(Gtk.DestDefaults.ALL, [], Gdk.DragAction.COPY)
        #self.panel_aplicaciones_favoritas.drag_dest_set_target_list(targets)

        self.panel_aplicaciones_favoritas.drag_dest_set_target_list(None)
        self.aplicaciones.area.drag_source_set_target_list(None)

        self.panel_aplicaciones_favoritas.drag_dest_add_text_targets()
        self.aplicaciones.area.drag_source_add_text_targets()
        self.panel_aplicaciones_favoritas.area = self.aplicaciones.area


if __name__ == '__main__':
    Lestim()
    Gtk.main()
