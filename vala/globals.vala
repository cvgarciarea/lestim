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

using Gtk;
using Gdk;

public int CURRENT_MONITOR = 0;
public int DISPLAY_WIDTH = 0;
public int DISPLAY_HEIGHT = 0;

public void set_display_size(int? monitor_id = null) {
    Gdk.Screen screen = Gdk.Screen.get_default();
    Gdk.Rectangle rect;

    if (monitor_id == null) {
        monitor_id = screen.get_primary_monitor();
    }

    CURRENT_MONITOR = monitor_id;
    screen.get_monitor_geometry(CURRENT_MONITOR, out rect);
    DISPLAY_WIDTH = rect.width;
    DISPLAY_HEIGHT = rect.height;
}

enum Target {
    STRING,
}

const TargetEntry[] app_button_target_list = {
    {"STRING", 0, Target.STRING},
};

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

public void check_paths() {
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
        string text = "{'icon-size': 48,
                        'panel-orientation': 'Left',
                        'panel-autohide': true,
                        'panel-expand': false,
                        'panel-space-reserved': false,
                        'panel-animation-step-size': 5;
                        'favorites-apps': []
                        }";
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

public void set_config(Json.Object settings) {
    var root_node = new Json.Node (Json.NodeType.OBJECT);
    root_node.set_object(settings);

    var generator = new Json.Generator(){pretty=true, root=root_node};
    generator.to_file(get_settings_path());
}

public Gtk.Image get_image_from_name(string icon, int size=24) {
    try {
        var screen = Gdk.Screen.get_default();
        var theme = Gtk.IconTheme.get_for_screen(screen);
        var pixbuf = theme.load_icon(icon, size, Gtk.IconLookupFlags.FORCE_SYMBOLIC);

        if (pixbuf.get_width() != size || pixbuf.get_height() != size) {
            pixbuf = pixbuf.scale_simple(size, size, Gdk.InterpType.BILINEAR);
        }

        return new Gtk.Image.from_pixbuf(pixbuf);
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
    //try {
    css_provider.load_from_path(get_theme_path());
    //} catch (GLib.Error e) {return;}

    style_context.add_provider_for_screen(screen, css_provider, Gtk.STYLE_PROVIDER_PRIORITY_USER);
}

public Gee.ArrayList get_backgrounds() {
    Gee.ArrayList<string> list = new Gee.ArrayList<string>();
    string? name = null;

    try {
        GLib.Dir dir = GLib.Dir.open(get_system_backgrounds_dir(), 0);
        while ((name = dir.read_name()) != null) {
            string path = Path.build_filename(get_system_backgrounds_dir(), name);
            list.add(path);
        }
    } catch {}

    return list;
}

public void set_wallpaper(string path) {
    File file = File.new_for_path(get_background_path());
    file.delete();

	file.make_symbolic_link(path);
	set_theme();
}

public class MouseDetector: Object {

    public signal void pos_checked(int x, int y);

    public int x;
    public int y;
    public bool checking = false;

    public MouseDetector() {
    }

    public void start() {
        if (!this.checking) {
            this.checking = true;
            GLib.Timeout.add(100, this.check);
        }
    }

    public void stop() {
        checking = false;
    }

    private bool check() {
        X.Display display = new X.Display();
        X.Event event = X.Event();
        X.Window window = display.default_root_window();

        display.query_pointer(window, out window,
            out event.xbutton.subwindow, out event.xbutton.x_root,
            out event.xbutton.y_root, out event.xbutton.x,
            out event.xbutton.y, out event.xbutton.state);

        this.x = event.xbutton.x_root;
        this.y = event.xbutton.y_root;

        this.pos_checked(x, y);

        return checking;
    }
}

public class WindowPositionDetector: Object {

    //__gsignals__ = {
    //    'show-panel': (GObject.SIGNAL_RUN_FIRST, None, []),
    //    'hide-panel': (GObject.SIGNAL_RUN_FIRST, None, [])
    //}

    public LestimPanel panel;
    public bool panel_visible = true;
    //public Wnck.Screen screen;

    public WindowPositionDetector(LestimPanel panel) {
        this.panel = panel;
        //screen = Wnck.Screen.get_default();
    }
}
