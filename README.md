Lestim
======

##Test vala version:
**Copy xml file and install schema:**
```
# cp data/org.lestim.dock.gschema.xml /usr/share/glib-2.0/schemas/
# cp data/org.lestim.panel.gschema.xml /usr/share/glib-2.0/schemas/
# glib-compile-schemas /usr/share/glib-2.0/schemas/
```

**Compile and run:**
```
make
./lestim
```

##Task list
- [x] Resize background size to screen size
- [ ] Fix the style for themes with dark leter
- [ ] Make installable
- [ ] Add functionality to the lateral panel
  - [ ] Calendar
  - [ ] System tray icons
  - [ ] Sound GtkScale
  - [ ] Brightness GtkScale
  - [ ] Add system notifications
  - [ ] Down buttons
    - [ ] Power off
    - [ ] Reboot
    - [ ] Log out
    - [x] Preferences
- [ ] Add Wnck functionality(manage applications windows)
- [ ] Save log in a file
- [ ] Add option transparency to the dock

*Dependencies:*

 * GTK+ >= 3.14
 * gdk 3.0
 * libwnck 3.0
 * gee 0.8
 * gdk-pixbuf-2.0
 * libgnome-menu
 * gio-unix 2.0

**Author**
 * Cristian García <cristian99garcia@gmail.com>
