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
        box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        add(box);

        image = new Gtk.Image();
        box.add(image);

        label = new Gtk.Label(null);
        box.pack_end(label, true, true, 0);

        button_release_event.connect(button_release_event_cb);
    }

    private bool button_release_event_cb(Gtk.Widget self, Gdk.EventButton event) {
        if (event.button == 1) {
            left_click();
        } else if (event.button == 3) {
            right_click();
        }

        return true;
    }

    public void set_image_from_string(string name) {
        icon_name = name;
        box.remove(image);

        image = get_image_from_name(icon_name, icon_size);
        box.add(image);
        show_all();
    }

    public void set_image_from_widget(Gtk.Image _image) {
        icon_name = null;
        box.remove(image);

        image = _image;
        box.add(image);
        show_all();
    }

    public void set_image_from_pixbuf(Gdk.Pixbuf pixbuf) {
        icon_name = null;
        box.remove(image);

        image = new Gtk.Image.from_pixbuf(pixbuf);
        box.add(image);
        show_all();
    }

    public void set_icon_size(int size) {
        if (size == icon_size) {
            return;
        }

        icon_size = size;

        if (icon_name != null) {
            set_image_from_string(icon_name);
        } else {
            Gdk.Pixbuf pixbuf = image.get_pixbuf();
            pixbuf = pixbuf.scale_simple(icon_size, icon_size, Gdk.InterpType.TILES);
            set_image_from_pixbuf(pixbuf);
        }
    }

    public void set_label(string text) {
        label.set_label(text);
    }

    public void set_show_label(bool show) {
        if (show != show_label) {
            show_label = show;
            if (show_label) {
                box.pack_end(label, true, true, 0);
            } else {
                box.remove(label);
            }
        }
    }
}

class OpenedAppButton: PanelButton {

    public OpenedAppButton() {}
    /*public Wnck.Window window;

    public OpenedAppButton(Wnck.Window _window) {
        window = _window;
        set_image_from_pixbuf(window.get_icon());
        set_tooltip_text(window.get_name());

        left_click.connect(left_click_cb);
    }

    private void left_click_cb() {
        if (!window.is_active()) {
            window.active(0);
        } else {
            window.minimize();
        }
    }
    */
}

private class ShowAppsButton: PanelButton {
    public ShowAppsButton() {
        set_name("PanelAppsButton");
        set_image_from_string("view-grid-symbolic");
        set_show_label(false);
    }
}

private class LateralPanelButton: PanelButton {
    public LateralPanelButton() {
        set_name("ShowPanelButton");
        set_image_from_string("go-previous-symbolic");
        set_show_label(false);
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
        set_name("LestimPanel");
        set_keep_above(true);
        set_decorated(false);
        set_type_hint(Gdk.WindowTypeHint.DOCK);
        set_gravity(Gdk.Gravity.STATIC);
        resize(48, 400);
        set_border_width(2);
        move(0, DISPLAY_HEIGHT / 2 - 200);
        set_skip_taskbar_hint(true);
        set_skip_pager_hint(true);
        set_urgency_hint(true);

        Gtk.drag_dest_set (
            this,
            Gtk.DestDefaults.MOTION | Gtk.DestDefaults.HIGHLIGHT,
            app_button_target_list,
            Gdk.DragAction.COPY
        );

        box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        add(box);

        show_apps_button = new ShowAppsButton();
        show_apps_button.left_click.connect(show_apps_cb);
        box.pack_start(show_apps_button, false, false, 0);

        favorite_area = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        box.pack_start(favorite_area, false, false, 5);

        //Wnck.Tasklist opened_apps_area = new Wnck.Tasklist();
        //opened_apps_area = new Wnck.Tasklist();
        //box.pack_start(opened_apps_area, false, false, 0);

        lateral_panel_button = new LateralPanelButton();
        lateral_panel_button.left_click.connect(show_lateral_panel_cb);
        box.pack_end(lateral_panel_button, false, false, 1);

        drag_data_received.connect(drag_data_received_cb);
        realize.connect(realize_cb);

        show_all();
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
        reset_pos();
    }

    private void show_lateral_panel_cb() {
        panel_visible = !(panel_visible);
        show_lateral_panel(panel_visible);
    }

    private void show_apps_cb() {
        show_apps();
    }

    public void set_reveal_state(bool visible) {
        panel_visible = visible;
        if (!visible) {
            lateral_panel_button.set_image_from_string("go-previous-symbolic");
        } else {
            lateral_panel_button.set_image_from_string("go-next-symbolic");
        }
    }

    public void set_orientation(string _orientation) {
        if (orientation == _orientation) {
            return;
        }

        orientation = _orientation;
        if (orientation == "Top" || orientation == "Bottom") {
            box.set_orientation(Gtk.Orientation.HORIZONTAL);
            favorite_area.set_orientation(Gtk.Orientation.HORIZONTAL);
        } else {
            box.set_orientation(Gtk.Orientation.VERTICAL);
            favorite_area.set_orientation(Gtk.Orientation.VERTICAL);
        }

        reset_pos();
    }

    public void set_autohide(bool _autohide) {
        autohide = _autohide;
        reveal(!autohide);
    }

    public void set_expand(bool _expand) {
        if (expand == _expand) {
            return;
        }

        expand = _expand;
        var settings = get_config();
        int s = (int)settings.get_int_member("icon-size");
        int w, h;
        get_size(out w, out h);

        if (expand) {
            switch (orientation) {
                case "Left":
                    set_size_request(w, DISPLAY_HEIGHT);
                    resize(w, DISPLAY_HEIGHT);
                    move(0, 0);
                    break;

                case "Top":
                    if (h == DISPLAY_WIDTH) {
                        h = s;
                    }

                    set_size_request(DISPLAY_WIDTH, h);
                    resize(DISPLAY_WIDTH, h);
                    move(0, 0);
                    break;

                case "Bottom":
                    if (h == DISPLAY_WIDTH) {
                        h = s;
                    }

                    set_size_request(DISPLAY_WIDTH, h);
                    resize(DISPLAY_WIDTH, h);
                    get_size(out w, out h);
                    move(DISPLAY_HEIGHT - h, 0);
                    break;
            }
        } else {
            switch (orientation) {
                case "Left":
                    set_size_request(s, 1);
                    resize(s, 1);
                    move(0, DISPLAY_HEIGHT / 2 - h / 2);
                    break;

                case "Top":
                    set_size_request(1, s);
                    resize(1, s);
                    move(DISPLAY_WIDTH / 2 - w / 2, 0);
                    break;

                case "Bottom":
                    set_size_request(1, s);
                    resize(1, s);
                    move(DISPLAY_WIDTH / 2 - w / 2, DISPLAY_HEIGHT - h);
                    break;
            }
        }
        reset_pos();
    }

    public void set_reserve_space(bool _reserve_space) {
        if (reserve_space == _reserve_space) {
            return;
        }

        reserve_space = _reserve_space;
        reserve_screen_space();
    }

    private void reserve_screen_space() {
        if (!get_realized()) {
            return;
        }
        /*
        int w, h;
        get_size(out w, out h);

        Gdk.Atom atom;
        long struts[12];

        if (shown) {
            switch (orientation) {
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
        Gdk.property_change(get_window(), atom, Gdk.Atom.intern("CARDINAL", false),
            32, Gdk.PropMode.REPLACE, (uint8[])struts, 12);
    */
    }

    public void set_icon_size(int size) {
        if (size != icon_size) {
            icon_size = size;
            show_apps_button.set_icon_size(icon_size);
            lateral_panel_button.set_icon_size(icon_size);
        }

        reset_pos();
    }

    public void reset_pos() {
        GLib.Idle.add(() => {

        if (in_transition) {
            return false;
        }

        var settings = get_config();
        int s = (int)settings.get_int_member("icon-size");
        int w, h;
        get_size(out w, out h);
        shown = true;

        if (expand) {
            switch (orientation) {
                case "Left":
                    set_size_request(s, DISPLAY_HEIGHT);
                    resize(s, DISPLAY_HEIGHT);
                    move(0, 0);
                    break;

                case "Top":
                    set_size_request(DISPLAY_WIDTH, s);
                    resize(DISPLAY_WIDTH, s);
                    move(0, 0);
                    break;

                case "Bottom":
                    set_size_request(DISPLAY_WIDTH, s);
                    resize(DISPLAY_WIDTH, s);
                    move(0, DISPLAY_HEIGHT - h);
                    break;
            }
        } else {
            switch (orientation) {
                case "Left":
                    set_size_request(s, 1);
                    resize(s, 1);
                    move(0, DISPLAY_HEIGHT / 2 - h / 2);
                    break;

                case "Top":
                    set_size_request(1, s);
                    resize(1, s);
                    move(DISPLAY_WIDTH / 2 - w / 2, 0);
                    break;

                case "Bottom":
                    set_size_request(1, s);
                    resize(1, s);
                    move(DISPLAY_WIDTH / 2 - w / 2, DISPLAY_HEIGHT - h);
                    break;
            }
        }

        return true;
        });
    }

    private bool _reveal_left() {
        int x, y, w, h;
        get_position(out x, out y);
        get_size(out w, out h);

        if (x + avance < 0) {
            in_transition = true;
            move(x + avance, DISPLAY_HEIGHT / 2 - h / 2);
            return true;
        } else {
            move(0, DISPLAY_HEIGHT / 2 - h / 2);
            in_transition = false;
            shown = true;
            return false;
        }
    }

    private bool _reveal_top() {
        int x, y, w, h;
        get_position(out x, out y);
        get_size(out w, out h);

        if (y + avance < 0) {
            in_transition = true;
            move(DISPLAY_WIDTH / 2 - w / 2, y + avance);
            return true;
        } else {
            move(DISPLAY_WIDTH / 2 - w / 2, 0);
            in_transition = false;
            shown = true;
            return false;
        }
    }

    private bool _reveal_bottom() {
        int x, y, w, h;
        get_position(out x, out y);
        get_size(out w, out h);

        if (y - avance > DISPLAY_HEIGHT - h) {
            in_transition = true;
            move(DISPLAY_WIDTH / 2 - w / 2, y - avance);
            return true;
        } else {
            move(DISPLAY_WIDTH / 2 - w / 2, DISPLAY_HEIGHT - h);
            in_transition = false;
            shown = true;
            return false;
        }
    }

    private void _reveal() {
        if (in_transition) {
            return;
        }

        switch (orientation) {
            case "Left":
                GLib.Timeout.add(20, _reveal_left);
                break;

            case "Top":
                GLib.Timeout.add(20, _reveal_top);
                break;

            case "Bottom":
                GLib.Timeout.add(20, _reveal_bottom);
                break;
        }
    }

    private bool _disreveal_left() {
        int w, h, x, y;
        get_size(out w, out h);
        get_position(out x, out y);

        if (x + w - avance > 0) {
            in_transition = true;
            move(x - avance, DISPLAY_HEIGHT / 2 - h / 2);
            return true;
        } else {
            move(-w, DISPLAY_HEIGHT / 2 - h / 2);
            in_transition = false;
            shown = false;
            return false;
        }
    }

    private bool _disreveal_top() {
        int w, h, x, y;
        get_size(out w, out h);
        get_position(out x, out y);

        if (y + h - avance > 0) {
            in_transition = true;
            move(DISPLAY_WIDTH / 2 - w / 2, y - avance);
            return true;
        } else {
            move(DISPLAY_WIDTH / 2 - w / 2, -h);
            in_transition = false;
            shown = false;
            return false;
        }
    }

    private bool _disreveal_bottom() {
        int w, h, x, y;
        get_size(out w, out h);
        get_position(out x, out y);

        if (y + avance < DISPLAY_HEIGHT) {
            in_transition = true;
            move(DISPLAY_WIDTH / 2 - w / 2, y + avance);
            return true;
        } else {
            move(DISPLAY_WIDTH / 2 - w / 2, DISPLAY_HEIGHT);
            in_transition = false;
            shown = false;
            return false;
        }
    }

    private void _disreveal() {
        if (in_transition) {
            return;
        }

        switch (orientation) {
            case "Left":
                GLib.Timeout.add(20, _disreveal_left);
                break;

            case "Top":
                GLib.Timeout.add(20, _disreveal_top);
                break;

            case "Bottom":
                GLib.Timeout.add(20, _disreveal_bottom);
                break;
        }
    }

    public void reveal(bool _shown) {
        if (_shown == shown) {
            return;
        }

        shown = _shown;
        if (shown) {
            _reveal();
        } else {
            _disreveal();
        }
    }
}
