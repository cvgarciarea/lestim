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

    private Gdk.Pixbuf pixbuf;

    public IconView() {
        this.reload_pixbuf();
        this.draw.connect(this.draw_cb);
    }

    public bool draw_cb(Gtk.Widget self, Cairo.Context ctx) {
        Gdk.cairo_set_source_pixbuf(ctx, this.pixbuf, 0, 0);
        ctx.paint();
        return true;
    }

    public void reload_background() {
        this.reload_pixbuf();
        this.queue_draw();
    }

    private void reload_pixbuf() {
        this.pixbuf = new Gdk.Pixbuf.from_file_at_size(get_background_path(), DISPLAY_WIDTH, DISPLAY_HEIGHT);
    }
}
