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

public class IconView: Gtk.DrawingArea {

    private Gdk.Pixbuf? pixbuf = null;

    public IconView() {
        //this.reload_pixbuf();
        this.draw.connect(this.draw_cb);
    }

    public bool draw_cb(Gtk.Widget self, Cairo.Context ctx) {
        if (this.pixbuf != null) {
            Gdk.cairo_set_source_pixbuf(ctx, this.pixbuf, 0, 0);
            ctx.paint();
        }

        return true;
    }

    public void reload_background() {
        this.reload_pixbuf();
        this.queue_draw();
    }

    private void reload_pixbuf() {
        try {
            this.pixbuf = new Gdk.Pixbuf.from_file_at_size(get_background_path(), DISPLAY_WIDTH, DISPLAY_HEIGHT);
            if (this.pixbuf.get_width() != DISPLAY_WIDTH || this.pixbuf.get_height() != DISPLAY_WIDTH) {
                this.pixbuf = this.pixbuf.scale_simple(DISPLAY_WIDTH, DISPLAY_HEIGHT, Gdk.InterpType.HYPER);
            }
        } catch (GLib.Error e) {
            this.pixbuf = null;
        }
    }
}

public class BackgroundWindow: Gtk.Window {

    public IconView icon_view;

    public BackgroundWindow() {
        this.set_title("Background");
        this.set_name("BackgroundWindow");
        this.set_type_hint(Gdk.WindowTypeHint.DESKTOP);
        this.set_size_request(DISPLAY_WIDTH, DISPLAY_HEIGHT);
        this.move(0, 0);

        this.icon_view = new IconView();
        this.add(this.icon_view);

        this.icon_view.reload_background();

        this.show_all();
    }

    public void set_background(string path) {
        GLib.File file1 = GLib.File.new_for_path(get_background_path());
	    GLib.File file2 = GLib.File.new_for_path(path);

        try {
            file2.copy(file1, GLib.FileCopyFlags.OVERWRITE);
            this.icon_view.reload_background();
        } catch (GLib.Error e) {
            GLib.warning("Can not copy file %s to %s and set to background. Aborting.", file2.get_path(), file1.get_path());
        }
    }
}

