#!/usr/bin/env python
# -*- ccoding: utf-8 -*-

from gi.repository import Gtk

import Globales as G

from Widgets import WWTB
from Widgets import WorkArea
from Widgets import LateralPanel
from Widgets import DownPanel
from Widgets import AppsView


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

		self.vbox.set_name('CanvasVBox')
		self.hbox.set_name('CanvasHBox')

		self.connect('destroy', Gtk.main_quit)
		self.downpanel.connect('show-apps', self.show_apps)
		self.downpanel.connect('show-lateral-panel', self.show_lateral_panel)
		self.appsview.connect('run-app', self.run_app)

		self.hbox.pack_start(self.workarea, True, True, 0)
		self.hbox.pack_end(self.lateralpanel, False, False, 0)
		self.vbox.pack_start(self.hbox, True, True, 0)
		self.vbox.pack_end(self.downpanel, False, False, 0)

		self.add(self.vbox)
		self.show_all()
		self.lateralpanel.hide()

	def set_principal_widget(self, widget):
		"""
		Está hecho así, para que se puedan usar terminales y cosas por el estilo.
		"""

		self.hbox.remove(self.hbox.get_children()[0])
		self.hbox.pack_start(widget, True, True, 0)
		self.show_all()
		self.lateralpanel.hide()

	def show_apps(self, widget):
		if not self.appsview in self.hbox.get_children():
			self.set_principal_widget(self.appsview)

		else:
			self.set_principal_widget(self.workarea)

	def run_app(self, widget, app):
		self.set_principal_widget(self.workarea)
		G.run_app(app)

	def show_lateral_panel(self, widget, visible):
		if visible:
			self.lateralpanel.show_all()

		else:
			self.lateralpanel.hide()


if __name__ == '__main__':

	Ventana()
	Gtk.main()