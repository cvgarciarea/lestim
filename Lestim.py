#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# Copyright (C) 2015, Cristian García <cristian99garcia@gmail.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

from gi.repository import Gtk
from gi.repository import Gio
from gi.repository import GLib
from gi.repository import GObject

from widgets import LestimWindow


class LestimApp(Gtk.Application):

    def __init__(self):
        Gtk.Application.__init__(self, application_id='org.lestim.lestim-session', flags=Gio.ApplicationFlags.FLAGS_NONE)

        GLib.set_application_name('lestim')
        GLib.set_prgname('lestim')

        self.set_flags(Gio.ApplicationFlags.HANDLES_OPEN)
        self.add_main_option('debug', b'd', GLib.OptionFlags.NONE, GLib.OptionArg.NONE, 'Debug lestim', None)

        self.connect('activate', self.__activate_cb)

    def __activate_cb(self, app):
        self._win = LestimWindow(self)
        self._win.show_all()


if __name__ == '__main__':
    lestim = LestimApp()
    lestim.run()

