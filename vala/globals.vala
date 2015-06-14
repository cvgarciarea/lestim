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
    return join(GLib.Environment.get_user_config_dir(), "lestim");
}

public string get_settings_path() {
    return join(get_work_dir(), "settings.json");
}

public string get_theme_path() {
    return join(get_work_dir(), "theme.css");
}

public string get_background_path() {
    return join(get_work_dir(), "background");
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
        work_dir.make_directory_with_parents();
    }

    if (!settings_path.query_exists()) {
        string text = "{'icon-size': 48, 'panel-orientation': 'Left', 'panel-autohide': true, 'panel-expand': false, 'panel-space-reserved': false, 'favorites-apps': []}";
        FileUtils.set_contents(get_settings_path(), text);
    }

    if (!background_path.query_exists()) {
        var file = File.new_for_path("background");
        file.copy(background_path, FileCopyFlags.NONE);
    }

    if (!theme_path.query_exists()) {
        var file = File.new_for_path("theme.css");
        file.copy(theme_path, FileCopyFlags.NONE);
    }
}

public string join(string s1, string s2) {
    string r = s1;
    char c = (char)"/";
    if (r[-1] != c && s2[0] != c) {
        r += "/";
    }

    r += s2;
    return r;
}

public Json.Object get_config() {
    check_paths();
    Json.Parser parser = new Json.Parser ();
	parser.load_from_file(get_settings_path());
	return parser.get_root().get_object();
}

public Gtk.Image get_image(string icon, int size=24) {
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
    css_provider.load_from_path(get_theme_path());
    style_context.add_provider_for_screen(screen, css_provider, Gtk.STYLE_PROVIDER_PRIORITY_USER);
}

