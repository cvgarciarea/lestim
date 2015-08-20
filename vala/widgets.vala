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

public class AppButton: Gtk.Button {

    public GLib.DesktopAppInfo app_info;
    public Gtk.Box vbox;

    public AppButton(GLib.DesktopAppInfo app_info, bool show_label=false) {
        this.app_info = app_info;

        this.set_name("AppButton");
        this.set_tooltip_text(app_info.get_description());
        this.set_hexpand(false);
        this.set_vexpand(false);
        this.set_can_focus(true);

        Gtk.drag_source_set(
            this,
            Gdk.ModifierType.BUTTON1_MASK,
            app_button_target_list,
            Gdk.DragAction.COPY
        );

        this.vbox = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        this.vbox.set_hexpand(false);
        this.add(this.vbox);

        if (show_label) {
            this.vbox.pack_end(new Gtk.Label(this.app_info.get_name()), false, false, 2);
        }

        int icon_size = 64;  // get from settings;

        string name = app_info.get_icon().to_string();
        var image = get_image_from_name(name, icon_size);
        var pixbuf = image.get_pixbuf();

        if (pixbuf == null) {
            pixbuf = get_image_from_name("application-x-executable-symbolic", icon_size).get_pixbuf();
        }

        if (pixbuf.get_width() != icon_size || pixbuf.get_height() != icon_size) {
            pixbuf = pixbuf.scale_simple(icon_size, icon_size, Gdk.InterpType.BILINEAR);
        }

        this.vbox.pack_start(new Gtk.Image.from_pixbuf(pixbuf), false, false, 0);
    }
}

