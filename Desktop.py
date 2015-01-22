#!/usr/bin/env python
# -*- ccoding: utf-8 -*-

from gi.repository import Gtk
from gi.repository import GObject

import Globales as G

from Widgets import WWTB
from Widgets import WorkArea
from Widgets import AppsView
from Widgets import DownPanel
from Widgets import LateralPanel
from Widgets import SettingsWindow


class Ventana(WWTB):

    __gtype_name__ = 'PrincipalWindow'

    def __init__(self):
        WWTB.__init__(self, pos=(0, 0), size=G.Sizes.DISPLAY_SIZE)

        self.workarea = WorkArea()
        self.lateralpanel = LateralPanel()
        self.downpanel = DownPanel()
        self.appsview = AppsView()
        self.vbox = Gtk.VBox()
        self.hbox = Gtk.HBox()

        self.connect('destroy', Gtk.main_quit)
        self.lateralpanel.connect('settings', self.launch_settings_window)
        self.downpanel.connect('show-apps', self.show_apps)
        self.downpanel.connect('show-lateral-panel', self.show_lateral_panel)
        self.appsview.connect('run-app', self.run_app)
        self.appsview.connect('favorited-app', self.downpanel.update_buttons)

        self.hbox.pack_start(self.workarea, True, True, 0)
        self.hbox.pack_end(self.lateralpanel, False, False, 0)
        self.vbox.pack_start(self.hbox, True, True, 0)
        self.vbox.pack_end(self.downpanel, False, False, 0)

        self.add(self.vbox)
        self.show_all()
        self.lateralpanel.hide()

    def set_principal_widget(self, widget):
        """
        Está hecho así, para que se puedan usar terminales en lugar de
        del iconview y cosas por el estilo.
        """

        self.hbox.remove(self.hbox.get_children()[0])
        self.hbox.pack_start(widget, True, True, 0)
        self.show_all()
        self.downpanel.indicadores.boton_panel_lateral.set_label('>')
        self.lateralpanel.hide()

    def show_apps(self, widget):
        if not self.appsview in self.hbox.get_children():
            self.set_principal_widget(self.appsview)

        else:
            self.set_principal_widget(self.workarea)

    def run_app(self, widget, app):
        self.set_principal_widget(self.workarea)
        G.run_app(app)

    def launch_settings_window(self, *args):
        def _open():
            SettingsWindow()

        self.show_lateral_panel(None, False)
        GObject.idle_add(_open)

    def show_lateral_panel(self, widget, visible):
        if visible:
            self.lateralpanel.show_all()
            self.downpanel.indicadores.boton_panel_lateral.set_label('<')

        else:
            self.lateralpanel.hide()
            self.downpanel.indicadores.boton_panel_lateral.set_label('>')


if __name__ == '__main__':

    Ventana()
    Gtk.main()
