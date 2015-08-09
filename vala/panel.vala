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

class PanelButton: Gtk.EventBox {

    public signal void right_click();
    public signal void left_click();

    public Gtk.Box box;
    public Gtk.Image image;
    public Gtk.Label label;

    public int icon_size = 48;
    public bool show_label = true;
    public string? icon_name;

    public PanelButton() {
        this.box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        this.add(this.box);

        this.image = new Gtk.Image();
        this.box.add(this.image);

        this.label = new Gtk.Label(null);
        this.box.pack_end(this.label, true, true, 0);

        this.button_release_event.connect(this.button_release_event_cb);
    }

    private bool button_release_event_cb(Gtk.Widget self, Gdk.EventButton event) {
        if (event.button == 1) {
            this.left_click();
        } else if (event.button == 3) {
            this.right_click();
        }

        return true;
    }

    public void set_image_from_string(string name) {
        this.icon_name = name;
        this.box.remove(this.image);

        this.image = get_image_from_name(this.icon_name, this.icon_size);
        this.box.add(this.image);
        this.show_all();
    }

    public void set_image_from_widget(Gtk.Image image) {
        this.icon_name = null;
        this.box.remove(this.image);

        this.image = image;
        this.box.add(this.image);
        this.show_all();
    }

    public void set_image_from_pixbuf(Gdk.Pixbuf pixbuf) {
        this.icon_name = null;
        this.box.remove(this.image);

        this.image = new Gtk.Image.from_pixbuf(pixbuf);
        this.box.add(this.image);
        this.show_all();
    }

    public void set_icon_size(int size) {
        if (size == this.icon_size) {
            return;
        }

        this.icon_size = size;

        if (this.icon_name != null) {
            this.set_image_from_string(this.icon_name);
        } else {
            Gdk.Pixbuf pixbuf = this.image.get_pixbuf();
            pixbuf = pixbuf.scale_simple(this.icon_size, this.icon_size, Gdk.InterpType.TILES);
            this.set_image_from_pixbuf(pixbuf);
        }
    }

    public void set_label(string text) {
        this.label.set_label(text);
    }

    public void set_show_label(bool show) {
        if (show != this.show_label) {
            this.show_label = show;
            if (this.show_label) {
                this.box.pack_end(this.label, true, true, 0);
            } else {
                this.box.remove(this.label);
            }
        }
    }
}

class OpenedAppButton: PanelButton {

    public OpenedAppButton() {}
    /*public Wnck.Window window;

    public OpenedAppButton(Wnck.Window _window) {
        window = _window;
        this.set_image_from_pixbuf(window.get_icon());
        this.set_tooltip_text(window.get_name());

        this.left_click.connect(this.left_click_cb);
    }

    private void left_click_cb() {
        if (!this.window.is_active()) {
            this.window.active(0);
        } else {
            this.window.minimize();
        }
    }
    */
}

private class ShowAppsButton: PanelButton {
    public ShowAppsButton() {
        this.set_name("PanelAppsButton");
        this.set_image_from_string("view-grid-symbolic");
        this.set_show_label(false);
    }
}

private class LateralPanelButton: PanelButton {
    public LateralPanelButton() {
        this.set_name("ShowPanelButton");
        this.set_image_from_string("go-previous-symbolic");
        this.set_show_label(false);
    }
}

public class LestimPanel: Gtk.Window {

    public signal void show_apps();
    public signal void show_lateral_panel(bool visible);

    public bool shown = true;
    public string orientation = "Left";
    public bool expand = false;
    public bool autohide = false;
    public bool reserve_space = false;
    public int icon_size = 48;
    public bool panel_visible = false;
    public bool in_transition = false;
    public int avance = 10;

    public Gtk.Box box;
    public Gtk.Box favorite_area;
    //public Wnck.Tasklist opened_apps_area;
    private ShowAppsButton show_apps_button;
    private LateralPanelButton lateral_panel_button;

    public LestimPanel() {
        this.set_name("LestimPanel");
        this.set_keep_above(true);
        this.set_decorated(false);
        this.set_type_hint(Gdk.WindowTypeHint.DOCK);
        this.set_gravity(Gdk.Gravity.STATIC);
        this.resize(48, 400);
        this.set_border_width(2);
        this.move(0, DISPLAY_HEIGHT / 2 - 200);
        this.set_skip_taskbar_hint(true);
        this.set_skip_pager_hint(true);
        this.set_urgency_hint(true);

        Gtk.drag_dest_set (
            this,
            Gtk.DestDefaults.MOTION | Gtk.DestDefaults.HIGHLIGHT,
            app_button_target_list,
            Gdk.DragAction.COPY
        );

        this.box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        this.add(this.box);

        this.show_apps_button = new ShowAppsButton();
        this.show_apps_button.left_click.connect(show_apps_cb);
        this.box.pack_start(this.show_apps_button, false, false, 0);

        this.favorite_area = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        this.box.pack_start(this.favorite_area, false, false, 5);

        //Wnck.Tasklist opened_apps_area = new Wnck.Tasklist();
        //this.opened_apps_area = new Wnck.Tasklist();
        //this.box.pack_start(this.opened_apps_area, false, false, 0);

        this.lateral_panel_button = new LateralPanelButton();
        this.lateral_panel_button.left_click.connect(this.show_lateral_panel_cb);
        this.box.pack_end(this.lateral_panel_button, false, false, 1);

        this.drag_data_received.connect(this.drag_data_received_cb);
        this.realize.connect(this.realize_cb);

        this.show_all();
    }

    private void drag_data_received_cb(Gtk.Widget widget, Gdk.DragContext context, int x, int y, Gtk.SelectionData selection_data, uint target_type, uint time) {
        if ((selection_data == null) || !(selection_data.get_length() >= 0)) {
            return;
        }

        switch (target_type) {
            case Target.STRING:
                stdout.printf((string)selection_data.get_data() + "\n");
                break;
            default:
                stdout.printf("Anything\n");
                break;
        }
    }

    private void realize_cb() {
        this.reset_pos();
    }

    private void show_lateral_panel_cb() {
        this.show_lateral_panel(!this.panel_visible);
    }

    private void show_apps_cb() {
        this.show_apps();
    }

    public void set_reveal_state(bool visible) {
        this.panel_visible = visible;
        if (!this.panel_visible) {
            this.lateral_panel_button.set_image_from_string("go-previous-symbolic");
        } else {
            this.lateral_panel_button.set_image_from_string("go-next-symbolic");
        }
    }

    public void set_orientation(string orientation) {
        if (this.orientation == orientation) {
            return;
        }

        this.orientation = orientation;
        if (this.orientation == "Top" || this.orientation == "Bottom") {
            this.box.set_orientation(Gtk.Orientation.HORIZONTAL);
            this.favorite_area.set_orientation(Gtk.Orientation.HORIZONTAL);
        } else {
            this.box.set_orientation(Gtk.Orientation.VERTICAL);
            this.favorite_area.set_orientation(Gtk.Orientation.VERTICAL);
        }

        this.reset_pos();
    }

    public void set_autohide(bool autohide) {
        this.autohide = autohide;
        this.reveal(!this.autohide);
    }

    public void set_expand(bool expand) {
        if (this.expand == expand) {
            return;
        }

        this.expand = expand;
        var settings = get_config();
        int w, h;
        this.get_size(out w, out h);
        this.reset_pos();
    }

    public void set_reserve_space(bool reserve_space) {
        if (this.reserve_space == reserve_space) {
            return;
        }

        this.reserve_space = reserve_space;
        this.reserve_screen_space();
    }

    private void reserve_screen_space() {
        if (!this.get_realized()) {
            return;
        }
        /*
        int w, h;
        this.get_size(out w, out h);

        Gdk.Atom atom;
        long struts[12];

        if (this.shown) {
            switch (this.orientation) {
                case "Top":
                    struts = {0, 0, h, 0,
                              0, 0, 0, 0,
                              0, DISPLAY_WIDTH, 0, 0};
                    break;
                case "Left":
                    struts = {w, 0, 0, 0,
                              0, DISPLAY_HEIGHT,
                              0, 0, 0, 0, 0, 0};
                    break;
                case "Bottom":
                    struts = {0, 0, 0,
                              DISPLAY_HEIGHT - h,
                              0, 0, 0, 0, 0, 0,
                              0, w};
                    break;
            }
        } else {
            struts = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
        }

        atom = Gdk.Atom.intern("_NET_WM_STRUT_PARTIAL", false);
        Gdk.property_change(this.get_window(), atom, Gdk.Atom.intern("CARDINAL", false),
            32, Gdk.PropMode.REPLACE, (uint8[])struts, 12);
    */
    }

    public void set_step_size(int avance) {
        this.avance = avance;
    }

    public void set_icon_size(int size) {
        if (this.icon_size != size) {
            this.icon_size = size;
            this.show_apps_button.set_icon_size(this.icon_size);
            this.lateral_panel_button.set_icon_size(this.icon_size);
        }

        this.reset_pos();
    }

    public void reset_pos() {
        GLib.Idle.add(() => {
            if (this.in_transition) {
                return false;
            }

            var settings = get_config();
            int s = (int)settings.get_int_member("icon-size");
            int w, h;
            this.get_size(out w, out h);
            this.shown = true;

            if (this.expand) {
                switch (this.orientation) {
                    case "Left":
                        this.set_size_request(s, DISPLAY_HEIGHT);
                        this.resize(s, DISPLAY_HEIGHT);
                        break;

                    case "Top":
                        this.set_size_request(DISPLAY_WIDTH, s);
                        this.resize(DISPLAY_WIDTH, s);
                        break;

                    case "Bottom":
                        this.set_size_request(DISPLAY_WIDTH, s);
                        this.resize(DISPLAY_WIDTH, s);
                        break;
                }
            } else {
                switch (this.orientation) {
                    case "Left":
                        this.set_size_request(s, 1);
                        this.resize(s, 1);
                        break;

                    case "Top":
                        this.set_size_request(1, s);
                        this.resize(1, s);
                        break;

                    case "Bottom":
                        this.set_size_request(1, s);
                        this.resize(1, s);
                        break;
                }
            }

            this.get_size(out w, out h);
            if (this.shown) {
                switch(this.orientation) {
                    case "Left":
                        this.move(0, !this.expand? DISPLAY_HEIGHT / 2 - h / 2: 0);
                        break;

                    case "Top":
                        this.move(!this.expand? DISPLAY_WIDTH / 2 - w / 2: 0, 0);
                        break;

                    case "Bottom":
                        this.move(!this.expand? DISPLAY_WIDTH / 2 - w / 2: 0, DISPLAY_HEIGHT - h);
                        break;
                }
            } else {
                switch(this.orientation) {
                    case "Left":
                        this.move(-w, !this.expand? DISPLAY_HEIGHT / 2 - h / 2: 0);
                        break;

                    case "Top":
                        this.move(!this.expand? DISPLAY_WIDTH / 2 - w / 2: 0, -h);
                        break;

                    case "Bottom":
                        this.move(!this.expand? DISPLAY_WIDTH / 2 - w / 2: 0, DISPLAY_HEIGHT);
                        break;
                }
            }
            return true;
        });
    }

    private bool _reveal_left() {
        int x, y, w, h;
        this.get_position(out x, out y);
        this.get_size(out w, out h);

        if (x + avance < 0) {
            this.in_transition = true;
            this.move(x + avance, DISPLAY_HEIGHT / 2 - h / 2);
            return true;
        } else {
            this.move(0, DISPLAY_HEIGHT / 2 - h / 2);
            this.in_transition = false;
            this.shown = true;
            return false;
        }
    }

    private bool _reveal_top() {
        int x, y, w, h;
        this.get_position(out x, out y);
        this.get_size(out w, out h);

        if (y + avance < 0) {
            this.in_transition = true;
            this.move(DISPLAY_WIDTH / 2 - w / 2, y + avance);
            return true;
        } else {
            this.move(DISPLAY_WIDTH / 2 - w / 2, 0);
            this.in_transition = false;
            this.shown = true;
            return false;
        }
    }

    private bool _reveal_bottom() {
        int x, y, w, h;
        this.get_position(out x, out y);
        this.get_size(out w, out h);

        if (y - avance > DISPLAY_HEIGHT - h) {
            this.in_transition = true;
            this.move(DISPLAY_WIDTH / 2 - w / 2, y - avance);
            return true;
        } else {
            this.move(DISPLAY_WIDTH / 2 - w / 2, DISPLAY_HEIGHT - h);
            this.in_transition = false;
            this.shown = true;
            return false;
        }
    }

    private void _reveal() {
        if (this.in_transition) {
            return;
        }

        switch (this.orientation) {
            case "Left":
                GLib.Timeout.add(20, this._reveal_left);
                break;

            case "Top":
                GLib.Timeout.add(20, this._reveal_top);
                break;

            case "Bottom":
                GLib.Timeout.add(20, this._reveal_bottom);
                break;
        }
    }

    private bool _disreveal_left() {
        int w, h, x, y;
        this.get_size(out w, out h);
        this.get_position(out x, out y);

        if (x + w - avance > 0) {
            this.in_transition = true;
            this.move(x - avance, DISPLAY_HEIGHT / 2 - h / 2);
            return true;
        } else {
            this.move(-w, DISPLAY_HEIGHT / 2 - h / 2);
            this.in_transition = false;
            this.shown = false;
            return false;
        }
    }

    private bool _disreveal_top() {
        int w, h, x, y;
        this.get_size(out w, out h);
        this.get_position(out x, out y);

        if (y + h - avance > 0) {
            this.in_transition = true;
            this.move(DISPLAY_WIDTH / 2 - w / 2, y - avance);
            return true;
        } else {
            this.move(DISPLAY_WIDTH / 2 - w / 2, -h);
            this.in_transition = false;
            this.shown = false;
            return false;
        }
    }

    private bool _disreveal_bottom() {
        int w, h, x, y;
        this.get_size(out w, out h);
        this.get_position(out x, out y);

        if (y + avance < DISPLAY_HEIGHT) {
            this.in_transition = true;
            this.move(DISPLAY_WIDTH / 2 - w / 2, y + avance);
            return true;
        } else {
            this.move(DISPLAY_WIDTH / 2 - w / 2, DISPLAY_HEIGHT);
            this.in_transition = false;
            this.shown = false;
            return false;
        }
    }

    private void _disreveal() {
        if (this.in_transition) {
            return;
        }

        switch (this.orientation) {
            case "Left":
                GLib.Timeout.add(20, this._disreveal_left);
                break;

            case "Top":
                GLib.Timeout.add(20, this._disreveal_top);
                break;

            case "Bottom":
                GLib.Timeout.add(20, this._disreveal_bottom);
                break;
        }
    }

    public void reveal(bool shown) {
        if (this.shown == shown) {
            return;
        }

        this.shown = shown;
        if (this.shown) {
            this._reveal();
        } else {
            this._disreveal();
        }
    }
}
