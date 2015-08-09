/*
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

class LestimApp: Gtk.Application {

    public LestimWindow background;
    public GLib.Settings gsettings;

    public LestimApp() {
        GLib.Object(application_id: "org.lestim");
    }

    protected override void activate() {
        set_display_size();
        check_paths();

        this.background = new LestimWindow();
        this.background.set_application(this);
        this.background.show();

        set_theme();
    }
}

int main (string[] args) {
    return new LestimApp().run(args);
}
