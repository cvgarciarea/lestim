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

using Wnck;


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
    public bool can_reset = true;

    public Gtk.Box box;
    public Gtk.Box favorite_area;
    //public Wnck.Tasklist opened_apps_area;
    private ShowAppsButton show_apps_button;
    private LateralPanelButton lateral_panel_button;

    public LestimPanel() {
        set_keep_above(true);
        set_decorated(false);
        set_type_hint(Gdk.WindowTypeHint.DOCK);
        resize(48, 400);
        move(0, DISPLAY_HEIGHT / 2 - 200);
        set_name("LestimPanel");

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

        configure_event.connect(configure_event_cb);
        drag_data_received.connect(drag_data_received_cb);

        show_all();
    }

    private bool configure_event_cb(Gtk.Widget self, Gdk.EventConfigure event) {
        if (!check_pos() && can_reset) {
            reset_pos();
        }
        return false;
    }

    private void drag_data_received_cb(Gtk.Widget widget, Gdk.DragContext context, int x, int y, Gtk.SelectionData selection_data, uint target_type, uint time) {
        if ((selection_data == null) || !(selection_data.get_length() >= 0)) {
            return;
        }

        switch (target_type) {
            case Target.STRING:
                stdout.printf((string)selection_data.get_data());
                break;
            default:
                stdout.printf("Anything");
                break;
        }
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
        expand = _expand;
        int w, h;
        get_size(out w, out h);

        if (orientation == "Left") {
            set_size_request(w, DISPLAY_HEIGHT);
            resize(w, DISPLAY_HEIGHT);
            move(0, 0);
        } else {
            if (h == DISPLAY_WIDTH) {
                h = 48;
            }

            set_size_request(DISPLAY_WIDTH, h);
            resize(DISPLAY_WIDTH, h);
            if (orientation == "Top") {
                move(0, 0);
            } else {
                get_size(out w, out h);
                move(DISPLAY_HEIGHT - h, 0);
            }
        }
    }

    public void set_reserve_space(bool _reserve_space) {
        reserve_space = _reserve_space;
    }

    public void set_icon_size(int size) {
        can_reset = false;

        if (size != icon_size) {
            icon_size = size;
            show_apps_button.set_icon_size(icon_size);
            lateral_panel_button.set_icon_size(icon_size);

            reset_pos();
        }

        can_reset = true;
    }

    private bool check_pos() {
        int x, y, w, h;
        get_position(out x, out y);
        get_size(out w, out h);
        bool result = false;

        if (shown && !in_transition) {
            switch (orientation) {
                case "Left":
                    result = x == 0 && y == DISPLAY_HEIGHT / 2 - h / 2;
                    break;

                case "Top":
                    result = y == 0 && x == DISPLAY_WIDTH / 2 - w / 2;
                    break;

                default:
                    result = y == DISPLAY_WIDTH - h && x == DISPLAY_WIDTH / 2 - w / 2;
                    break;
            }
        } else if (!shown && !in_transition) {
            switch (orientation) {
                case "Left":
                    result = x == -w && y == DISPLAY_HEIGHT / 2 - h / 2;
                    break;

                case "Top":
                    result = y == -h && x == DISPLAY_WIDTH / 2 - w / 2;
                    break;

                default:
                    result = y == DISPLAY_WIDTH && x == DISPLAY_WIDTH / 2 - w / 2;
                    break;
            }
        } else if (in_transition) {
            result = true;
        }

        return result;
    }

    private void reset_pos() {
        if (expand) {
            if (orientation == "Left") {
                set_size_request(48, DISPLAY_HEIGHT);
                resize(48, DISPLAY_HEIGHT);
                move(0, 0);
            } else {
                set_size_request(DISPLAY_WIDTH, 48);
                resize(DISPLAY_WIDTH, 48);

                int w, h;
                get_size(out w, out h);

                if (orientation == "Top") {
                    move(0, 0);
                } else {
                    move(0, DISPLAY_HEIGHT - h);
                }
            }
        } else {
            if (orientation == "Left") {
                set_size_request(48, 1);
                resize(48, 1);
                int w, h;
                get_size(out w, out h);

                move(0, DISPLAY_HEIGHT / 2 - h / 2);
            } else {
                set_size_request(1, 48);
                resize(48, 1);
                int w, h;
                get_size(out w, out h);

                if (orientation == "Top") {
                    move(DISPLAY_WIDTH / 2 - w / 2, 0);
                } else {
                    move(DISPLAY_WIDTH / 2 - w / 2, DISPLAY_HEIGHT - h);
                }
            }
        }
    }

    private void _reveal() {
        if (in_transition) {
            return;
        }

        shown = true;

        int avance = 0;
        int w, h;
        get_size(out w, out h);

        int _x = DISPLAY_WIDTH / 2 - w / 2;
        int _y = DISPLAY_HEIGHT / 2 - h / 2;

        int lx = 0;
        int ly = 0;

        if (orientation == "Left") {
            GLib.Timeout.add(20, () => {
                get_position(out lx, out ly);

                if (lx < 0) {
                    in_transition = true;

                    avance = (w - lx) / 2;
                    lx = (lx + avance);
                    if (lx <= 0) {
                        move(lx, _y);
                    } else {
                        move(0, _y);
                    }

                    return true;
                } else {
                    in_transition = false;
                    return false;
                }
            });

        } else if (orientation == "Up") {
            GLib.Timeout.add(20, () => {
                get_position(out lx, out ly);

                if (ly < 0) {
                    in_transition = true;

                    avance = (h - ly) / 2;
                    ly = (ly + avance);
                    if (ly <= 0) {
                        move(_x, ly);
                    } else {
                        move(_x, 0);
                    }
                    return true;
                } else {
                    in_transition = false;
                    return false;
                }
            });

        } else if (orientation == "Bottom") {
            GLib.Timeout.add(20, () => {
                get_position(out lx, out ly);

                if (ly < DISPLAY_HEIGHT + h) {
                    avance = (DISPLAY_HEIGHT - ly) / 2;
                    ly = (ly + avance);
                    if (ly <= DISPLAY_HEIGHT - h) {
                        move(_x, ly);
                    } else {
                        move(_x, DISPLAY_HEIGHT - h);
                    }
                    return true;
                } else {
                    in_transition = false;
                    return false;
                }
            });
        }
    }

    private void _disreveal() {
        if (in_transition) {
            return;
        }

        shown = false;

        int avance = 0;
        int w, h;
        get_size(out w, out h);

        int _x = DISPLAY_WIDTH / 2 - w / 2;
        int _y = DISPLAY_HEIGHT / 2 - h / 2;

        int lx = 0;
        int ly = 0;
        if (orientation == "Left") {
            GLib.Timeout.add(20, () => {
                get_position(out lx, out ly);

                if (lx + w > 0) {
                    in_transition = true;

                    avance = (lx - w) / 2;
                    move(lx + avance, _y);
                    return true;
                } else {
                    in_transition = false;
                    return false;
                }
            });

        } else if (orientation == "Up") {
            GLib.Timeout.add(20, () => {
                get_position(out lx, out ly);
                if (ly + h > 0) {
                    in_transition = true;

                    avance = (ly - h) / 2;
                    move(_x, ly + avance);
                    return true;
                } else {
                    in_transition = false;
                    return false;
                }
            });

        } else if (orientation == "Bottom") {
            GLib.Timeout.add(20, () => {
                get_position(out lx, out ly);
                if (ly + h < DISPLAY_HEIGHT) {
                    in_transition = true;

                    avance = (DISPLAY_HEIGHT - ly) / 2;
                    move(_x, ly + avance);
                    return true;
                } else {
                    in_transition = false;
                    return false;
                }
            });
        }
    }

    public void reveal(bool visible) {
        if (visible == shown) {
            return;
        }

        shown = visible;
        if (!visible) {
            _disreveal();
        } else {
            _reveal();
        }
    }
}
