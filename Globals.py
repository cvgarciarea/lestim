#!/usr/bin/env python
# -*- coding: utf-8 -*-

#  Globals.py por:
#     Cristian García: cristian99garcia@gmail.com

import os
import alsaaudio
import ConfigParser
import thread
import commands

try:
    import Image

except ImportError:
    from PIL import Image

#from modules import enumerate_interfaces
#from modules import escanea

from gi.repository import GdkPixbuf
from gi.repository import Gio
from gi.repository import Gtk
from gi.repository import Gdk


mixer = alsaaudio.Mixer()
background_path = os.path.expanduser('~/.lestim/background.jpg')
main_window_icon = os.path.join(os.path.dirname(__file__), 'images/logo.svg')
screen = Gdk.Screen.get_default()
width = screen.width()
height = screen.height()
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
backgrounds_path = os.path.join(settings_dir, 'backgrounds')
theme_path = os.path.join(settings_dir, 'Lestim.css')
#theme_path = os.path.join(os.path.dirname(__file__), 'Lestim.css')

if not os.path.isdir(settings_dir):
    os.makedirs(settings_dir)

if not os.path.isdir(backgrounds_path):
    os.makedirs(backgrounds_path)

if not os.path.isfile(settings_path):
    archivo = open(settings_path, 'w')
    configuracion = '''{
    "fondo-simbolico": "%s",
    "panel-siempre-visible": False,
    "aplicaciones-favoritas": [],
    "gestion-del-escritorio": True,
}''' % os.path.join(os.path.dirname(__file__), 'images/background.jpg')

    configuracion = configuracion.encode('utf-8')
    archivo.write(configuracion)
    archivo.close()

if not os.path.isfile(theme_path):
    archivo = open(os.path.join(os.path.dirname(__file__), 'Lestim.css'))
    texto = archivo.read()
    texto = texto.replace('""', '"%s"' % background_path)

    archivo.close()

    archivo = open(theme_path, 'w')
    archivo.write(texto)
    archivo.close()


css_provider = Gtk.CssProvider()
context = Gtk.StyleContext()


ICONVIEW_TEXT_COLUMN = 0
ICONVIEW_PIXBUF_COLUMN = 1


def get_settings():

    configuracion = eval(open(settings_path).read())

    return configuracion


def set_settings(diccionario):

    def save_settings(diccionario):

        archivo = open(settings_path, 'w')
        archivo.write(str(diccionario))
        archivo.close()

        set_background()

    thread.start_new_thread(save_settings, (diccionario,))


def get_display_dimensions():

    return width, height


def get_user_directories():

    direccion = os.path.expanduser('~/.config/user-dirs.dirs')
    usuario = os.path.expanduser('~/')
    escritorio = None
    descargas = None
    documentos = None
    imagenes = None
    musica = None
    videos = None
    papelera = None

    if os.path.isfile(direccion):
        texto = open(direccion).read()

        for linea in texto.splitlines():
            if linea.startswith('XDG_DESKTOP_DIR='):
                escritorio = commands.getoutput('echo %s' % linea.split('"')[1])

            elif linea.startswith('XDG_DOWNLOAD_DIR='):
                descargas = commands.getoutput('echo %s' % linea.split('"')[1])

            elif linea.startswith('XDG_DOCUMENTS_DIR='):
                documentos = commands.getoutput('echo %s' % linea.split('"')[1])

            elif linea.startswith('XDG_MUSIC_DIR='):
                musica = commands.getoutput('echo %s' % linea.split('"')[1])

            elif linea.startswith('XDG_PICTURES_DIR='):
                imagenes = commands.getoutput('echo %s' % linea.split('"')[1])

            elif linea.startswith('XDG_VIDEOS_DIR='):
                videos = commands.getoutput('echo %s' % linea.split('"')[1])

    return {
        'usuario': usuario,
        'escritorio': escritorio,
        'descargas': descargas,
        'documentos': documentos,
        'imagenes': imagenes,
        'musica': musica,
        'videos': videos,
        'papelera': papelera,
    }

def get_desktop_directory():

    return get_user_directories()['escritorio']


def get_backgrounds():

    fondos = {'fondos': [], 'imagenes': [], 'colores': []}
    directorio = get_user_directories()['imagenes']

    for x in os.listdir(directorio):
        archivo = os.path.join(directorio, x)
        if ' ' in archivo:
            _archivo = archivo.replace(' ', '\ ')

        else:
            _archivo = archivo

        if os.path.isfile(archivo) and 'image' in commands.getoutput('file --mime-type %s' % _archivo).split(' ')[-1]:
            fondos['imagenes'].append(archivo)

    for x in os.listdir(backgrounds_path):
        archivo = os.path.join(backgrounds_path, x)

        if ' ' in archivo:
            archivo = archivo.replace(' ', '\ ')

        if os.path.isfile(archivo) and \
           'image' in commands.getoutput('file --mime-type %s' % archivo).split(' ')[-1]:

            fondos['fondos'].append(archivo)

    fondos['fondos'].sort()
    fondos['imagenes'].sort()

    return fondos


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
                    # por ejemplo, esto hace que el programa reconozca a %U
                    # como un argumento y el programa no se inicialice
                    # correctamente

                    t = ''
                    for x in ejecutar:
                        t += x if x != '%' and x != ejecutar[ejecutar.index('%') + 1] \
                                       else ''

                    ejecutar = t

            if cfg.has_option('Desktop Entry', 'Categories'):
                categoria = cfg.get('Desktop Entry', 'Categories')

            else:
                categoria = ''

            if categoria == '' or 'utility' in categoria.lower():
                _categoria = 'Accesorios'

            if 'accessibility' in categoria.lower():
                _categoria = 'Acceso universal'

            if 'desktopsettings' in categoria.lower() or 'system' in categoria.lower() \
                    or 'settings' in categoria.lower():

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
                    'icono-str': icono,
                    'icono': get_icon(icono),
                    'ejecutar': ejecutar,
                    'categoria': _categoria,
                }

                if _categoria not in categorias:
                    categorias[_categoria] = []

                categorias[_categoria].append(aplicacion)

    return categorias


def get_icon(path):

    icon_theme = Gtk.IconTheme()
    pixbuf = icon_theme.load_icon('gtk-file', 48, 0)

    if '/' in path:
        archivo = Gio.File.new_for_path(path)
        info = archivo.query_info('standard::icon',
                                  Gio.FileQueryInfoFlags.NOFOLLOW_SYMLINKS,
                                  None)
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
                        pixbuf = GdkPixbuf.Pixbuf.new_from_file_at_size(
                            d, 48, 48)

                    else:
                        pixbuf = icon_theme.load_icon(cfg.get('Desktop Entry',
                                                              'Icon'), 48, 0)

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

        pixbuf = icon_theme.load_icon(path if icon_theme.has_icon(path)
                                           else 'gtk-file', 48, 0)

    return pixbuf


"""
def get_ip():

    ifs = enumerate_interfaces.all_interfaces()
    for x in ifs:
        if x[0] == 'wlan0':
            return enumerate_interfaces.format_ip(x[1])
"""


def clear_string(texto):

    texto = texto.lower()

    if 'á' in texto:
        texto = texto.replace('á', 'a')

    if 'é' in texto:
        texto = texto.replace('é', 'e')

    if 'í' in texto:
        texto = texto.replace('í', 'i')

    if 'ó' in texto:
        texto = texto.replace('ó', 'o')

    if 'ú' in texto:
        texto = texto.replace('ú', 'u')

    return texto


def get_background():

    return background_path


def set_background(background=get_background()):

    archivo = open(theme_path)
    lista = archivo.read().split('"')
    width, height = get_display_dimensions()
    texto = lista[0] + '"' + background + '"' + lista[-1]

    archivo.close()

    archivo = open(theme_path, 'w')
    archivo.write(texto)
    archivo.close()

    dicc = get_settings()
    imagen = dicc['fondo-simbolico'] \
        if os.path.isfile(dicc['fondo-simbolico']) \
        else os.path.join(os.path.dirname(__file__), 'images/background.jpg')

    width, height = get_display_dimensions()
    img = Image.open(imagen)
    img = img.resize((width, height), Image.ANTIALIAS)

    img.save(background_path)


def set_theme():

    context.remove_provider_for_screen(
        screen,
        css_provider,
    )

    css_provider.load_from_path(theme_path)

    context.add_provider_for_screen(
        screen,
        css_provider,
        Gtk.STYLE_PROVIDER_PRIORITY_USER
    )


def open_file(direccion):

    if not direccion.endswith('.desktop'):
        if ' ' in direccion:
            direccion = direccion.replace(' ', '\ ')

        os.system('xdg-open %s' % direccion)

    else:
        cfg = ConfigParser.ConfigParser()
        cfg.read([direccion])

        if cfg.has_option('Desktop Entry', 'Exec'):
            os.system(cfg.has_option('Desktop Entry', 'Exec'))


if not os.path.exists(background_path):
    set_background()
