#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
import thread
import Globales

from gi.repository import Gtk
from gi.repository import Gdk
from gi.repository import GObject
from gi.repository import GdkPixbuf

from modules import ScanFolder

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


class PopupEntrySearch(WWTB):

    __gsignals__ = {
        'search-changed': (GObject.SIGNAL_RUN_FIRST, None, [str])
        }

    def __init__(self):

        tx = 200
        ty = 35

        WWTB.__init__(self, (Globales.width, Globales.height - ty))

        self.entry = Gtk.SearchEntry()

        self.resize(tx, ty)
        self.entry.set_size_request(tx, ty)
        self.entry.grab_focus()

        self.entry.connect('changed', lambda w: self.emit('search-changed', w.get_text()))
        self.entry.connect('key-press-event', self.button_press_event_cb)

        self.add(self.entry)
        self.show_all()

    def button_press_event_cb(self, widget, event):

        if event.string == "": # En realidad esta cadena alberga el caracter "Escape"
            self.destroy()


class WorkArea(Gtk.IconView):

    __gtype_name__ = 'WorkArea'

    def __init__(self):
        Gtk.IconView.__init__(self)

        self.modelo = Gtk.ListStore(str, GdkPixbuf.Pixbuf)
        self.scan_foolder = ScanFolder.ScanFolder(Globales.get_user_directories()['escritorio'])

        self.set_selection_mode(Gtk.SelectionMode.MULTIPLE)
        self.set_model(self.modelo)
        self.set_text_column(0)
        self.set_pixbuf_column(1)
        self.set_item_orientation(Gtk.Orientation.VERTICAL)

        self.add_events(
            Gdk.EventMask.KEY_PRESS_MASK |
            Gdk.EventMask.KEY_RELEASE_MASK |
            Gdk.EventMask.BUTTON_PRESS_MASK
        )

        self.connect('button-press-event', self.on_click_press)
        self.connect('key-press-event', self.buscar_archivo)
        self.scan_foolder.connect('files-changed', self.agregar_iconos)

    def on_click_press(self, widget, event):
        boton = event.button
        tiempo = event.time
        posx = event.x
        posy = event.y

        if event.type.value_name == 'GDK_2BUTTON_PRESS' and boton == 1:
            try:
                path = self.get_path_at_pos(int(posx), int(posy))
                iter = self.modelo.get_iter(path)

                Globales.open_file(os.path.join(Globales.get_user_directories()['escritorio'], self.modelo.get_value(iter, 0)))

            except TypeError:
                pass

        elif event.type.value_name == 'GDK_BUTTON_PRESS' and boton == 3:
            return True

    def buscar_archivo(self, widget, event):
        if event.string.isalpha():
            win = PopupEntrySearch()
            win.connect('search-changed', self.search_text)
            win.entry.set_text(event.string)
            win.entry.select_region(1, 1)

    def open_files(self, *args):
        for x in self.get_selected_items():
            iter = self.modelo.get_iter(x)
            nombre = self.modelo.get_value(iter, 0)
            archivo = os.path.join(Globales.get_desktop_directory(), nombre)

            if not os.path.exists(archivo):
                for x in os.listdir(Globales.get_desktop_directory()):
                    if x.endswith('.desktop'):
                        if ConfigParser.has_option('Desktop Entry', 'Name') and \
                            ConfigParser.get('Desktop Entry', 'Name') == nombre:
                            archivo = os.path.join(Globales.get_desktop_directory(), x)

                            break

            Globales.open_file(archivo)

    def search_text(self, widget, text):
        self.unselect_all()

        if text:
            text = Globales.clear_string(text)

            for item in self.modelo:
                label = Globales.clear_string(list(item)[0])

                if label.startswith(text):
                    self.select_path(item.path)
                    break

    def agregar_iconos(self, scan_foolder, lista):
        self.limpiar()
        for x in lista:
            self.insertar_iter(x)

    def limpiar(self):
        self.modelo.clear()

    def set_direccion(self, direccion):
        self.direccion = direccion

    def insertar_iter(self, direccion):
        nombre = direccion.split('/')[-1]
        icono = Globales.get_icon(direccion)

        if nombre.endswith('.desktop'):
            cfg = ConfigParser.ConfigParser()
            cfg.read([direccion])

            if cfg.has_option('Desktop Entry', 'Name'):
                nombre = cfg.get('Desktop Entry', 'Name')

        iter = self.modelo.append([nombre, icono])
        path = self.modelo.get_path(iter)

        self.show_all()


class ShutdownButton(Gtk.Button):

    __gtype_name__ = 'ShutdownButton'

    def __init__(self):
        Gtk.Button.__init__(self)

        self.imagen = Gtk.Image.new_from_file(Globales.Paths.ICON_SHUTDOWN)
        self.set_tooltip_text('Apagar')
        self.add(self.imagen)


class RebootButton(Gtk.Button):

    __gtype_name__ = 'RebootButton'

    def __init__(self):
        Gtk.Button.__init__(self)

        self.imagen = Gtk.Image.new_from_file(Globales.Paths.ICON_REBOOT)
        self.set_tooltip_text('Reiniciar')
        self.add(self.imagen)


class LockButton(Gtk.Button):

    __gtype_name__ = 'LockButton'

    def __init__(self):
        Gtk.Button.__init__(self)

        self.imagen = Gtk.Image.new_from_file(Globales.Paths.ICON_LOCK)
        self.set_tooltip_text('Bloquear')
        self.add(self.imagen)


class SettingsButton(Gtk.Button):

    __gtype_name__ = 'SettingsButton'

    def __init__(self):
        Gtk.Button.__init__(self)

        self.imagen = Gtk.Image.new_from_file(Globales.Paths.ICON_SETTINGS)
        self.set_tooltip_text('Ajustes')
        self.add(self.imagen)


class LateralPanel(Gtk.VBox):

    __gtype_name__ = 'LateralPanel'

    __gsignals__ = {
        'settings': (GObject.SIGNAL_RUN_FIRST, None, [])
        }

    def __init__(self):
        Gtk.VBox.__init__(self)

        s_volumen = Gtk.HScale()
        a_volumen = Gtk.Adjustment(Globales.get_actual_volume(), 0, 100, 1, 10)
        i_volumen = Gtk.Image.new_from_icon_name('audio-volume-muted', Gtk.IconSize.MENU)
        s_brillo = Gtk.HScale()
        a_brillo = Gtk.Adjustment(Globales.get_actual_brightness(), 10, 100, 1, 10)
        i_brillo = Gtk.Image.new_from_icon_name('display-brightness-symbolic', Gtk.IconSize.MENU)

        hbox = Gtk.HBox()
        b_apagar = ShutdownButton()
        b_reiniciar = RebootButton()
        b_bloquear = LockButton()
        b_ajustes = SettingsButton()

        s_volumen.set_adjustment(a_volumen)
        s_volumen.set_draw_value(False)
        s_brillo.set_adjustment(a_brillo)
        s_brillo.set_draw_value(False)
        self.set_size_request(300, -1)

        s_brillo.connect('value-changed', lambda w: Globales.set_brightness(w.get_value()))
        b_ajustes.connect('clicked', lambda w: self.emit('settings'))

        hbox.pack_start(b_apagar, True, True, 10)
        hbox.pack_start(b_reiniciar, True, True, 10)
        hbox.pack_start(b_bloquear, True, True, 10)
        hbox.pack_start(b_ajustes, True, True, 10)
        self.pack_end(hbox, False, False, 10)
        self.add_widgets(i_volumen, s_volumen)
        self.add_widgets(i_brillo, s_brillo)

    def add_widgets(self, icono, widget):
        hbox = Gtk.HBox()
        hbox.pack_start(icono, False, False, 1)
        hbox.pack_start(widget, True, True, 0)
        self.pack_start(hbox, False, False, 1)


class AppButtonPopover(Gtk.Popover):

    __gtype_name__ = 'AppButtonPopover'

    __gsignals__ = {
        'favorited': (GObject.SIGNAL_RUN_FIRST, None, [bool]),
        }

    def __init__(self, button, app):
        Gtk.Popover.__init__(self)

        self.vbox = Gtk.VBox()
        self.c_favorito = Gtk.CheckButton('En favoritos')

        self.set_relative_to(button)
        self.c_favorito.set_active(app in Globales.get_settings()['aplicaciones-favoritas'])
        
        self.c_favorito.connect('toggled', self.favorited)

        self.vbox.pack_start(self.c_favorito, True, True, 1)
        self.add(self.vbox)

    def favorited(self, *args):
        self.emit('favorited', self.c_favorito.get_active())


class AppButton(Gtk.Button):

    __gtype_name__ = 'AppButton'

    __gsignals__ = {
        'run-app': (GObject.SIGNAL_RUN_FIRST, None, []),
        'favorited': (GObject.SIGNAL_RUN_FIRST, None, []),
        }

    def __init__(self, app, label=None, icon_size=32):
        Gtk.Button.__init__(self)

        self.app = app
        self.popover = AppButtonPopover(self, app)

        vbox = Gtk.VBox()
        pixbuf = Globales.get_icon(app['icono'], icon_size)
        imagen = Gtk.Image.new_from_pixbuf(pixbuf)

        if not label:
            self.set_tooltip_text(app['nombre'])

        elif label:
            texto = app['nombre']
            texto = texto[:20] + '...' if len(texto) > 20 else texto
            vbox.pack_end(Gtk.Label(texto), False, False, 0)

        self.connect('button-release-event', self.button_press_event_cb)
        self.popover.connect('favorited', self.favorited_cb)

        vbox.pack_start(imagen, True, True, 0)

        self.add(vbox)

    def button_press_event_cb(self, widget, event):
        if event.button == 1:
            self.emit('run-app')

        elif event.button == 3:
            self.popover.show_all()

    def favorited_cb(self, widget, favorito):
        configuracion = Globales.get_settings()

        if favorito:
            configuracion['aplicaciones-favoritas'].append(self.app)

        elif not favorito and self.app in configuracion['aplicaciones-favoritas']:
            configuracion['aplicaciones-favoritas'].remove(self.app)

        Globales.set_settings(configuracion)
        self.emit('favorited')


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

        self.pack_start(self.lanzador, False, False, 2)
        self.pack_start(self.buttons_area, True, True, 2)
        self.pack_end(self.indicadores, False, False, 0)

        self.update_buttons()
        self.show_all()

    def add_app_button(self, app):
        boton = AppButton(app)
        boton.connect('favorited', self.update_buttons)
        self.buttons_area.pack_start(boton, False, False, 0)

    def update_buttons(self, *args):
        while self.buttons_area.get_children():
            self.buttons_area.remove(self.buttons_area.get_children()[-1])

        for app in Globales.get_settings()['aplicaciones-favoritas']:
            self.add_app_button(app)

        self.show_all()


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
        'favorited-app': (GObject.SIGNAL_RUN_FIRST, None, []),
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
            boton.connect('favorited', lambda w: self.emit('favorited-app'))
            self.fbox.add(boton)

        self.show_all()

    def search_app(self, widget):
        for x in self.fbox.get_children():
            boton = x.get_children()[0]
            if widget.get_text().lower() in boton.app['nombre'].lower():
                x.show_all()

            else:
                x.hide()


class SettingsWindow(Gtk.Window):

    __gtype_name__ = 'SettingsWindow'

    def __init__(self):
        Gtk.Window.__init__(self)

        headerbar = Gtk.HeaderBar()
        self.icon_view = Gtk.IconView()

        headerbar.set_show_close_button(True)
        self.set_titlebar(headerbar)

        self.make_view_backgrounds()

    def make_view_backgrounds(self):
        # Permitir que se puedan seleccionar varios fondos, y seleccionar a cada
        # cuantos segundos pasan

        self.selector_de_fondo = Gtk.VBox()
        scrolled = Gtk.ScrolledWindow()
        hbox = Gtk.HBox()
        b_ok = Gtk.Button.new_from_stock(Gtk.STOCK_OK)
        box = Gtk.FlowBox()
        box.change = False
        backgrounds = Globales.get_backgrounds()

        for x in backgrounds:
            pixbuf = GdkPixbuf.Pixbuf.new_from_file_at_size(x, 300, 150)
            imagen = Gtk.Image.new_from_pixbuf(pixbuf)
            imagen.archivo = x
            box.add(imagen)

        box.set_homogeneous(True)
        box.set_selection_mode(Gtk.SelectionMode.SINGLE)
        box.unselect_all()

        box.connect('selected-children-changed', self.set_fondo)

        hbox.pack_end(b_ok, False, False, 2)
        scrolled.add(box)
        self.selector_de_fondo.add(scrolled)
        self.selector_de_fondo.pack_end(hbox, False, False, 2)

    def set_fondo(self, widget):
        if not widget.change: # La primera vez se activa solo
            widget.change = True
            return

        if widget.get_selected_children():
            imagen = widget.get_selected_children()[0].get_children()[0]
            archivo = imagen.archivo

            GObject.idle_add(Globales.set_background, archivo, True)