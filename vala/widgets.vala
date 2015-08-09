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
    public MouseDetector mouse;

    public LestimWindow() {
        this.set_title("Lestim");
        this.set_name("LestimWindow");
        this.set_type_hint(Gdk.WindowTypeHint.DESKTOP);
        this.set_size_request(DISPLAY_WIDTH, DISPLAY_HEIGHT);
        this.move(0, 0);

        this.box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        this.box.set_name("LestimCanvas");
        this.add(this.box);

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
        this.settings_window.settings_changed.connect(this.settings_changed_cb);

        this.mouse = new MouseDetector();
        this.mouse.pos_checked.connect(this.mouse_pos_checked);

        this.realize.connect(this.realize_cb);
    }

    private void realize_cb(Gtk.Widget widget) {
        this.load_settings();
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

    public void load_settings() {
        Json.Object settings = get_config();
        this.panel.set_orientation(settings.get_string_member("panel-orientation"));
        this.panel.set_autohide(settings.get_boolean_member("panel-autohide"));
        this.panel.set_icon_size((int)settings.get_int_member("icon-size"));
        this.panel.set_expand(settings.get_boolean_member("panel-expand"));
        this.panel.set_reserve_space(settings.get_boolean_member("panel-space-reserved"));
        this.panel.set_step_size((int)settings.get_int_member("panel-animation-step-size"));

        if (settings.get_boolean_member("panel-autohide")) {
            this.mouse.start();
        } else {
            this.mouse.stop();
        }

        if (this.panel.expand && !this.panel.autohide) {
            int w, h;
            this.panel.get_size(out w, out h);
            switch(this.panel.orientation) {
                case "Left":
                    this.lateral_panel.set_size_request(300, DISPLAY_HEIGHT);
                    this.lateral_panel.resize(300, DISPLAY_HEIGHT);
                    this.lateral_panel.current_y = 0;
                    this.lateral_panel.reveal(false);
                    break;

                case "Top":
                    this.lateral_panel.set_size_request(300, DISPLAY_HEIGHT - h);
                    this.lateral_panel.resize(300, DISPLAY_HEIGHT - h);
                    this.lateral_panel.current_y = h;
                    this.lateral_panel.reveal(false);
                    break;

                case "Bottom":
                    this.lateral_panel.set_size_request(300, DISPLAY_HEIGHT - h);
                    this.lateral_panel.resize(300, DISPLAY_HEIGHT - h);
                    this.lateral_panel.current_y = 0;
                    this.lateral_panel.reveal(false);
                    break;
            }
        } else {
            this.lateral_panel.set_size_request(300, DISPLAY_HEIGHT);
        }
    }

    public void settings_changed_cb(SettingsWindow window) {
        this.load_settings();
    }

    public void mouse_pos_checked(MouseDetector mouse, int x1, int y1) {
        if (!this.panel.autohide) {
            this.mouse.stop();
            return;
        }

        int w, h, x2, y2;
        this.panel.get_size(out w, out h);
        this.panel.get_position(out x2, out y2);

        switch (this.panel.orientation) {
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

