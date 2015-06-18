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


public class LestimWindow: Gtk.ApplicationWindow {

    //bool panel_orientation;
    //bool panel_autohide;
    //bool panel_expand;
    //bool panel_space_reserved;

    public Gtk.Box box;
    public LestimPanel panel;
    public LateralPanel lateral_panel;
    public SettingsWindow settings_window;
    public AppsView apps_view;

    public LestimWindow() {
        set_title("Lestim");
        set_name("LestimWindow");
        set_type_hint(Gdk.WindowTypeHint.DESKTOP);
        set_size_request(DISPLAY_WIDTH, DISPLAY_HEIGHT);
        move(0, 0);

        box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        box.set_name("Canvas");
        add(box);

        panel = new LestimPanel();
        panel.show_apps.connect(show_apps);
        panel.show_lateral_panel.connect(show_lateral_panel);

        lateral_panel = new LateralPanel();
        lateral_panel.show_settings.connect(show_settings);
        lateral_panel.reveal_changed.connect(reveal_changed);

        apps_view = new AppsView(this);
        //apps_view.connect('run-app', self.run_app)
        //apps_view.connect('favorited-app', self.update_favorited_buttons)

        settings_window = new SettingsWindow();

        load_settings();
    }

    public void show_apps(LestimPanel panel) {
        apps_view.reveal(!apps_view.visible);
    }

    public void show_lateral_panel(LestimPanel _panel, bool visible) {
        lateral_panel.reveal(visible);
    }

    public void show_settings(LateralPanel _panel) {
        settings_window.reveal();
    }

    public void reveal_changed(LateralPanel _panel, bool visible) {
        panel.set_reveal_state(visible);
    }

    public void load_settings() {
        var object = get_config();
        panel.set_orientation(object.get_string_member("panel-orientation"));
        panel.set_icon_size((int)object.get_int_member("icon-size"));
    }
}

public class AppButton: Gtk.Button {

    public GLib.DesktopAppInfo app_info;
    public Gtk.Box vbox;

    public AppButton(GLib.DesktopAppInfo _app_info, bool show_label=false) {
        app_info = _app_info;

        set_name("AppButton");
        set_tooltip_text(app_info.get_description());
        set_hexpand(false);
        set_vexpand(false);

        vbox = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        vbox.set_hexpand(false);
        add(vbox);

        if (show_label) {
            vbox.pack_end(new Gtk.Label(app_info.get_name()), false, false, 2);
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

        vbox.pack_start(new Gtk.Image.from_pixbuf(pixbuf), false, false, 0);
    }
}

