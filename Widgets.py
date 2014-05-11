#!/usr/bin/env python
# -*- coding: utf-8 -*-

#  Widgets.py por:
#     Cristian García: cristian99garcia@gmail.com

import os
import sys
import time
import cairo
import alsaaudio
# import thread
import ConfigParser
import Globals as G

from modules import brightness
from modules import ScanFolder

from gi.repository import Gtk
from gi.repository import Gdk
from gi.repository import GdkPixbuf
from gi.repository import GObject
from gi.repository import Gio

icon_theme = Gtk.IconTheme()
icons = icon_theme.list_icons(None)


class WindowWithoutTitleBar(Gtk.Window):
    
    def __init__(self, position=None, destroy_when_close=True):
        
        Gtk.Window.__init__(self)

        if position:
            self.move(*position)

        self._destroy = destroy_when_close

        self.connect('realize', self.do_realized)
        self.connect('focus-out-event', self.close_cb)

    def do_realized(self, widget):
        
        win = self.get_window()
        win.set_decorations(False)
        win.process_all_updates()

    def close_cb(self, *args):
        
        if self._destroy:
            self.destroy()
        
        else:
            self.hide()


class PopupMenuButton(Gtk.ScaleButton):
    
    def __init__(self, label, popup_widget):
        
        Gtk.ScaleButton.__init__(self)

        self.set_relief(Gtk.ReliefStyle.NONE)

        self.label = Gtk.Label(label)
        self.popup_widget = popup_widget

        self.remove(self.get_children()[0])
        self.add(self.label)

        self.connect('clicked', self._clicked)

        self.hack()

    def hack(self):

        win = self.get_popup()

        if 'GtkWindow' in str(win):
            frame = win.get_children()[0]
            _vbox = frame.get_children()[0]
            vbox = Gtk.VBox()

            vbox.add(self.popup_widget)
            frame.remove(_vbox)
            frame.add(vbox)

        elif 'GtkPopover' in str(win):
            vbox = win.get_children()[0]

            vbox.remove(vbox.get_children()[0])
            vbox.remove(vbox.get_children()[0])
            vbox.remove(vbox.get_children()[0])
            vbox.add(self.popup_widget)

            vbox.show_all()

    def _clicked(self, widget):
        
        if not self.popup_widget.get_visible():
            self.popup_widget.show_all()


class PopupEntrySearch(WindowWithoutTitleBar):

    __gsignals__ = {
        'search-changed': (GObject.SIGNAL_RUN_FIRST, None, [str])
        }

    def __init__(self):

        tx = 200
        ty = 35

        WindowWithoutTitleBar.__init__(self, (G.width, G.height - ty))# (G.width - (tx / 2), G.height - (ty / 2)))
        
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


class Area(Gtk.IconView):

    __gtype_name__ = 'DesktopArea'

    __gsignals__ = {
        'show-panel': (GObject.SIGNAL_RUN_FIRST, None, [bool])
        }

    def __init__(self):

        Gtk.IconView.__init__(self)

        self.always_visible = G.get_settings()['panel-siempre-visible']
        self.modelo = Gtk.ListStore(str, GdkPixbuf.Pixbuf)
        self.scan_foolder = ScanFolder.ScanFolder(G.get_desktop_directory())

        self.set_selection_mode(Gtk.SelectionMode.MULTIPLE)
        self.set_model(self.modelo)
        self.set_text_column(G.ICONVIEW_TEXT_COLUMN)
        self.set_pixbuf_column(G.ICONVIEW_PIXBUF_COLUMN)
        self.set_item_orientation(Gtk.Orientation.VERTICAL)
        # self.set_item_width(100)
        # self.set_margin(0)
        # self.set_item_padding(0)
        self.set_reorderable(True)
        # self.set_columns(2)

        self.add_events(
            Gdk.EventMask.KEY_PRESS_MASK |
            Gdk.EventMask.KEY_RELEASE_MASK |
            Gdk.EventMask.POINTER_MOTION_MASK |
            Gdk.EventMask.POINTER_MOTION_HINT_MASK |
            Gdk.EventMask.BUTTON_MOTION_MASK |
            Gdk.EventMask.BUTTON_PRESS_MASK |
            Gdk.EventMask.BUTTON_RELEASE_MASK
        )

        self.connect('button-press-event', self.on_click_press)
        self.connect('key-press-event', self.on_button_press)
        self.scan_foolder.connect('files-changed', self.agregar_iconos)

    def do_motion_notify_event(self, event):

        x, y = (int(event.x), int(event.y))
        rect = self.get_allocation()
        xx, yy, ww, hh = (rect.x, rect.y, rect.width, rect.height)

        if y in range(G.height - 100, G.height) and not self.always_visible:
            self.emit('show-panel', True)

        elif y not in range(G.height - 100, G.height) and not self.always_visible:
            self.emit('show-panel', False)

    def on_click_press(self, widget, event):

        def abrir_archivo(aplicacion):

            direccion = os.path.join(self.direccion, aplicacion)

            if not direccion.endswith('.desktop'):
                if ' ' in direccion:
                    direccion = direccion.replace(' ', '\ ')

                os.system('xdg-open %s' % direccion)

            else:
                cfg = ConfigParser.ConfigParser()
                cfg.read([direccion])

                if cfg.has_option('Desktop Entry', 'Exec'):
                    os.system(cfg.has_option('Desktop Entry', 'Exec'))

        boton = event.button
        posx = event.x
        posy = event.y

        if event.type.value_name == 'GDK_2BUTTON_PRESS' and boton == 1:

            try:
                path = self.get_path_at_pos(int(posx), int(posy))
                iter = self.modelo.get_iter(path)

                abrir_archivo(self.modelo.get_value(iter, 0))

            except TypeError:
                pass

    def on_button_press(self, widget, event):

        if event.string.isalpha():
            win = PopupEntrySearch()
            win.connect('search-changed', self.search_text)
            win.entry.set_text(event.string)
            win.entry.select_region(1, 1)

    def search_text(self, widget, text):
        
        self.unselect_all()

        if text:
            text = G.clear_string(text)

            for item in self.modelo:
                label = G.clear_string(list(item)[0])

                if label.startswith(text):
                    self.select_path(item.path)
                    break

    def agregar_iconos(self, scan_foolder, lista):

        self.limpiar()

        for x in lista:
            self.insertar_iter(x)

    def insertar_iter(self, direccion):

        nombre = direccion.split('/')[-1]
        icono = G.get_icon(direccion)

        if nombre.endswith('.desktop'):
            cfg = ConfigParser.ConfigParser()
            cfg.read([direccion])

            if cfg.has_option('Desktop Entry', 'Name'):
                nombre = cfg.get('Desktop Entry', 'Name')

        iter = self.modelo.append([nombre, icono])
        path = self.modelo.get_path(iter)

        tooltip = Gtk.Tooltip()

        tooltip.set_text(direccion)
        tooltip.set_icon(icono)
        self.set_tooltip_item(tooltip, path)

        self.show_all()

    def limpiar(self):

        self.modelo.clear()

    def set_direccion(self, direccion):

        self.direccion = direccion

    def set_panel_visible(self, visible):
        
        self.always_visible = visible
        self.emit('show-panel', self.always_visible)


class Panel(Gtk.Box):

    __gsignals__ = {
        'show-panel': (GObject.SIGNAL_RUN_FIRST, None, [bool])
        }

    def __init__(self, orientacion=Gtk.Orientation.HORIZONTAL):

        Gtk.Box.__init__(self, orientation=orientacion)

        self.boton_aplicaciones = ApplicationsButton()
        self.boton_calendario = CalendarButton()
        self.boton_usuario = UserButton()
        separador1 = Gtk.SeparatorToolItem()
        separador2 = Gtk.SeparatorToolItem()

        separador1.set_expand(True)
        separador2.set_expand(True)
        separador1.set_draw(False)
        separador2.set_draw(False)

        self.boton_aplicaciones.connect('show-panel', lambda x, s: self.emit('show-panel', s))
 
        self.pack_start(self.boton_aplicaciones, False, False, 0)
        self.pack_start(separador1, True, True, 0)
        self.pack_start(self.boton_calendario, False, False, 0)
        self.pack_start(separador2, True, True, 0)
        self.pack_end(self.boton_usuario, False, False, 0)

    def get_applications_menu(self):

        return self.boton_aplicaciones.aplicaciones

    def get_user_menu(self):

        return self.boton_usuario.menu


class FavouriteApplicationsMenu(Gtk.ListBox):
    
    __gsignals__ = {
        'open-application': (GObject.SIGNAL_RUN_FIRST, None, []),
        'remove-from-favourites': (GObject.SIGNAL_RUN_FIRST, None, []),
        }

    def __init__(self, boton):
        
        Gtk.ListBox.__init__(self)

        # self.set_selection_mode(Gtk.SelectionMode.NONE)

        row = Gtk.ListBoxRow()
        row.add(Gtk.Label('Abrir'))
        self.add(row)

        row = Gtk.ListBoxRow()
        row.add(Gtk.Label('Eliminar de favoritos'))
        self.add(row)

        self.connect('row-activated', self.on_selection_changed)

    def on_selection_changed(self, widget, row):
        
        texto = row.get_children()[0].get_label()
        self.emit('open-application' if texto == 'Abrir' else 'remove-from-favourites')


class FavouriteApplicationsButton(PopupMenuButton):
    
    __gtype_name__ = 'FavouriteApplicationsButton'

    __gsignals__ = {
        'open-application': (GObject.SIGNAL_RUN_FIRST, None, [object]),
        'remove-from-favourites': (GObject.SIGNAL_RUN_FIRST, None, [object]),
        'open-menu': (GObject.SIGNAL_RUN_FIRST, None, []),
        }

    def __init__(self, app):

        menu = FavouriteApplicationsMenu(self)

        PopupMenuButton.__init__(self, '', menu)

        self.dicc = app
        self.popover = self.popup_widget.get_parent().get_parent()

        pixbuf = G.get_icon(app['icono-str'])
        imagen = Gtk.Image.new_from_pixbuf(pixbuf)

        self.set_image(imagen)
        self.set_tooltip_text(app['nombre'])
        self.set_relief(Gtk.ReliefStyle.NONE)

        menu.connect('open-application', lambda x: self.emit('open-application', self.dicc))
        menu.connect('open-application', lambda x: self.popup_widget.hide())
        menu.connect('remove-from-favourites', lambda x: self.emit('remove-from-favourites', self.dicc))
        menu.connect('remove-from-favourites', lambda x: self.popup_widget.hide())
        self.disconnect_by_func(self._clicked)
        self.connect('button-press-event', self._on_button_press_event)
        self.connect('open-menu', lambda x: self.popover.show_all())
        self.connect('clicked', lambda x: self.popover.hide())

        self.show_all()

    def _on_button_press_event(self, widget, event):
        
        boton = event.button
        posx = event.x
        posy = event.y

        if event.type.value_name == 'GDK_BUTTON_PRESS' and boton == 3:
            self.emit('open-menu')

        if event.type.value_name == 'GDK_BUTTON_PRESS' and boton == 1:
            self.emit('open-application', self.dicc)


class FavouriteApplications(Gtk.ButtonBox):
    
    __gname_type__ = 'FavouriteApplicationsPanel'

    __gsignals__ = {
        'open-application': (GObject.SIGNAL_RUN_FIRST, None, [object])
        }

    def __init__(self):
        
        Gtk.ButtonBox.__init__(self)

        settings = G.get_settings()
        self.aplicaciones = settings['aplicaciones-favoritas']
        self.area = None

        self.set_layout(Gtk.ButtonBoxStyle.CENTER)
        self.set_spacing(10)
        self.set_size_request(-1, 48)

        self.drag_dest_set(Gtk.DestDefaults.ALL, [], Gdk.DragAction.COPY)
        self.connect('drag-drop', self.on_drag_data_received)

        self.update_buttons()
        self.show_all()

    def on_drag_data_received(self, widget, drag_context, data, info, time):
        
        path = self.area.get_selected_items()[0]
        _iter = self.area.get_model().get_iter(path)
        text = self.area.get_model().get_value(_iter, G.ICONVIEW_TEXT_COLUMN)

        confi = G.get_settings()
        lista = []
        nombres = []
        iconos = []

        for x in self.aplicaciones + [self.area._parent.iters[text]]:
            x['icono'] = x['icono-str']
            # ^^^ Evitando un error de sintaxis

            if (not x in lista) and (not x['nombre'] in nombres and not x['icono-str'] in iconos):
                nombres.append(x['nombre'])
                iconos.append(x['icono-str'])
                lista.append(x)

        confi['aplicaciones-favoritas'] = lista
        self.aplicaciones = lista

        G.set_settings(confi)

        self.update_buttons()
        self.area.unselect_all()

    def update_buttons(self):

        while self.get_children():
            self.remove(self.get_children()[0])
        
        for x in self.aplicaciones:
            boton = FavouriteApplicationsButton(x)
            
            boton.connect('open-application', self._open_application)
            boton.connect('remove-from-favourites', self._remove_from_favourites)
            self.add(boton)
            boton.show()

    def _open_application(self, widget, app):
        
        self.emit('open-application', app)

    def _remove_from_favourites(self, widget, app):

        confi = G.get_settings()
        self.aplicaciones.remove(app)
        confi['aplicaciones-favoritas'] = self.aplicaciones
        
        G.set_settings(confi)

        self.update_buttons()


class ApplicationsArea(Gtk.IconView):

    __gsignals__ = {
        'show-panel': (GObject.SIGNAL_RUN_FIRST, None, [bool])
        }

    def __init__(self):
        
        Gtk.IconView.__init__(self)

        self.modelo = Gtk.ListStore(str, GdkPixbuf.Pixbuf)

        #self.set_selection_mode(Gtk.SelectionMode.NONE)
        self.set_model(self.modelo)
        self.set_text_column(G.ICONVIEW_TEXT_COLUMN)
        self.set_pixbuf_column(G.ICONVIEW_PIXBUF_COLUMN)
        self.set_columns(3)
        self.set_size_request(400, -1)

        self.enable_model_drag_source(Gdk.ModifierType.BUTTON1_MASK, [], Gdk.DragAction.COPY)
        self.connect('drag-begin', lambda *a: self.emit('show-panel', True))


class ApplicationsMenu(Gtk.HBox):

    __gsignals__ = {
        'open-application': (GObject.SIGNAL_RUN_FIRST, None, [object]),
        'show-panel': (GObject.SIGNAL_RUN_FIRST, None, [bool]),
        }

    def __init__(self):

        Gtk.HBox.__init__(self)

        self.listbox = Gtk.ListBox()
        self.area = ApplicationsArea()
        self.area._parent = self
        self.modelo = self.area.modelo
        self.entrada = Gtk.SearchEntry()
        self.buttonbox = Gtk.HBox()
        self.programas = {}
        self.iters = {}

        self.set_apps()

        vbox = Gtk.VBox()
        _hbox = Gtk.HBox()
        scrolled1 = Gtk.ScrolledWindow()
        scrolled2 = Gtk.ScrolledWindow()

        scrolled1.set_size_request(675, 400)
        scrolled1.set_can_focus(False)
        scrolled2.set_size_request(200, -1)
        scrolled2.set_can_focus(False)

        for x in self.categorias:
            row = Gtk.ListBoxRow()
            hbox = Gtk.HBox()

            hbox.pack_start(Gtk.Label(x), False, False, 0)
            row.add(hbox)
            self.listbox.add(row)

        self.listbox.connect('row-activated', self.category_changed)
        self.area.connect('button-release-event', self.click)
        self.area.connect('show-panel', lambda w, s: self.emit('show-panel', s))
        self.entrada.connect('changed', self.app_search)
        self.entrada.connect('activate', self.app_search)

        scrolled1.add(self.area)
        scrolled2.add(self.listbox)
        _hbox.pack_end(self.entrada, False, False, 10)
        vbox.pack_start(_hbox, False, False, 2)
        vbox.pack_start(scrolled1, True, True, 0)
        vbox.pack_end(self.buttonbox, False, False, 0)
        self.pack_start(scrolled2, False, False, 5)
        self.pack_start(vbox, True, True, 0)

        self.show_applications(self.categorias[0])

    def click(self, widget, event):

        posx = event.x
        posy = event.y

        try:
            path = self.area.get_path_at_pos(int(posx), int(posy))
            iter = self.modelo.get_iter(path)
            aplicacion = self.iters[self.modelo.get_value(iter, 0)]

            self.emit('open-application', aplicacion)
            return False

        except TypeError:
            pass

        return True

    def set_apps(self):

        self.modelo.clear()
        self.programas = G.get_applications()
        self.categorias = self.programas.keys()

    def show_applications(self, categoria, apps=None):

        numero = 0
        index = 0
        iters = {}
        self.modelo.clear()

        if apps is None:
            if categoria in self.programas.keys():
                for x in self.programas[categoria]:
                    index += 1 if numero % 12 == 0 else 0
                    numero += 1

                    if index not in iters.keys():
                        iters[index] = []

                    iters[index].append(x)
                    iters[index].sort()

        else:
            for x in apps:
                index += 1 if numero % 12 == 0 else 0
                numero += 1

                if index not in iters.keys():
                    iters[index] = []

                iters[index].append(x)
                iters[index].sort()

        self.app_switch(None, iters, 1)
        self.set_buttons(numero, iters)

    def category_changed(self, widget, row):

        categoria = row.get_children()[0].get_children()[0].get_label()
        self.show_applications(categoria)

    def app_search(self, widget):

        # thread.start_new_thread(self.set_apps, ())

        resultados = []
        texto = G.clear_string(widget.get_text())
        self.entrada.set_progress_pulse_step(0.2)

        if len(texto):
            for categoria in self.categorias:
                for programa in self.programas[categoria]:
                    if type(programa) == dict:
                        app = G.clear_string(programa['nombre'])

                        if texto in app:
                            resultados.append(programa)
                            self.entrada.progress_pulse()

        else:
            resultados = self.programas[self.categorias[0]]

        self.entrada.set_progress_pulse_step(0)
        self.show_applications(None, resultados)

    def app_switch(self, widget, iters, index=None):

        if index is None:
            index = widget.index

        self.modelo.clear()
        self.iters = {}

        if index in iters.keys():
            for x in iters[index]:
                iter = self.modelo.append([x['nombre'], G.get_icon(x['icono-str'])])
                self.iters[x['nombre']] = x

    def set_buttons(self, numero=0, iters={}):

        while self.buttonbox.get_children():
            self.buttonbox.remove(self.buttonbox.get_children()[0])

        s1 = Gtk.HSeparator()
        s2 = Gtk.HSeparator()

        s1.set_hexpand(True)
        s2.set_hexpand(True)

        self.buttonbox.pack_start(s1, True, True, 0)
        self.buttonbox.pack_end(s2, True, True, 0)

        cantidad = numero / 12 if numero % 12 > 0 else 0
        _boton = Gtk.RadioButton.new_from_widget(None)
        _boton.index = 1
        _boton.connect('toggled', self.app_switch, iters)
        _boton.set_hexpand(False)

        self.buttonbox.pack_start(_boton, False, False, 0)

        for x in range(1, cantidad + 1):
            boton = Gtk.RadioButton.new_from_widget(_boton)
            boton.index = x+1

            boton.set_hexpand(False)

            boton.connect('toggled', self.app_switch, iters)
            self.buttonbox.pack_start(boton, False, False, 0)

        self.buttonbox.show_all()

    
class UserMenu(Gtk.ListBox):

    __gsignals__ = {
        'open-settings-window': (GObject.SIGNAL_RUN_FIRST, None, []),
        'close': (GObject.SIGNAL_RUN_FIRST, None, []),
        }

    def __init__(self):

        Gtk.ListBox.__init__(self)
        
        self.set_selection_mode(Gtk.SelectionMode.NONE)
        self.set_size_request(400, 500)

        _hbox = self.create_row()
        hbox = Gtk.HBox()
        expander = Gtk.Expander()

        expander.set_label('Wi-Fi')

        hbox.add(Gtk.Label(G.get_ip()))
        expander.add(hbox)
        _hbox.add(expander)

        hbox = self.create_row(VolumeWidget())

        box = self.create_row(Gtk.ButtonBox())
        boton_confi = Gtk.Button(stock=Gtk.STOCK_PREFERENCES)
        boton_cerrar = Gtk.Button('Salir')

        box.set_layout(Gtk.ButtonBoxStyle.CENTER)
        box.set_spacing(20)

        boton_confi.connect('clicked', lambda widget: self.emit('open-settings-window'))
        boton_cerrar.connect('clicked', lambda widget: self.emit('close'))

        box.add(boton_confi)
        box.add(boton_cerrar)

    def set_value(self, widget, button):

        button.set_value(widget.get_value() / 100)
        G.mixer.setvolume(int(button.get_value() * 100))

    def create_row(self, widget=None):

        # No se puede establecer la variable widget directamente como una HBox
        # porque sino, cada vez que se llame a la función, se tomará en cuenta
        # a la misma HBox, y esto no permite el normal empaquetamiento

        if not widget:
            widget = Gtk.HBox()

        row = Gtk.ListBoxRow()

        row.add(widget)
        self.add(row)

        return widget


class ApplicationsButton(PopupMenuButton):

    __gsignals__ = {
        'show-panel': (GObject.SIGNAL_RUN_FIRST, None, [bool])
        }

    def __init__(self):

        self.aplicaciones = ApplicationsMenu()
        self.aplicaciones.boton = self

        PopupMenuButton.__init__(self, 'Aplicaciones', self.aplicaciones)

        self.aplicaciones.connect('show-panel', lambda x, s: self.emit('show-panel', s))


class UserButton(PopupMenuButton):

    def __init__(self):

        self.menu = UserMenu()
        self.menu.boton = self

        PopupMenuButton.__init__(self, 'Aplicaciones', self.menu)


class CalendarButton(PopupMenuButton):

    def __init__(self):

        PopupMenuButton.__init__(self, '', Gtk.Calendar())

        self.set_time()
        GObject.timeout_add(1000, self.set_time, ())

    def set_time(self, *args):

        actual = time.asctime()

        if actual:
            dia = actual.split(' ')[0]
            mes = actual.split(' ')[1]
            fecha = actual.split(' ')[2]
            hora = actual.split(' ')[3]
            anyo = actual.split(' ')[4]

            dias = {
                'Sun': 'Dom',
                'Mon': 'Lun',
                'Tue': 'Mar',
                'Wed': 'Mié',
                'Thu': 'Jue',
                'Fri': 'Vie',
                'Sat': 'Sáb',
            }

            meses = {
                'Jan': 'Ene',
                'Feb': 'Feb',
                'Mar': 'Mar',
                'Apr': 'Abr',
                'May': 'May',
                'Jun': 'Jun',
                'Jul': 'Jul',
                'Aug': 'Ago',
                'Sep': 'Sep',
                'Nov': 'Nov',
                'Dec': 'Dic',
            }

            texto = hora + '  ' + \
                dias[dia] + ', ' + \
                fecha + ' de ' + \
                meses[mes] + ' del ' + anyo

            self.label.set_text(texto)

        return True


class SettingsWindow(Gtk.Window):

    __gtype_name__ = 'FavouriteApplicationsPanel'

    __gsignals__ = {
        'settings-changed': (GObject.SIGNAL_RUN_FIRST, None, [object])
        }
    
    def __init__(self):

        Gtk.Window.__init__(self)

        self.titlebar = Gtk.HeaderBar()
        self.vbox = Gtk.VBox()
        self.stack = Gtk.Stack()
        self.stack_switcher = Gtk.StackSwitcher()
        self.confi = G.get_settings()

        self.set_titlebar(self.titlebar)
        self.titlebar.set_show_close_button(True)
        self.titlebar.set_tooltip_text(
            'Algunos cambios tendrán efecto en la siguiente sesión')
        self.stack.set_transition_type(
            Gtk.StackTransitionType.SLIDE_LEFT_RIGHT)
        self.stack.set_transition_duration(1000)

        # Sección: Apariencia
        vbox = Gtk.VBox()
        hbox = Gtk.HBox()
        entrada = Gtk.Entry()
        boton = Gtk.Button()
        label = Gtk.Label()

        entrada.set_editable(False)
        entrada.set_text(self.confi['fondo-simbolico'])
        label.set_markup("<big><big><big>···</big></big></big>")

        boton.connect('clicked', self.file_chooser_images)

        boton.add(label)
        hbox.pack_start(Gtk.Label('Fondo de escritorio:'), False, False, 2)
        hbox.pack_start(entrada, True, True, 5)
        hbox.pack_end(boton, False, False, 0)
        vbox.pack_start(hbox, False, False, 2)
        self.stack.add_titled(vbox, 'Apariencia', 'Apariencia')

        # Falta crear toda la interfaz y funcionalidad para el resto de las
        # secciones de configuración
        actual = brightness.get_current_brightness()
        minimo = 0
        maximo = brightness.get_max_brightness()

        vbox = Gtk.VBox()
        hbox = Gtk.HBox()
        adj = Gtk.Adjustment(actual, minimo, maximo, 10, 0)
        scale = Gtk.HScale(adjustment=adj)

        scale.set_adjustment(adj)
        scale.set_draw_value(False)

        scale.connect('value-changed', lambda w:
                      brightness.set_brightness(w.get_value()))

        hbox.pack_start(Gtk.Label('Brillo'), False, False, 10)
        hbox.pack_end(scale, True, True, 0)
        vbox.pack_start(hbox, False, False, 2)
        self.stack.add_titled(vbox, 'Energía', 'Energía')

        vbox = Gtk.VBox()
        hbox = VolumeWidget()

        vbox.pack_start(hbox, False, False, 2)
        self.stack.add_titled(vbox, 'Sonido', 'Sonido')

        vbox = Gtk.VBox()
        listbox = Gtk.ListBox()
        hbox = self.create_row(listbox)
        switch = Gtk.Switch()
        
        listbox.set_selection_mode(Gtk.SelectionMode.NONE)
        switch.set_active(self.confi['panel-siempre-visible'])

        switch.connect('notify::active', lambda w, x: self.settings_changed(w, 'panel-siempre-visible', w.get_active()))

        hbox.pack_start(Gtk.Label('Ocultar automáticamente'), False, False, 0)
        hbox.pack_end(switch, False, False, 0)

        vbox.pack_start(listbox, True, True, 5)
        self.stack.add_titled(vbox, 'Panel inferior', 'Panel inferior')

        self.stack_switcher.set_stack(self.stack)
        self.titlebar.add(self.stack_switcher)
        self.vbox.pack_start(self.stack, True, True, 0)

        self.connect('settings-changed', self.save_settings)

        self.add(self.vbox)
        self.show_all()

    def settings_changed(self, widget, key, value):
        
        self.confi[key] = value
        self.emit('settings-changed', self.confi)

    def save_settings(self, *args):
        
        G.set_settings(self.confi)

    def create_row(self, listbox):
        
        row = Gtk.ListBoxRow()
        hbox = Gtk.HBox()
        
        row.add(hbox)
        listbox.add(row)

        return hbox

    def file_chooser_images(self, widget):

        def abrir(widget, self, chooser):

            self.confi['fondo-simbolico'] = chooser.get_filename()
            G.set_settings(self.confi)

        chooser = Gtk.FileChooserDialog()
        buttonbox = chooser.get_children()[0].get_children()[1]
        boton_abrir = Gtk.Button(stock=Gtk.STOCK_OPEN)
        boton_cancelar = Gtk.Button(stock=Gtk.STOCK_CANCEL)
        _filter = Gtk.FileFilter()

        _filter.set_name('Imágnes')
        _filter.add_mime_type("image/*")
        chooser.set_filename(self.confi['fondo-simbolico']
                             if os.path.exists(self.confi['fondo-simbolico'])
                             else os.path.join(
                                os.path.expanduser('~/'), os.getlogin())
                             )

        chooser.set_title('Seleccione una imagen')
        chooser.set_action(Gtk.FileChooserAction.OPEN)
        chooser.add_filter(_filter)
        chooser.set_parent(self)
        chooser.set_modal(True)

        boton_abrir.connect('clicked', abrir, self, chooser)
        boton_abrir.connect('clicked', lambda x: chooser.destroy())
        boton_cancelar.connect('clicked', lambda x: chooser.destroy())

        buttonbox.add(boton_cancelar)
        buttonbox.add(boton_abrir)

        chooser.show_all()


class VolumeWidget(Gtk.HBox):

    def __init__(self):

        Gtk.HBox.__init__(self)

        adj = Gtk.Adjustment(int(G.mixer.getvolume()[0]), 25, 100, 1, 10, 0)
        self.button = Gtk.VolumeButton()
        self.scale = Gtk.HScale(adjustment=adj)

        self.button.set_sensitive(False)
        self.button.set_opacity(1)
        self.button.set_value(self.scale.get_value() / 100)
        self.scale.set_show_fill_level(True)
        self.scale.set_draw_value(False)

        self.scale.connect('value-changed', lambda x: self.set_value())

        self.pack_start(self.button, False, False, 0)
        self.pack_start(self.scale, True, True, 0)

    def set_value(self, valor=None):

        if valor is None:
            valor = int(self.scale.get_value())

        self.button.set_value(valor / 100.0)
        G.mixer.setvolume(valor)
