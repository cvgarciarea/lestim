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

class Lestim: Gtk.Application {

    public GLib.Settings gsettings;

    public WallpaperWindow window;
    public LestimDock dock;
    public LestimPanel panel;
    public SettingsWindow settings_window;
    public AppsView apps_view;
    public MouseDetector mouse;

    public Lestim() {
        GLib.Object(application_id: "org.desktop.lestim");
    }

    protected override void activate() {
        get_display_size();
        check_paths();

        this.window = new WallpaperWindow();
        this.window.show();

        this.gsettings = new GLib.Settings("org.lestim.dock");
        this.gsettings.changed.connect(this.settings_changed_cb);

        this.dock = new LestimDock();
        this.dock.show_apps.connect(this.show_apps);
        this.dock.show_panel.connect(this.show_panel);

        this.apps_view = new AppsView(this.dock);
        //apps_view.connect('run-app', self.run_app)
        //apps_view.connect('favorited-app', self.update_favorited_buttons)

        this.panel = new LestimPanel();
        this.panel.show_settings.connect(this.show_settings);
        this.panel.reveal_changed.connect(this.reveal_changed);

        this.settings_window = new SettingsWindow();
        //this.settings_window.change_wallpaper.connect(this.set_wallpaper);

        this.mouse = new MouseDetector();
        //this.mouse.pos_checked.connect(this.mouse_pos_checked);

        set_theme();
    }

    public void settings_changed_cb(GLib.Settings settings, string key) {
        switch (key) {
            case "icon-size":
                this.dock.set_icon_size(this.gsettings.get_int("icon-size"));
                break;

            case "position":
                this.dock.set_position(this.gsettings.get_string("position"));
                break;

            case "autohide":
                this.dock.set_autohide(this.gsettings.get_boolean("autohide"));
                break;

            case "expand":
                this.dock.set_expand(this.gsettings.get_boolean("expand"));
                break;

            case "space-reserved":
                this.dock.set_reserve_space(this.gsettings.get_boolean("space-reserved"));
                break;

            case "animation-step-size":
                this.dock.set_step_size(this.gsettings.get_int("animation-step-size"));
                break;
        }
    }

    public void show_apps(LestimDock dock) {
        this.apps_view.reveal(!this.apps_view.visible);
    }

    public void show_panel(LestimDock dock, bool visible) {
        this.panel.reveal(visible);
    }

    public void show_settings(LestimPanel panel) {
        this.settings_window.reveal();
    }

    public void reveal_changed(LestimPanel panel, bool visible) {
        this.dock.set_reveal_state(visible);
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
}

int main (string[] args) {
    return new Lestim().run(args);
}
