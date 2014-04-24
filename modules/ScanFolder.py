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

        for _file in _files:
            _file = os.path.join(self.foolder, _file)

            if os.path.isdir(_file):
                directories.append(_file)

            elif os.path.isfile(_file):
                files.append(_file)

        directories.sort()
        files.sort()

        return directories + files
