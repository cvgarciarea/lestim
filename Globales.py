#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
import time
import thread
import subprocess
import ConfigParser

from gi.repository import Gtk
from gi.repository import Gdk
from gi.repository import Gio
from gi.repository import GdkPixbuf

try:
    import Image

except ImportError:
    from PIL import Image

os.system('cp /home/cristian/Documentos/Desktop/Desktop.css /home/cristian/.desktop/Desktop.css')
t = open('/home/cristian/.desktop/Desktop.css').read()
f = open('/home/cristian/.desktop/Desktop.css', 'w')
f.write(t.replace('""', '"/home/cristian/.desktop/background.jpg"'))
f.close()

screen = Gdk.Screen.get_default()
css_provider = Gtk.CssProvider()
context = Gtk.StyleContext()


class Sizes:
    DISPLAY_WITH = screen.width()
    DISPLAY_HEIGHT = screen.height() - 20
    DISPLAY_SIZE = (DISPLAY_WITH, DISPLAY_HEIGHT)


class Paths:
    WORK_DIR = os.path.expanduser('~/.desktop/')
    SETTINGS_PATH = os.path.expanduser('~/.desktop/settings.json')
    THEME_PATH = os.path.join(WORK_DIR, 'Desktop.css')
    LOCAL_THEME_PATH = os.path.join(os.path.dirname(__file__), 'Desktop.css')
    BACKGROUND_PATH = os.path.expanduser('~/.desktop/background.jpg')
    LOCAL_BACKGROUND_PATH = os.path.join(os.path.dirname(__file__), 'backgrounds/colorful.jpg')
    BACKGROUNDS_DIR = os.path.join(WORK_DIR, 'backgrounds')
    LOCAL_BACKGROUNDS_DIR = os.path.join(os.path.dirname(__file__), 'backgrounds')
    APPS_DIR = '/usr/share/applications'


def get_settings():

    confi = eval(open(Paths.SETTINGS_PATH).read())
    #confi['tamano-de-los-iconos'] = int(confi['tamano-de-los-iconos'])
    #confi['gestion-del-escritorio'] = bool(confi['gestion-del-escritorio'])
    #confi['panel-siempre-visible'] = bool(confi['panel-siempre-visible'])
    confi['aplicaciones-favoritas'] = eval(str(confi['aplicaciones-favoritas']))

    return confi


def get_actual_volume():
    proc = subprocess.Popen('/usr/bin/amixer sget Master', shell=True, stdout=subprocess.PIPE)
    amixer_stdout = proc.communicate()[0].split('\n')[4]
    proc.wait()

    find_start = amixer_stdout.find('[') + 1
    find_end = amixer_stdout.find('%]', find_start)

    return int(amixer_stdout[find_start:find_end])


def get_actual_brightness():
    valor = subprocess.check_output("xrandr --verbose | grep -i brightness | cut -f2 -d ' '", shell=True)
    if(valor != ""):
        valor = valor.split('\n')[0]
        valor = int(float(valor) * 100)
    else:
        valor = ""
    return valor


def set_brightness(valor):
    monitor = subprocess.check_output("xrandr -q | grep ' connected' | cut -d ' ' -f1", shell=True)
    if(monitor != ""):
        monitor = monitor.split('\n')[0]

    if valor >= 2:
        valor /= 100.0

    cmdStatus = subprocess.check_output("xrandr --output %s --brightness %.2f" % (monitor, valor), shell=True)


def set_settings(dicc):
    def save_settings(dicc):
        """
        texto = '{\n'

        for x in dicc:
            if type(x) in [str, int]:
                texto += '    "%s": "%s",' % (x, str(dicc[x])) + '\n'

            else:
                texto += '    "%s": [\n' % x

                for i in x:
                    texto += '        %s,\n' % i

                texto += '    ],'

        texto += '}'
        texto = texto.replace('"False"', '""')
        texto = texto.replace('"True"', '"True"')

        archivo = open(settings_path, 'w')
        archivo.write(texto)
        archivo.close()
        """
        texto = str({'aplicaciones-favoritas': dicc['aplicaciones-favoritas']})
        archivo = open(Paths.SETTINGS_PATH, 'w')
        archivo.write(texto)
        archivo.close()
        set_background()

    thread.start_new_thread(save_settings, (dicc,))


def set_background(background=Paths.BACKGROUND_PATH):
    archivo = open(Paths.LOCAL_THEME_PATH)
    lista = archivo.read().split('"')
    width, height = Sizes.DISPLAY_SIZE
    texto = lista[0] + '"' + background + '"' + lista[-1]

    archivo.close()

    archivo = open(Paths.THEME_PATH, 'w')
    archivo.write(texto)
    archivo.close()

    dicc = get_settings()
    width, height = Sizes.DISPLAY_SIZE
    img = Image.open(Paths.LOCAL_BACKGROUND_PATH)
    img = img.resize((width, height), Image.ANTIALIAS)

    img.save(Paths.BACKGROUND_PATH)


def set_theme():
    context.remove_provider_for_screen(screen, css_provider,)
    css_provider.load_from_path(Paths.THEME_PATH)
    context.add_provider_for_screen(
        screen,
        css_provider,
        Gtk.STYLE_PROVIDER_PRIORITY_USER
    )


def get_time():
    tiempo = time.gmtime()
    texto = '%d/%d/%d  %d:%d:%d' % (tiempo[2], tiempo[1], tiempo[1], tiempo[3], tiempo[4], tiempo[5])
    if len(texto.split(':')[-1]) == 1:
        texto = texto[:-1] + '0%d' % tiempo[5]

    return texto


def get_app(archivo):

    categorias = {}
    icon_theme = Gtk.IconTheme()
    aplicacion = None

    if archivo.endswith('.desktop'):
        archivo = os.path.join(Paths.APPS_DIR, archivo)
        cfg = ConfigParser.ConfigParser()
        nombre = None
        icono = None
        ejecutar = None

        cfg.read([archivo])

        if cfg.has_option('Desktop Entry', 'Name'):
            nombre = cfg.get('Desktop Entry', 'Name')

        if cfg.has_option('Desktop Entry', 'Name[es]'):
            nombre = cfg.get('Desktop Entry', 'Name[es]')

        if cfg.has_option('Desktop Entry', 'Icon'):
            icono = cfg.get('Desktop Entry', 'Icon')

        else:
            icono = 'text-x-preview'

        if cfg.has_option('Desktop Entry', 'Exec'):
            ejecutar = cfg.get('Desktop Entry', 'Exec')

            if '%' in ejecutar:
                # Para programas que el comando a ejecutar termina en %U
                # por ejemplo, esto hace que el programa reconozca a %U
                # como un argumento y el programa no se inicialice
                # correctamente

                t = ''
                for x in ejecutar:
                    t += x if x != '%' and x != ejecutar[ejecutar.index('%') + 1] else ''

                ejecutar = t

        if nombre and ejecutar:
            aplicacion = {
                'nombre': nombre,
                'icono': icono,
                'ejecutar': ejecutar,
            }

    return aplicacion


def get_icon(path, size=32):

    icon_theme = Gtk.IconTheme()
    pixbuf = icon_theme.load_icon('gtk-file', size, 0)

    if '/' in path:
        archivo = Gio.File.new_for_path(path)
        info = archivo.query_info('standard::icon',
                                  Gio.FileQueryInfoFlags.NOFOLLOW_SYMLINKS,
                                  None)
        icono = info.get_icon()
        tipos = icono.get_names()

        if 'image-x-generic' in tipos:
            pixbuf = GdkPixbuf.Pixbuf.new_from_file_at_size(path, size, size)

        else:
            if path.endswith('.desktop'):
                cfg = ConfigParser.ConfigParser()
                cfg.read([path])

                if cfg.has_option('Desktop Entry', 'Icon'):
                    if '/' in cfg.get('Desktop Entry', 'Icon'):
                        d = cfg.get('Desktop Entry', 'Icon')
                        pixbuf = GdkPixbuf.Pixbuf.new_from_file_at_size(
                            d, size, size)

                    else:
                        pixbuf = icon_theme.load_icon(cfg.get('Desktop Entry',
                                                              'Icon'), size, 0)

                else:
                    pixbuf = icon_theme.load_icon('gtk-file', size, 0)

            else:
                try:
                    pixbuf = icon_theme.choose_icon(tipos, size, 0).load_icon()

                except:
                    pixbuf = icon_theme.load_icon('gtk-file', size, 0)

    else:
        if '.' in path:
            path = path.split('.')[0]

        pixbuf = icon_theme.load_icon(path if icon_theme.has_icon(path)
                                           else 'gtk-file', size, 0)

    return pixbuf


def run_app(app):
    def run(app):
        print app['ejecutar']
        os.system(app['ejecutar'])

    thread.start_new_thread(run, (app,))


if not os.path.isdir(Paths.WORK_DIR):
    os.makedirs(Paths.WORK_DIR)

if not os.path.isdir(Paths.BACKGROUNDS_DIR):
    os.makedirs(Paths.BACKGROUNDS_DIR)

if not os.path.isfile(Paths.SETTINGS_PATH):
    diccionario = {
    "fondo-simbolico": Paths.LOCAL_BACKGROUND_PATH,
    #"panel-siempre-visible": False,
    "aplicaciones-favoritas": [],
    #"gestion-del-escritorio": True,
    #"tamano-de-los-iconos": 64
    }

    set_settings(diccionario)

if not os.path.isfile(Paths.THEME_PATH):
    archivo = open(Paths.LOCAL_THEME_PATH)
    texto = archivo.read()
    texto = texto.replace('""', '"%s"' % Paths.BACKGROUND_PATH)

    archivo.close()

    archivo = open(Paths.THEME_PATH, 'w')
    archivo.write(texto)
    archivo.close()


if not os.path.exists(Paths.BACKGROUND_PATH):
    set_background()