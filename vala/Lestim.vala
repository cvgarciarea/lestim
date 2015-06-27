/*
Compile with:
    valac --pkg gtk+-3.0 --pkg gdk-3.0 --pkg libwnck-3.0 --pkg json-glib-1.0 --pkg gee-1.0 --pkg gdk-pixbuf-2.0 --pkg libgnome-menu --pkg gio-unix-2.0 -X -lm Lestim.vala globals.vala panel.vala widgets.vala lateral_panel.vala settings_window.vala apps_view.vala -X "-DGMENU_I_KNOW_THIS_IS_UNSTABLE"

Copyright (C) 2015, Cristian García <cristian99garcia@gmail.com>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
*/

using Gtk;

class LestimApp: Gtk.Application {
    public LestimWindow window;

    protected override void activate() {
        set_display_size();
        check_paths();

        window = new LestimWindow();
        window.set_application(this);
        window.show();
        set_theme();
  }

    public LestimApp() {
        Object(application_id: "org.lestim.session");
  }
}

int main (string[] args) {
    return new LestimApp().run(args);
}
