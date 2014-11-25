#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
import Globales

from gi.repository import Gtk
from gi.repository import GObject


Globales.set_theme()


class WWTB(Gtk.Window):

    __gtype_name__ = 'WindowWithoutTitleBar'

    def __init__(self, pos=(300, 300), size=(300, 400)):
        Gtk.Window.__init__(self)

        self.move(*pos)
        self.resize(*size)

        self.connect('realize', self.do_realized)

    def do_realized(self, widget):

        self.get_window().set_decorations(False)
        self.get_window().process_all_updates()


class WorkArea(Gtk.IconView):

    __gtype_name__ = 'WorkArea'

    def __init___(swlf):
        Gtk.IconView.__init__(self)


class LateralPanel(Gtk.VBox):

    __gtype_name__ = 'LateralPanel'

    def __init__(self):
        Gtk.VBox.__init__(self)

        s_volumen = Gtk.HScale()
        a_volumen = Gtk.Adjustment(Globales.get_actual_volume(), 0, 100, 1, 10)
        i_volumen = Gtk.Image.new_from_icon_name('audio-volume-muted', Gtk.IconSize.MENU)
        s_brillo = Gtk.HScale()
        a_brillo = Gtk.Adjustment(Globales.get_actual_brightness(), 10, 100, 1, 10)
        i_brillo = Gtk.Image.new_from_icon_name('display-brightness-symbolic', Gtk.IconSize.MENU)

        s_volumen.set_adjustment(a_volumen)
        s_volumen.set_draw_value(False)
        s_brillo.set_adjustment(a_brillo)
        s_brillo.set_draw_value(False)
        self.set_size_request(300, -1)

        s_brillo.connect('value-changed', lambda w: Globales.set_brightness(w.get_value()))

        self.add_widgets(i_volumen, s_volumen)
        self.add_widgets(i_brillo, s_brillo)

    def add_widgets(self, icono, widget):
        hbox = Gtk.HBox()
        hbox.pack_start(icono, False, False, 1)
        hbox.pack_start(widget, True, True, 0)
        self.pack_start(hbox, False, False, 1)


class AppButtonMenu(Gtk.Window):

    __gtype_name__ = 'AppButtonMenu'

    def __init__(self, button):
        Gtk.Window.__init__(self)


class AppButtonPopover(Gtk.Popover):

    __gtype_name__ = 'AppButtonPopover'

    def __init__(self, button):
        Gtk.Window.__init__(self)


class AppButton(Gtk.Button):

    __gtype_name__ = 'AppButton'

    def __init__(self, app, label=None, icon_size=32):
        Gtk.Button.__init__(self)

        self.app = app

        vbox = Gtk.VBox()
        pixbuf = Globales.get_icon(app['icono'], icon_size)
        imagen = Gtk.Image.new_from_pixbuf(pixbuf)

        if not label:
            self.set_tooltip_text(app['nombre'])

        elif label:
            texto = app['nombre']
            texto = texto[:20] + '...' if len(texto) > 20 else texto
            vbox.pack_end(Gtk.Label(texto), False, False, 0)

        vbox.pack_start(imagen, True, True, 0)

        self.add(vbox)


class IndicatorsArea(Gtk.HBox):

    __gtype_name__ = 'IndicatorsArea'

    __gsignals__ = {
        'show-lateral-panel': (GObject.SIGNAL_RUN_FIRST, None, [bool]),
        }

    def __init__(self):
        Gtk.HBox.__init__(self)

        self.boton_calendario = Gtk.Button(Globales.get_time())
        self.boton_panel_lateral = Gtk.Button('>')

        GObject.timeout_add(500, self.set_time, ())
        self.boton_panel_lateral.connect('clicked', self.show_lateral_panel)

        self.pack_end(self.boton_panel_lateral, False, False, 1)
        self.pack_end(self.boton_calendario, False, False, 1)

    def set_time(self, *args):
        self.boton_calendario.set_label(Globales.get_time())
        return True

    def show_lateral_panel(self, widget):

        if widget.get_label() == '>':
            widget.set_label('<')
            self.emit('show-lateral-panel', True)

        elif widget.get_label() == '<':
            widget.set_label('>')
            self.emit('show-lateral-panel', False)


class DownPanel(Gtk.HBox):

    __gtype_name__ = 'DownPanel'

    __gsignals__ = {
        'show-apps': (GObject.SIGNAL_RUN_FIRST, None, []),
        'show-lateral-panel': (GObject.SIGNAL_RUN_FIRST, None, [bool]),
        }

    def __init__(self):
        Gtk.HBox.__init__(self)

        self.lanzador = AppButton({'icono': 'distributor-logo', 'nombre': 'Mostrar aplicaciones'})
        self.buttons_area = Gtk.HBox()
        self.indicadores = IndicatorsArea()

        self.lanzador.connect('clicked', lambda w: self.emit('show-apps'))
        self.indicadores.connect('show-lateral-panel', lambda w, v: self.emit('show-lateral-panel', v))

        self.pack_start(self.buttons_area, True, True, 2)
        self.pack_end(self.indicadores, False, False, 0)
        self.add_app_button(self.lanzador)

    def add_app_button(self, boton):
        self.buttons_area.pack_start(boton, False, False, 1)


class AppsEntry(Gtk.Entry):

    __gtype_name__ = 'AppsEntry'

    def __init__(self):
        Gtk.Entry.__init__(self)

        self.set_placeholder_text('Buscar...')
        self.props.xalign = 0.015


class AppsView(Gtk.VBox):

    __gtype_name__ = 'AppsView'

    __gsignals__ = {
        'run-app': (GObject.SIGNAL_RUN_FIRST, None, [object]),
        }

    def __init__(self):
        Gtk.VBox.__init__(self)

        scrolled = Gtk.ScrolledWindow()
        self.entry = AppsEntry()
        self.fbox = Gtk.FlowBox()

        GObject.idle_add(self.show_all_apps)
        self.fbox.set_max_children_per_line(5)

        self.entry.connect('changed', self.search_app)

        scrolled.add(self.fbox)
        self.pack_start(self.entry, False, False, 20)
        self.pack_start(scrolled, True, True, 0)

    def show_all_apps(self, *args):
        apps = {}

        for archivo in os.listdir(Globales.Paths.APPS_DIR):
            app = Globales.get_app(archivo)

            if app:
                apps[app['nombre']] = app

        n_apps = apps.keys()
        n_apps.sort()

        for x in n_apps:
            boton = AppButton(apps[x], label=True, icon_size=64)
            boton.connect('clicked', lambda w: self.emit('run-app', apps[x]))
            self.fbox.add(boton)

        self.show_all()

    def search_app(self, widget):
        for x in self.fbox.get_children():
            boton = x.get_children()[0]
            if widget.get_text().lower() in boton.app['nombre'].lower():
                x.show_all()

            else:
                x.hide()