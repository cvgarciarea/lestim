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

    public GLib.Settings gsettings;

    public Gtk.Box box;
    public IconView icon_view;
    public LestimPanel panel;
    public LateralPanel lateral_panel;
    public SettingsWindow settings_window;
    public AppsView apps_view;
    public MouseDetector mouse;

    public LestimWindow() {
        this.set_title("Lestim");
        this.set_name("LestimWindow");
        this.set_type_hint(Gdk.WindowTypeHint.DESKTOP);
        this.set_size_request(DISPLAY_WIDTH, DISPLAY_HEIGHT);
        this.move(0, 0);

        this.gsettings = new GLib.Settings("org.lestim.panel");
        this.gsettings.changed.connect(this.settings_changed_cb);

        this.box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        this.box.set_name("LestimCanvas");
        this.add(this.box);

        this.icon_view = new IconView();
        this.box.pack_start(this.icon_view, true, true, 0);

        this.panel = new LestimPanel();
        this.panel.show_apps.connect(show_apps);
        this.panel.show_lateral_panel.connect(this.show_lateral_panel);

        this.lateral_panel = new LateralPanel();
        this.lateral_panel.show_settings.connect(this.show_settings);
        this.lateral_panel.reveal_changed.connect(this.reveal_changed);

        this.apps_view = new AppsView(this);
        //apps_view.connect('run-app', self.run_app)
        //apps_view.connect('favorited-app', self.update_favorited_buttons)

        this.settings_window = new SettingsWindow();
        this.settings_window.change_wallpaper.connect(this.set_wallpaper);

        this.mouse = new MouseDetector();
        this.mouse.pos_checked.connect(this.mouse_pos_checked);

        this.icon_view.reload_background();
    }

    public void show_apps(LestimPanel panel) {
        this.apps_view.reveal(!this.apps_view.visible);
    }

    public void show_lateral_panel(LestimPanel panel, bool visible) {
        this.lateral_panel.reveal(visible);
    }

    public void show_settings(LateralPanel panel) {
        this.settings_window.reveal();
    }

    public void reveal_changed(LateralPanel panel, bool visible) {
        this.panel.set_reveal_state(visible);
    }

    public void settings_changed_cb(GLib.Settings settings, string key) {
        switch (key) {
            case "icon-size":
                this.panel.set_icon_size(this.gsettings.get_int("icon-size"));
                break;

            case "position":
                this.panel.set_position(this.gsettings.get_string("position"));
                break;

            case "autohide":
                this.panel.set_autohide(this.gsettings.get_boolean("autohide"));
                break;

            case "expand":
                this.panel.set_expand(this.gsettings.get_boolean("expand"));
                break;

            case "space-reserved":
                this.panel.set_reserve_space(this.gsettings.get_boolean("space-reserved"));
                break;

            case "animation-step-size":
                this.panel.set_step_size(this.gsettings.get_int("animation-step-size"));
                break;
        }
    }

    public void mouse_pos_checked(MouseDetector mouse, int x1, int y1) {
        if (!this.gsettings.get_boolean("autohide")) {
            this.mouse.stop();
            return;
        }

        int w, h, x2, y2;
        this.panel.get_size(out w, out h);
        this.panel.get_position(out x2, out y2);

        switch (this.gsettings.get_string("position")) {
            case "Left":
                if ((x1 <= 10) && (y1 >= y2) && (y1 <= y2 + h) && !this.panel.shown) {
                    this.panel.reveal(true);
                }
                else if ((x1 >= w) || (y1 <= y2) || (y1 >= y2 + h) && this.panel.shown) {
                    //panel.reveal(detector.panel_visible || apps_view.shown);
                    this.panel.reveal(this.apps_view.shown);
                }
                break;

            case "Top":
                if ((y1 <= 10) && (x1 >= x2) && (x1 <= x2 + w) && !this.panel.shown) {
                    this.panel.reveal(true);
                }
                else if ((y1 >= h) || (x1 <= x2) || (x1 >= x2 + w) && this.panel.shown) {
                    //panel.reveal(detector.panel_visible || apps_view.shown);
                    this.panel.reveal(this.apps_view.shown);
                }
                break;

            case "Bottom":
                if ((y1 >= DISPLAY_HEIGHT - 10) && (x1 >= x2) && (x1 <= x2 + w) && !this.panel.shown) {
                    this.panel.reveal(true);
                }
                else if ((y1 <= DISPLAY_HEIGHT - h) || (x1 <= x2) || (x1 >= x2 + w) && this.panel.shown) {
                    //panel.reveal(detector.panel_visible || apps_view.shown);
                    this.panel.reveal(this.apps_view.shown);
                }
                break;

            default:
                this.panel.reveal(true);
                break;
        }
    }

    public void set_wallpaper(SettingsWindow win, string path) {
        GLib.File file1 = GLib.File.new_for_path(get_background_path());

	    GLib.File file2 = GLib.File.new_for_path(path);
	    file2.copy(file1, GLib.FileCopyFlags.OVERWRITE);

        this.icon_view.reload_background();
    }
}

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

