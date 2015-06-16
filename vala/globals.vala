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

public int DISPLAY_WIDTH = 1366;
public int DISPLAY_HEIGHT = 768;

public string get_home_dir() {
    return GLib.Environment.get_home_dir();
}

public string get_desktop_dir() {
    return GLib.Environment.get_variable("XDG_DESKTOP_DIR");
}

public string get_work_dir() {
    return Path.build_filename(GLib.Environment.get_user_config_dir(), "lestim");
}

public string get_settings_path() {
    return Path.build_filename(get_work_dir(), "settings.json");
}

public string get_theme_path() {
    return Path.build_filename(get_work_dir(), "theme.css");
}

public string get_background_path() {
    return Path.build_filename(get_work_dir(), "background");
}

public string get_system_backgrounds_dir() {
    return "/usr/share/backgrounds";
}

public string get_system_apps_dir() {
    return "/usr/share/applications";
}

public void check_paths () {
    GLib.File work_dir = GLib.File.new_for_path(get_work_dir());
    GLib.File settings_path = GLib.File.new_for_path(get_settings_path());
    GLib.File background_path = GLib.File.new_for_path(get_background_path());
    GLib.File theme_path = GLib.File.new_for_path(get_theme_path());

    if (!work_dir.query_exists()) {
        try {
            work_dir.make_directory_with_parents();
        } catch {return;}
    }

    if (!settings_path.query_exists()) {
        string text = "{'icon-size': 48, 'panel-orientation': 'Left', 'panel-autohide': true, 'panel-expand': false, 'panel-space-reserved': false, 'favorites-apps': []}";
        try {
            GLib.FileUtils.set_contents(get_settings_path(), text);
        } catch {return;}
    }

    if (!background_path.query_exists()) {
        var file = GLib.File.new_for_path("background");
        try {
            file.copy(background_path, FileCopyFlags.NONE);
        } catch {return;}
    }

    if (!theme_path.query_exists()) {
        var file = File.new_for_path("theme.css");
        try {
            file.copy(theme_path, FileCopyFlags.NONE);
        } catch (GLib.Error e) {}
    }
}

public Json.Object get_config() {
    check_paths();
    Json.Parser parser = new Json.Parser ();
    try {
    	parser.load_from_file(get_settings_path());
    } catch {
        return new Json.Object();
    }

	return parser.get_root().get_object();
}

public Gtk.Image get_image_from_name(string icon, int size=24) {
    try {
        var screen = Gdk.Screen.get_default();
        var theme = Gtk.IconTheme.get_for_screen(screen);
        var pixbuf = theme.load_icon(icon, size, Gtk.IconLookupFlags.FORCE_SYMBOLIC);
        var image = new Gtk.Image.from_pixbuf(pixbuf);
        return image;
    }
    catch (GLib.Error e) {
        return new Gtk.Image();
    }
}

public void set_theme() {
    Gdk.Screen screen = Gdk.Screen.get_default();
    Gtk.CssProvider css_provider = new Gtk.CssProvider();
    Gtk.StyleContext style_context = new Gtk.StyleContext();

    style_context.remove_provider_for_screen(screen, css_provider);
    try {
        css_provider.load_from_path(get_theme_path());
    } catch (GLib.Error e) {return;}

    style_context.add_provider_for_screen(screen, css_provider, Gtk.STYLE_PROVIDER_PRIORITY_USER);
}

public Gee.ArrayList get_backgrounds() {
    Gee.ArrayList<string> list = new Gee.ArrayList<string>();
    string? name = null;

    try {
        GLib.Dir dir = GLib.Dir.open(get_system_backgrounds_dir(), 0);
        while ((name = dir.read_name()) != null) {
            string path = Path.build_filename(get_system_backgrounds_dir(), name);
            list.add(Path.build_filename(path, name));
        }
    }

    catch {
        return list;
    }

    return list;
}

