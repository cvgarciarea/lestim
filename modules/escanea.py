#!/usr/bin/python
# -*- coding: utf-8 -*-
# Project:     wifi-ltsp
# Module:     escanea.py
# Purpose:     Busca el canal libre más adecuado para la wifi
# Language:    Python 2.5
# Date:        03-Feb-2011.
# Ver:        07-Feb-2011.
# Author:    Francisco Mora Sánchez
# Copyright:   2011 - Francisco Mora Sánchez   <adminies.maestrojuancalero@edu.juntaextremadura.net>
#
# wifi-ltsp is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# Script2 is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
# You should have received a copy of the GNU General Public License
# along with wifi-ltsp. If not, see <http://www.gnu.org/licenses/>.


"""Módulo auxiliar para obtener información a través
del comando iwlist, perteneciente a las herramientas
wireless-tools

Francisco Mora Sánchez
IES Maestro Juan Calero
adminies.maestrojuancalero@edu.juntaextremadura.net


"""

import os
import re
import locale
from subprocess import Popen, STDOUT, PIPE, call

# Expresiones Regulares.
_re_mode = (re.I | re.M | re.S)
essid_pattern = re.compile('.*ESSID:"?(.*?)"?\s*\n', _re_mode)
ap_mac_pattern = re.compile('.*Address: (.*?)\n', _re_mode)
channel_pattern = re.compile('.*Channel:?=? ?(\d\d?)', _re_mode)
strength_pattern = re.compile('.*Quality:?=? ?(\d+)\s*/?\s*(\d*)', _re_mode)
altstrength_pattern = re.compile('.*Signal level:?=? ?(\d+)\s*/?\s*(\d*)', _re_mode)
signaldbm_pattern = re.compile('.*Signal level:?=? ?(-\d\d*)', _re_mode)
freq_pattern = re.compile('.*Frequency:(.*?)\n', _re_mode)

def to_unicode(x):
    """ Convierte una cadena a codificación utf-8. """
    # Si ésta es una cadena unicode, la codifica y la devuelve
    if not isinstance(x, basestring):
        return x
    if isinstance(x, unicode):
        return x.encode('utf-8')
    encoding = locale.getpreferredencoding()
    try:
        ret = x.decode(encoding).encode('utf-8')
    except UnicodeError:
        try:
            ret = x.decode('utf-8').encode('utf-8')
        except UnicodeError:
            try:
                ret = x.decode('latin-1').encode('utf-8')
            except UnicodeError:
                ret = x.decode('utf-8', 'replace').encode('utf-8')
            
    return ret

def EjecutaRegex(regex, cadena):
    """ ejecuta búsqueda de expresión regular en una cadena """
    m = regex.search(cadena)
    if m:
        return m.groups()[0]
    else:
        return None

def Ejecuta(comando, include_stderr=False, return_pipe=False,
        return_obj=False, return_retcode=True):
    """ Ejecuta un comando.

    Ejecuta el comando dado, retornando la salida del programa
    o un pipe para leer la salida.

    argumentos --
    comando - Comando a ejecutar
    include_std_err - Boleano, especifica si la salida de error debe
					ser incluida en el pipe.
    return_pipe - Boleano, especifica si el pipe del comando se
					devuelve. Si es False, todo lo que devolverá
					es la cadena de salida del comando.
    return_obj - Si True, Ejecuta devolverá el objeto Popen
					para el comando que se ha ejecutado.

    """
    if not isinstance(comando, list):
        comando = to_unicode(str(comando))
        comando = comando.split()
    if include_stderr:
        err = STDOUT
        fds = True
    else:
        err = None
        fds = False
    if return_obj:
        std_in = PIPE
    else:
        std_in = None
    
    # Debemos asegurarnos que los resultados del comando ejecutado
    # están en inglés, así ajustaremos un entorno temporal.
    tmpenv = os.environ.copy()
    tmpenv["LC_ALL"] = "C"
    tmpenv["LANG"] = "C"
    
    try:
        f = Popen(comando, shell=False, stdout=PIPE, stdin=std_in, stderr=err,
                  close_fds=fds, cwd='/', env=tmpenv)
    except OSError, e:
        print "Fallo ejecuando comando %s : %s" % (str(comando), str(e))
        return ""
        
    if return_obj:
        return f
    if return_pipe:
        return f.stdout
    else:
        return f.communicate()[0]

def FrecuenciaACanal(frecuencia):
	""" Transforma una frecuencia a canal.
	
		Nota: Esta función es una búsqueda en diccionario, por lo que
		la frecuencia debe estar en el diccionario para que pueda
		devolverse un canal válido.
		
        Parámetros:
        frecuencia -- cadena conteniendo la frecuencia
        
        Devuelve:
        El número de canal, o None si no se encuentra.
	"""
	ret = None
	freq_dict = {'2.412 GHz': 1, '2.417 GHz': 2, '2.422 GHz': 3,
		'2.427 GHz': 4, '2.432 GHz': 5, '2.437 GHz': 6,
		'2.442 GHz': 7, '2.447 GHz': 8, '2.452 GHz': 9,
		'2.457 GHz': 10, '2.462 GHz': 11, '2.467 GHz': 12,
		'2.472 GHz': 13, '2.484 GHz': 14 }
	try:
		ret = freq_dict[frecuencia]
	except KeyError:
		print "No se puede determinar el canal para la frecuencia: " + str(frecuencia)
	return ret

def get_link_quality(red):
	""" Obtiene la calidad del enlace desde la salida iwlist.
	"""
	try:
		[(strength, max_strength)] = strength_pattern.findall(red)
	except ValueError:
		(strength, max_strength) = (None, None)
	if strength in ['', None]:
		try:
			[(strength, max_strength)] = altstrength_pattern.findall(red)
		except ValueError:
			# Si el patrón no encuentra coincidencias
			# retornamos 101
			return 101
	if strength not in ['', None] and max_strength:
		#print "strength,max",strength,max_strength
		return (100 * int(strength) // int(max_strength))
	elif strength not in ["", None]:
		#print "strength,max",strength,max_strength
		return int(strength)
	else:
		#print "strength,max",strength,max_strength
		return None
    
def ParseAccessPoint(red):
	""" Examina una red wifi desde la salida de iwlist.
		Parámetros:
		red -- cadena que contiene la identificación de la red.
		Devuelve:
		Un diccionario que contiene las propiedades de la red wifi
		examinada.
	"""
	ap = {}
	ap['essid'] = EjecutaRegex(essid_pattern, red)
	try:
		ap['essid'] = to_unicode(ap['essid'])
	except (UnicodeDecodeError, UnicodeEncodeError):
		print 'Problema Unicode con el essid de la red actual, ignorando!!'
		return None
	if ap['essid'] in ['Hidden', '<hidden>', "", None]:
		print 'hidden'
		ap['oculta'] = True
		ap['essid'] = "<hidden>"
	else:
		ap['oculta'] = False
	# Canal - Para interfaces que no tienen un número de canal,
	# convertir la frecuencia.
	ap['canal'] = EjecutaRegex(channel_pattern, red)
	if ap['canal'] == None:
		freq = EjecutaRegex(freq_pattern, red)
		ap['canal'] = FrecuenciaACanal(freq)
	# BSSID
	ap['bssid'] = EjecutaRegex(ap_mac_pattern, red)
	# Calidad del enlace
	# Ajusta strength a -1 si no se encuentra calidad
	ap['calidad'] = get_link_quality(red)
	if ap['calidad'] is None:
		ap['calidad'] = -1
	# Signal Strength (only used if user doesn't want link
	# quality displayed or it isn't found)
	if EjecutaRegex(signaldbm_pattern, red):
		ap['intensidad'] = EjecutaRegex(signaldbm_pattern, red)
	return ap

def getWirelessInterfaces():
    """ Extract wireless device names from /proc/net/wireless.

        Returns empty list if no devices are present.

        >>> getWirelessInterfaces()
        ['', 'wifi0']

    """
    device = re.compile('[a-z]{2,}[0-9]*:')
    ifnames = []

    fp = open('/proc/net/wireless', 'r')
    for line in fp:
        try:
            # append matching pattern, without the trailing colon
            ifnames.append(device.search(line).group()[:-1])
        except AttributeError:
            pass

    return ifnames

def ObtieneRedes(interface):
	""" Obtiene una lista de redes wifi disponibles. La usamos para 
		obtener via iwlist datos de las redes disponibles. De momento
		lo usamos para obtener los valores del calidad e intensidad,
		ya que la librería pythonwifi no parece dar los valores correctos
		de estos parámetros.
	
		Parámetros:
		interface -- Interfaz sobre la que escanear
		Devuelve:
		Diccionario cuyas claves son ls bssids y cada elemento
		es otro diccionario cuyas claves con las características
		recogidas por iwlist
	"""
    
    #Si hostapd está corriendo iwlist scan no funciona:
	Popen(["invoke-rc.d","hostapd","stop"]).wait()
	Popen(["ifconfig",interface,"up"]).wait()
    
	cmd = 'iwlist ' + interface + ' scan'
	resultado = Ejecuta(cmd)
	# Divide las redes, utilizando Cell como punto de división
	# de esta forma podemos mirar una red cada vez.
	# Los espacios alrededor de '   Cell ' son para evitar el caso
	# de que alguien tenga un essid llamado Cell...
	redes = resultado.split( '   Cell ' )
	# An array for the access points
	access_points = []
	access_points = {}
	for red in redes:
		# Solo usa secciones donde haya un ESSID.
		if 'ESSID:' in red:
			# Añadir la red a la lista de redes
			entry = ParseAccessPoint(red)
			if entry is not None:
				# Normalmente solo tenemos bssids duplicados con redes
				# ocultas.  Solo nos fijamos en el essid real, para
				# que esté en la lista.
				if (entry['bssid'] not in access_points or not entry['oculta']):
					access_points[entry['bssid']] = entry
	return access_points

if __name__ == "__main__":
	datos_redes = ObtieneRedes('wlan0')
	print datos_redes
