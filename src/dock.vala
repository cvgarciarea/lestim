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

public class LestimDock: Gtk.Window {

    public signal void show_apps();
    public signal void show_panel(bool visible);

    public GLib.Settings gsettings;

    public bool shown = true;
    public bool panel_visible = false;
    public bool in_transition = false;

    public Gtk.Box box;
    public Gtk.Box favorite_area;
    //public Wnck.Tasklist opened_apps_area;
    private Ltk.ShowAppsButton show_apps_button;
    private Ltk.ShowLateralPanelButton lateral_panel_button;

    public LestimDock() {
        this.set_name("LestimDock");
        this.set_keep_above(true);
        this.set_decorated(false);
        this.set_type_hint(Gdk.WindowTypeHint.DOCK);
        this.set_gravity(Gdk.Gravity.STATIC);
        this.set_border_width(2);
        this.set_skip_taskbar_hint(true);
        this.set_skip_pager_hint(true);
        this.set_urgency_hint(true);
        this.set_app_paintable(true);
        this.set_visual(screen.get_rgba_visual());

        this.gsettings = new GLib.Settings("org.lestim.dock");
        this.gsettings.changed.connect(this.settings_changed_cb);

        this.box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        this.add(this.box);

        this.show_apps_button = new Ltk.ShowAppsButton();
        this.box.pack_start(this.show_apps_button, false, false, 0);

        this.show_apps_button.left_click.connect(() => {
            this.show_apps();
        });

        this.favorite_area = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        this.box.pack_start(this.favorite_area, true, true, 5);

        Gtk.drag_dest_set(this.favorite_area,
                          Gtk.DestDefaults.MOTION | Gtk.DestDefaults.HIGHLIGHT,
                          apps_target_list,
                          Gdk.DragAction.COPY);

        this.favorite_area.drag_motion.connect(this.drag_motion_cb);
        this.favorite_area.drag_leave.connect(this.drag_leave_cb);
        this.favorite_area.drag_drop.connect(this.drag_drop_cb);
        this.favorite_area.drag_data_received.connect(this.drag_data_received_cb);

        //Wnck.Tasklist opened_apps_area = new Wnck.Tasklist();
        //this.opened_apps_area = new Wnck.Tasklist();
        //this.box.pack_start(this.opened_apps_area, false, false, 0);

        this.lateral_panel_button = new Ltk.ShowLateralPanelButton();
        this.box.pack_end(this.lateral_panel_button, false, false, 1);

        this.lateral_panel_button.left_click.connect(() => {
            this.show_panel(!this.panel_visible);
        });

        this.realize.connect(() => {
            this.reload_favorited_buttons();
        });

        this.draw.connect(this.draw_cb);
    }

    private bool draw_cb(Cairo.Context ctx) {
        double t = 1.0 - (double)(this.gsettings.get_int("background-transparency")) / 10.0;

        ctx.set_source_rgba(Constants.bg_color[0], Constants.bg_color[1], Constants.bg_color[2], t);
        ctx.set_operator(Cairo.Operator.SOURCE);
        ctx.paint();

        return false;
    }

    public void settings_changed_cb(GLib.Settings gsettings, string key) {
        switch (key) {
            case "icon-size":
                this.reset_pos();
                break;

            case "position":
                this.reload_position();
                break;

            case "autohide":
                this.reveal(!this.gsettings.get_boolean("autohide"));
                break;

            case "expand":
                this.reset_pos();
                break;

            case "space-reserved":
                this.reload_space_reserved();
                break;

            case "animation-step-size":
                break;

            case "favorites-apps":
                this.reload_favorited_buttons();
                break;

            case "background-transparency":
                this.queue_draw();
                break;
        }
    }

    private void drag_data_received_cb(Gtk.Widget widget, Gdk.DragContext context,
                                       int x, int y,
                                       Gtk.SelectionData selection_data,
                                       uint target_type, uint time) {
        bool dnd_success = false;
        bool delete_selection_data = false;

        if ((selection_data != null) && (selection_data.get_length() >= 0)) {
            if (context.get_suggested_action() == Gdk.DragAction.MOVE) {
                delete_selection_data = true;
            }

            switch (target_type) {
                case Target.STRING:
                    string app = (string)selection_data.get_data();
                    string[] apps = this.gsettings.get_strv("favorites-apps");

                    if (!(app in apps)) {
                        apps += app;
                        this.gsettings.set_strv("favorites-apps", apps);
                    }

                    dnd_success = true;
                    break;
                default:
                    break;
            }
        }
        Gtk.drag_finish(context, dnd_success, delete_selection_data, time);
    }

    private bool drag_motion_cb(Gtk.Widget widget, Gdk.DragContext context, int x, int y, uint time) {
        // Draw in the dock
        return false;
    }

    private void drag_leave_cb(Gtk.Widget widget, Gdk.DragContext context, uint time) {
        // Remove the icon drawed
    }

    private bool drag_drop_cb(Gtk.Widget widget, Gdk.DragContext context, int x, int y, uint time) {
        bool is_valid_drop_site = true;

        if (context.list_targets() != null) {
            var target_type = (Gdk.Atom)context.list_targets().nth_data(Target.STRING);
            Gtk.drag_get_data(widget, context, target_type, time);
        } else {
            is_valid_drop_site = false;
        }

        return is_valid_drop_site;
    }

    public void reload_favorited_buttons() {
        foreach (Gtk.Widget button in this.favorite_area.get_children()) {
            this.favorite_area.remove(button);
        }

        string[] apps = this.gsettings.get_strv("favorites-apps");

        foreach (string desktop_file in apps) {
            GLib.File file = GLib.File.new_for_path(desktop_file);
            if (!file.query_exists()) {
                continue;
            }

            Ltk.IconManager icon_manager = new Ltk.IconManager();
            Ltk.App app = new Ltk.App(desktop_file, icon_manager);
            Ltk.FavoriteAppButton button = new Ltk.FavoriteAppButton(app);

            this.favorite_area.pack_start(button, false, false, 0);
            this.show_all();
        }
        this.reload_position();
    }

    public void set_reveal_state(bool visible) {
        this.panel_visible = visible;
        if (!this.panel_visible) {
            this.lateral_panel_button.set_image_from_icon_name("go-previous-symbolic");
        } else {
            this.lateral_panel_button.set_image_from_icon_name("go-next-symbolic");
        }
    }

    public void reload_position() {
        string position = this.gsettings.get_string("position");
        if (position == "Top" || position == "Bottom") {
            this.box.set_orientation(Gtk.Orientation.HORIZONTAL);
            this.favorite_area.set_orientation(Gtk.Orientation.HORIZONTAL);
        } else {
            this.box.set_orientation(Gtk.Orientation.VERTICAL);
            this.favorite_area.set_orientation(Gtk.Orientation.VERTICAL);
        }
        this.reset_pos();
        this.reload_space_reserved();
    }

    private void reload_space_reserved() {
        if (!this.get_realized()) {
            return;
        }

        bool reserve = this.gsettings.get_boolean("space-reserved");
        string position = this.gsettings.get_string("position");

        int w, h;
        this.get_size(out w, out h);

        Gdk.Atom atom;
        atom = Gdk.Atom.intern("_NET_WM_STRUT_PARTIAL", false);

        var window = this.get_window();

        long struts[12];

        if (this.shown && reserve) {
            switch (position) {
                case "Top":
                    struts = { 0, 0, h, 0,
                               0, 0, 0, 0,
                               0, DISPLAY_WIDTH,
                               0, 0 };
                    break;

                case "Left":
                    struts = { w, 0, 0, 0,
                        0, DISPLAY_HEIGHT,
                        0, 0, 0, 0, 0, 0 };
                    break;

                case "Bottom":  // For some reason, it does not work properly
                    struts = { 0, 0, 0,
                        DISPLAY_HEIGHT - h,
                        0, 0, 0, 0, 0, 0,
                        0, DISPLAY_WIDTH };
                    break;
            }
        } else {
            struts = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
        }

        Gdk.property_change(window, atom, Gdk.Atom.intern("CARDINAL", false),
            32, Gdk.PropMode.REPLACE, (uint8[])struts, 12);
    }

    public void reset_pos() {
        if (this.in_transition) {
            return;
        }

        int w, h;
        this.get_size(out w, out h);
        this.shown = true;
        bool expand = this.gsettings.get_boolean("expand");
        string position = this.gsettings.get_string("position");

        if (expand) {
            switch (position) {
                case "Left":
                    this.set_size_request(1, DISPLAY_HEIGHT);
                    this.resize(1, DISPLAY_HEIGHT);
                    this.favorite_area.set_size_request(1, 20);
                    break;

                case "Top":
                    this.set_size_request(DISPLAY_WIDTH, 1);
                    this.resize(DISPLAY_WIDTH, 1);
                    this.favorite_area.set_size_request(20, 1);
                    break;

                case "Bottom":
                    this.set_size_request(DISPLAY_WIDTH, 1);
                    this.resize(DISPLAY_WIDTH, 1);
                    this.favorite_area.set_size_request(20, 1);
                    break;
            }
        } else {
            switch (position) {
                case "Left":
                    this.favorite_area.set_size_request(1, 20);
                    break;

                case "Top":
                    this.favorite_area.set_size_request(20, 1);
                    break;

                case "Bottom":
                    this.favorite_area.set_size_request(20, 1);
                    break;
            }
            this.set_size_request(1, 1);
            this.resize(1, 1);
        }

        this.get_size(out w, out h);

        if (this.shown) {
            switch(position) {
                case "Left":
                    this.move(0, !expand? DISPLAY_HEIGHT / 2 - h / 2: 0);
                    break;

                case "Top":
                    this.move(!expand? DISPLAY_WIDTH / 2 - w / 2: 0, 0);
                    break;

                case "Bottom":
                    this.move(!expand? DISPLAY_WIDTH / 2 - w / 2: 0, DISPLAY_HEIGHT - h);
                    break;
            }
        } else {
            switch(position) {
                case "Left":
                    this.move(-w, !expand? DISPLAY_HEIGHT / 2 - h / 2: 0);
                    break;

                case "Top":
                    this.move(!expand? DISPLAY_WIDTH / 2 - w / 2: 0, -h);
                    break;

                case "Bottom":
                    this.move(!expand? DISPLAY_WIDTH / 2 - w / 2: 0, DISPLAY_HEIGHT);
                    break;
            }
        }
    }
    /*
    private bool _reveal_left() {
        int x, y, w, h;
        this.get_position(out x, out y);
        this.get_size(out w, out h);

        int avance = this.gsettings.get_int("animation-step-size");

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

        int avance = this.gsettings.get_int("animation-step-size");

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

        int avance = this.gsettings.get_int("animation-step-size");

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

        switch (this.gsettings.get_string("position")) {
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

        int avance = this.gsettings.get_int("animation-step-size");

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

        int avance = this.gsettings.get_int("animation-step-size");

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

        int avance = this.gsettings.get_int("animation-step-size");

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

        switch (this.gsettings.get_string("position")) {
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
    */
    public void reveal(bool shown) {
        if (this.shown == shown) {
            return;
        }

        this.shown = shown;
        if (this.shown) {
            //this._reveal();
        } else {
            //this._disreveal();
        }
    }
}

