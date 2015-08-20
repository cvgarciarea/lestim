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

public class WallpaperWindow: Gtk.Window {

    public IconView icon_view;

    public WallpaperWindow() {
        this.set_title("Wallpaper");
        this.set_name("WallpaperWindow");
        this.set_type_hint(Gdk.WindowTypeHint.DESKTOP);
        this.set_size_request(DISPLAY_WIDTH, DISPLAY_HEIGHT);
        this.move(0, 0);

        this.icon_view = new IconView();
        this.add(this.icon_view);

        this.icon_view.reload_background();
    }

    public void set_wallpaper(SettingsWindow win, string path) {
        GLib.File file1 = GLib.File.new_for_path(get_background_path());

	    GLib.File file2 = GLib.File.new_for_path(path);
	    file2.copy(file1, GLib.FileCopyFlags.OVERWRITE);

        this.icon_view.reload_background();
    }
}

