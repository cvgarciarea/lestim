#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# ScanFolder.py por:
#    Cristian García: cristian99garcia@gmail.com

import os

from gi.repository import GObject


class ScanFolder(GObject.GObject):

    __gsignals__ = {
        'files-changed': (GObject.SIGNAL_RUN_FIRST, None, [object]),
        'realized-searching': (GObject.SIGNAL_RUN_FIRST, None, []),
        }

    def __init__(self, foolder):

        GObject.GObject.__init__(self)

        self.foolder = foolder
        self.files = []
        self.show_hidden_files = False

        GObject.timeout_add(1000, self.scan)

    def scan(self):
        files = []
        directories = []

        if self.files != self.get_files():
            self.files = self.get_files()

            self.emit('files-changed', self.files)

        self.emit('realized-searching')

        return True

    def get_files(self):
        directories = []
        files = []
        _files = os.listdir(self.foolder)

        for name in _files:
            filename = os.path.join(self.foolder, name)

            if (not name.startswith('.') and not name.endswith('~')) or self.show_hidden_files:
                if os.path.isdir(filename):
                    directories.append(filename)

                elif os.path.isfile(filename):
                    files.append(filename)

        directories.sort()
        files.sort()

        return directories + files

    def set_show_hidden_files(self, if_show):
        if type(if_show) != bool:
            raise TypeError('The parameter must to be a bool')

        self.show_hidden_files = if_show
