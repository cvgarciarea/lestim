#!/usr/bin/env python
# -*- coding: utf-8 -*-

#  Globals.py por:
#     Cristian García: cristian99garcia@gmail.com

import os
import Image
import alsaaudio
import ConfigParser

try:
    import Image

except ImportError:
    from PIL import Image

from modules import enumerate_interfaces

from Xlib.display import Display

from gi.repository import GLib
from gi.repository import GdkPixbuf
from gi.repository import Gio
from gi.repository import Gtk


mixer = alsaaudio.Mixer()
background_path = os.path.expanduser('~/.lestim/background.jpg')
main_window_icon = os.path.join(os.path.dirname(__file__), 'images/logo.svg')
display = Display()
root = display.screen().root
desktop = root.get_geometry()
width = desktop.width
height = desktop.height
categories = [
    'Accesorios',
    'Acceso universal',
    'Configuración del sistema',
    'Aplicaciones web',
    'Ciencia',
    'Educación',
    'Gráficos',
    'Internet',
    'Juegos',
    'Oficina',
    'Programación',
    'Sonido y vídeo',
    'Wine'
]

settings_dir = os.path.expanduser('~/.lestim/')
settings_path = os.path.expanduser('~/.lestim/settings.json')

if not os.path.isdir(settings_dir):
    os.makedirs(settings_dir)

if not os.path.isfile(settings_path):
    archivo = open(settings_path, 'w')
    configuracion = '''{
    "fondo-simbolico": "%s",
}''' % os.path.join(os.path.dirname(__file__), 'images/background.jpg')

    archivo.write(configuracion)
    archivo.close()

GLib.set_application_name('Lestim')


def get_settings():

    archivo = open(settings_path)
    configuracion = eval(archivo.read())

    return configuracion


def set_settings(diccionario):

    archivo = open(settings_path, 'w')
    archivo.write(str(diccionario))
    archivo.close()

    set_background()


def get_display_dimensions():

    return width, height


def get_desktop_directory():

    direccion = os.path.expanduser('~/.config/user-dirs.dirs')
    directorio = os.path.expanduser('~/Desktop')

    if os.path.isfile(direccion):
        texto = open(direccion).read()

        for linea in texto.splitlines():
            if linea.startswith('XDG_DESKTOP_DIR="$HOME/'):
                directorio = linea.split('XDG_DESKTOP_DIR="$HOME/')[1][:-1]
                directorio = os.path.expanduser('~/%s' % directorio)

                break

    if not os.path.exists(directorio):
        os.mkdir(directorio)

    return directorio


def get_files():

    escritorio = get_desktop_directory()
    _archivos = os.listdir(escritorio)
    directorios = []
    archivos = []

    for x in _archivos:
        if not x.startswith('.'):
            direccion = os.path.join(escritorio, x)

            if os.path.isdir(direccion):
                directorios.append(direccion)

            elif os.path.isfile(direccion):
                archivos.append(direccion)

    directorios.sort()
    archivos.sort()

    return directorios, archivos


def get_applications():

    categorias = {}
    directorio = '/usr/share/applications/'

    for aplicacion in os.listdir(directorio):
        if aplicacion.endswith('.desktop'):
            archivo = os.path.join(directorio, aplicacion)
            cfg = ConfigParser.ConfigParser()
            nombre = None
            icono = None
            ejecutar = None
            _categoria = None

            cfg.read([archivo])

            if cfg.has_option('Desktop Entry', 'Name'):
                nombre = cfg.get('Desktop Entry', 'Name')

            if cfg.has_option('Desktop Entry', 'Name[es]'):
                nombre = cfg.get('Desktop Entry', 'Name[es]')

            if cfg.has_option('Desktop Entry', 'Icon'):
                icono = cfg.get('Desktop Entry', 'Icon')

            if cfg.has_option('Desktop Entry', 'Exec'):
                ejecutar = cfg.get('Desktop Entry', 'Exec')

                if '%' in ejecutar:
                    # Para programas que el comando a ejecutar termina en %U
                    # por ejemplo, esto hace que el programa reconozca a %U como
                    # un argumento y el programa no se inicialice correctamente

                    t = ''
                    for x in ejecutar:
                        t += x if x != '%' and x != ejecutar[ejecutar.index('%') + 1] else ''

                    ejecutar = t

            if cfg.has_option('Desktop Entry', 'Categories'):
                categoria = cfg.get('Desktop Entry', 'Categories')

            else:
                categoria = ''

            if categoria == '' or 'utility' in categoria.lower():
                _categoria = 'Accesorios'

            if 'accessibility' in categoria.lower():
                _categoria = 'Acceso universal'

            if 'desktopsettings' in categoria.lower() or 'system' in categoria.lower() or 'settings' in categoria.lower():
                _categoria = 'Configuración del sistema'

            if 'science' in categoria.lower():
                _categoria = 'Ciencia'

            if 'education' in categoria.lower():
                _categoria = 'Educación'

            if 'graphics' in categoria.lower():
                _categoria = 'Gráficos'

            if 'network' in categoria.lower():
                _categoria = 'Internet'

            if 'game' in categoria.lower():
                _categoria = 'Juegos'

            if 'office' in categoria.lower():
                _categoria = 'Oficina'

            if 'development' in categoria.lower():
                _categoria = 'Programación'

            if 'audio' in categoria.lower() or 'video' in categoria.lower():
                _categoria = 'Sonido y vídeo'

            if 'wine' in categoria.lower():
                _categoria = 'Wine'

            if nombre and icono and ejecutar and _categoria:
                aplicacion = {
                    'nombre': nombre,
                    'icono': get_icon(icono),
                    'ejecutar': ejecutar,
                    'categoria': _categoria,
                }

                if not _categoria in categorias:
                    categorias[_categoria] = []

                categorias[_categoria].append(aplicacion)

    return categorias


def get_icon(path):

    icon_theme = Gtk.IconTheme()
    pixbuf = icon_theme.load_icon('gtk-file', 48, 0)

    if '/' in path:
        archivo = Gio.File.new_for_path(path)
        info = archivo.query_info('standard::icon', Gio.FileQueryInfoFlags.NOFOLLOW_SYMLINKS, None)
        icono = info.get_icon()
        tipos = icono.get_names()

        if 'image-x-generic' in tipos:
            pixbuf = GdkPixbuf.Pixbuf.new_from_file_at_size(path, 48, 48)

        else:
            if path.endswith('.desktop'):
                cfg = ConfigParser.ConfigParser()
                cfg.read([path])

                if cfg.has_option('Desktop Entry', 'Icon'):
                    if '/' in cfg.get('Desktop Entry', 'Icon'):
                        d = cfg.get('Desktop Entry', 'Icon')
                        pixbuf = GdkPixbuf.Pixbuf.new_from_file_at_size(d, 48, 48)

                    else:
                        pixbuf = icon_theme.load_icon(cfg.get('Desktop Entry', 'Icon'), 48, 0)

                else:
                    pixbuf = icon_theme.load_icon('gtk-file', 48, 0)

            else:
                try:
                    pixbuf = icon_theme.choose_icon(tipos, 48, 0).load_icon()

                except:
                    pixbuf = icon_theme.load_icon('gtk-file', 48, 0)

    else:
        if '.' in path:
            path = path.split('.')[0]

        pixbuf = icon_theme.load_icon(path if icon_theme.has_icon(path) else 'gtk-file', 48, 0)


    return pixbuf


def get_ip():

    ifs = enumerate_interfaces.all_interfaces()
    for x in ifs:
        if x[0] == 'wlan0':
            return enumerate_interfaces.format_ip(x[1])


def clear_string(texto):

    texto = texto.lower()

    if 'á' in texto:
        texto.replace('á', 'a')

    if 'é' in texto:
        texto.replace('é', 'e')

    if 'í' in texto:
        texto.replace('í', 'i')

    if 'ó' in texto:
        texto.replace('ó', 'o')

    if 'ú' in texto:
        texto.replace('ú', 'u')

    return texto


def set_background():

    direccion = os.path.join(os.path.dirname(__file__), 'Lestim.css')
    archivo = open(direccion)
    lista = archivo.read().split('"')
    print lista
    width, height = get_display_dimensions()
    texto = lista[0] + '"' + get_background() + '"' + lista[-1]

    archivo.close()

    archivo = open(direccion, 'w')
    archivo.write(texto)
    archivo.close()

    dicc = get_settings()
    imagen = dicc['fondo-simbolico'] if os.path.exists(dicc['fondo-simbolico']) else os.path.join(os.path.dirname(__file__), 'images/background.jpg')
    width, height = get_display_dimensions()
    img = Image.open(imagen)
    img = img.resize((width, height), Image.ANTIALIAS)

    img.save(background_path)


def get_background():

    return background_path


if not os.path.exists(background_path):
    set_background()
