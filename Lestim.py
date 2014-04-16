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

from Widgets import Area
from Widgets import Panel
from Widgets import SettingsWindow


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

        self.vbox = Gtk.VBox()
        self.panel = Panel()
        self.area = Area()
        self.aplicaciones = self.panel.get_applications_menu()
        self.menu_de_usuario = self.panel.get_user_menu()

        self.set_files()
        self.set_icon_from_file(G.main_window_icon)
        self.set_title('Lestim')
        self.area.set_direccion(self.directorio)

        self.vbox.pack_start(self.panel, False, False, 0)
        self.vbox.pack_start(self.area, True, True, 0)

        #self.connect('delete-event', lambda w, e: self.accion(self, 'Cerrar'))
        self.connect('delete-event', lambda w, e: sys.exit(0))
        self.menu_de_usuario.connect('open-settings-window', lambda x: SettingsWindow())
        self.menu_de_usuario.connect('close', lambda x: sys.exit(0))
        self.aplicaciones.connect('open-application', self.app_exec)

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

    def app_exec(self, widget, app):

        def _exec(app):

            os.system(app['ejecutar'])

        thread.start_new_thread(_exec, (app,))

    def close_application(self, canvas):

        pass

    def get_directory(self):

        return G.get_desktop_directory()

    def set_files(self):

        directorios, archivos = G.get_files()

        self.area.limpiar()
        self.area.agregar_icono(directorios + archivos)


if __name__ == '__main__':
    Lestim()
    Gtk.main()
