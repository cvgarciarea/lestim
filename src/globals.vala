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

public int CURRENT_MONITOR = 0;
public int DISPLAY_WIDTH = 0;
public int DISPLAY_HEIGHT = 0;

public void get_display_size(int? monitor_id = null) {
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

const int BYTE_BITS = 8;
const int WORD_BITS = 16;
const int DWORD_BITS = 32;

public enum Target {
    INT32,
    STRING
}

public const Gtk.TargetEntry[] apps_target_list = {
    { "INTEGER",    0, Target.INT32 },  // Index
    { "STRING",     0, Target.STRING }, // ID
    { "text/plain", 0, Target.STRING }  // Name
};

public string get_home_dir() {
    return GLib.Environment.get_home_dir();
}

public string get_desktop_dir() {
    return GLib.Environment.get_variable("XDG_DESKTOP_DIR");
}

public string get_work_dir() {
    return GLib.Path.build_filename(GLib.Environment.get_user_config_dir(), "lestim");
}

public string get_theme_path() {
    return GLib.Path.build_filename(get_work_dir(), "theme.css");
}

public string get_background_path() {
    return GLib.Path.build_filename(get_work_dir(), "background");
}

public string get_system_backgrounds_dir() {
    return "/usr/share/backgrounds";
}

public string get_system_apps_dir() {
    return "/usr/share/applications";
}

public void check_paths() {
    GLib.File work_dir = GLib.File.new_for_path(get_work_dir());
    GLib.File background_path = GLib.File.new_for_path(get_background_path());
    GLib.File theme_path = GLib.File.new_for_path(get_theme_path());

    if (!work_dir.query_exists()) {
        try {
            work_dir.make_directory_with_parents();
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
    GLib.File file = GLib.File.new_for_path(get_system_backgrounds_dir());
    GLib.Cancellable cancellable = new GLib.Cancellable();

    return list_children(list, file, cancellable);
}

private Gee.ArrayList<string> list_children(Gee.ArrayList<string> list, GLib.File file, GLib.Cancellable cancellable) {
	try {
	    GLib.FileEnumerator enumerator = file.enumerate_children (
		    "standard::*",
		    GLib.FileQueryInfoFlags.NOFOLLOW_SYMLINKS,
		    cancellable);

	    GLib.FileInfo info = null;
	    while (!cancellable.is_cancelled() && ((info = enumerator.next_file(cancellable)) != null)) {
		    if (info.get_file_type() == GLib.FileType.DIRECTORY) {
			    GLib.File subdir = file.resolve_relative_path (info.get_name());
			    list_children(list, subdir, cancellable);
		    } else {
		        string path = GLib.Path.build_filename(file.get_path(), info.get_name());
		        GLib.File new_file = GLib.File.new_for_path(path);
		        string mime = new_file.query_info("*", GLib.FileQueryInfoFlags.NONE).get_content_type();
		        if ("image" in mime) {
                    list.add(path);
                }
		    }
	    }
	    return list;
    } catch (GLib.Error e) {
        return list;
    }
}

public void get_current_time(bool with_seconds, out string time, out string date) {
    GLib.DateTime TIME = new GLib.DateTime.now_local();

    string format_time = "%H:%M" + (with_seconds ? ":%S": "");
    string format_date = "%d/%m/%Y";

    time = TIME.format(format_time);
    date = TIME.format(format_date);
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

//public class WindowPositionDetector: Object {

    //__gsignals__ = {
    //    "show-panel": (GObject.SIGNAL_RUN_FIRST, None, []),
    //    "hide-panel": (GObject.SIGNAL_RUN_FIRST, None, [])
    //}

//    public LestimPanel panel;
//    public bool panel_visible = true;
    //public Wnck.Screen screen;

//    public WindowPositionDetector(LestimPanel panel) {
//        this.panel = panel;
        //screen = Wnck.Screen.get_default();
//    }
//}
/*
public class SoundControl: GLib.Object {

    private Gvc.MixerControl mixer;
    private Gvc.MixerStream stream;

    public SoundControl() {
        this.mixer = new Gvc.MixerControl("Lestim Volume Control");
        this.mixer.state_changed.connect(this.state_changed_cb);
        this.mixer.open();
    }

    protected void state_changed_cb(Gvc.MixerControl mixer, uint new_state) {
        if (new_state == Gvc.MixerControlState.READY) {
            this.stream = this.mixer.get_default_sink();
            this.stream.notify.connect((s, p)=> {
                if (p.name == "volume" || p.name == "is-muted") {
                    this.update_volume();
                }
            });
            this.update_volume();
        }
    }

    protected void update_volume() {
        var vol_norm = this.mixer.get_vol_max_norm();
        var vol = this.stream.get_volume();

        int n = (int) Math.floor(3*vol/vol_norm)+1;
        string image_name;

        // Work out an icon
        if (stream.get_is_muted() || vol <= 0) {
            image_name = "audio-volume-muted-symbolic";
        } else {
            switch (n) {
                case 1:
                    image_name = "audio-volume-low-symbolic";
                    break;
                case 2:
                    image_name = "audio-volume-medium-symbolic";
                    break;
                default:
                    image_name = "audio-volume-high-symbolic";
                    break;
            }
        }
        //widget.set_from_icon_name(image_name, Gtk.IconSize.INVALID);
        //status_image.set_from_icon_name(image_name, Gtk.IconSize.INVALID);

        var vol_max = this.mixer.get_vol_max_amplified();

        stdout.printf(vol_max.to_string() + "\n");
        stdout.printf(image_name + "\n");
        // Each scroll increments by 5%, much better than units..
        //step_size = vol_max / 20;
        //GLib.SignalHandler.block(status_widget, change_id);
        //status_widget.set_range(0, vol_max);
        //status_widget.set_value(vol);
        //status_widget.set_increments(step_size, step_size);
        //if (vol_norm < vol_max) {
        //    status_widget.add_mark(vol_norm, Gtk.PositionType.TOP, null);
        //} else {
        //    status_widget.clear_marks();
        //}
        //SignalHandler.unblock(status_widget, change_id);

        // This usually goes up to about 150% (152.2% on mine though.)
        //var pct = ((float)vol / (float)vol_norm)*100;
        //var ipct = (uint)pct;
        //widget.set_tooltip_text(@"$ipct%");

        // Gtk 3.12 issue, ensure we show all..
        //show_all();
        //queue_draw();
    }
}
*/
