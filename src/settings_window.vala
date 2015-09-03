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

public class SettingsWindow: Gtk.Window {

    public signal void change_background(string path);

    public GLib.Settings dock_settings;
    public GLib.Settings panel_settings;

    public Gtk.HeaderBar headerbar;
    public Gtk.Box hbox;
    public Gtk.ListBox listbox;
    public Gtk.Box box_switcher;
    public Gtk.Box current_child;

    public Gtk.RadioButton l_rbutton;
    public Gtk.RadioButton b_rbutton;
    public Gtk.RadioButton t_rbutton;
    public Gtk.Switch switch_autohide;
    public Gtk.Switch switch_expand;
    public Gtk.Switch switch_reserve;
    public Gtk.SpinButton spin_icon;
    public Gtk.SpinButton spin_step;
    public Gtk.SpinButton spin_dock_transparency;
    public Gtk.SpinButton spin_panel_transparency;

    public SettingsWindow() {
        this.set_name("SettingsWindow");
        this.set_title("Settings");
        this.set_icon_name("preferences-desktop");
        this.set_position(Gtk.WindowPosition.CENTER);
        this.resize(840, 580);

        this.dock_settings = new GLib.Settings("org.lestim.dock");
        this.dock_settings.changed.connect(this.dock_settings_changed);

        this.panel_settings = new GLib.Settings("org.lestim.panel");
        this.panel_settings.changed.connect(this.panel_settings_changed);

        this.headerbar = new Gtk.HeaderBar();
        this.headerbar.set_title("Settings");
        this.headerbar.set_show_close_button(true);
        this.set_titlebar(this.headerbar);

        this.hbox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        this.add(this.hbox);

        this.listbox = new Gtk.ListBox();
        this.listbox.set_border_width(20);
        this.listbox.set_selection_mode(Gtk.SelectionMode.SINGLE);
        this.listbox.row_activated.connect(row_activated_cb);
        this.hbox.pack_start(this.listbox, false, false, 0);

        this.box_switcher = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        this.hbox.pack_start(this.box_switcher, true, true, 5);

        Gtk.Box child = make_dock_section();
        this.current_child = child;
        this.box_switcher.add(child);
        this.add_section("Dock", "user-home-symbolic", child);

        child = make_panel_section();
        this.add_section("Panel", "go-last-symbolic", child);  // Temporary icon

        child = make_backgrounds_section();
        this.add_section("Background", "preferences-desktop-wallpaper-symbolic", child);

        this.show.connect(this.show_cb);
        this.delete_event.connect(this.delete_event_cb);

        this.current_child.show_all();
        this.hide();
    }

    public void show_cb(Gtk.Widget self) {
        this.update_dock_widgets();
        this.update_panel_widgets();
    }

    public bool delete_event_cb() {
        this.hide();
        return true;
    }

    public void add_section(string name, string icon, Gtk.Box child) {
        Gtk.ListBoxRow row = new Gtk.ListBoxRow();
        Gtk.Box box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        Gtk.Label label = new Gtk.Label(null);
        var image = get_image_from_name(icon);

        row.set_data("stack-child", child);
        label.set_markup("<b><big>" + name + "</big></b>");

        box.pack_start(image, false, false, 2);
        box.pack_start(label, false, false, 0);
        row.add(box);
        this.listbox.add(row);
    }

    private void row_activated_cb(Gtk.ListBox listbox, Gtk.ListBoxRow row) {
        if (row == null) {
            return;
        }

        this.box_switcher.remove(this.current_child);
        this.current_child = row.get_data("stack-child");
        this.box_switcher.add(row.get_data("stack-child"));
        this.show_all();
    }

    private void background_changed(Gtk.FlowBox fbox, Gtk.FlowBoxChild child) {
        if (child == null) {
            return;
        }

        var image = child.get_child();
        this.change_background(image.get_data("image-path"));
    }

    private Gtk.Box make_backgrounds_section() {
        Gtk.Box box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        Gtk.ScrolledWindow scrolled = new Gtk.ScrolledWindow(null, null);
        scrolled.set_hexpand(true);
        scrolled.set_vexpand(true);
        box.add(scrolled);

        Gtk.FlowBox fbox = new Gtk.FlowBox();
        fbox.set_homogeneous(true);
        fbox.set_selection_mode(Gtk.SelectionMode.SINGLE);
        fbox.set_row_spacing(5);
        fbox.set_column_spacing(5);
        fbox.set_border_width(10);
        fbox.child_activated.connect(background_changed);
        scrolled.add(fbox);

        Gee.ArrayList<string> backgrounds = get_backgrounds();

        foreach (string x in backgrounds) {
            GLib.File file = GLib.File.new_for_path(x);
            if (file.query_exists()) {
                try {
                    Gdk.Pixbuf pixbuf = new Gdk.Pixbuf.from_file_at_size(x, 200, 100);
                    if (pixbuf.get_width() != 200 || pixbuf.get_height() != 100) {
                        pixbuf = pixbuf.scale_simple(200, 100, Gdk.InterpType.BILINEAR);
                    }

                    Gtk.Image image = new Gtk.Image.from_pixbuf(pixbuf);
                    image.set_data("image-path", x);
                    fbox.add(image);
                } catch {}
            }
        }

        return box;
    }

    private Gtk.Box make_row(Gtk.ListBox listbox, string label) {
        Gtk.ListBoxRow row = new Gtk.ListBoxRow();

        Gtk.Box box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        box.set_border_width(10);
        box.pack_start(new Gtk.Label(label), false, false, 0);
        row.add(box);

        listbox.add(row);

        return box;
    }

    private Gtk.Box make_panel_section() {
        Gtk.Box box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);

        Gtk.ListBox listbox = new Gtk.ListBox();
        listbox.set_selection_mode(Gtk.SelectionMode.NONE);
        box.add(listbox);

        var box1 = this.make_row(listbox, "Transparency");
        Gtk.Adjustment adj1 = new Gtk.Adjustment(1, 0, 9, 1, 2, 0);
        this.spin_panel_transparency = new Gtk.SpinButton(adj1, 0, 0);
        this.spin_panel_transparency.value_changed.connect(this.transparency_panel_changed);
        box1.pack_end(this.spin_panel_transparency, false, false, 0);

        return box;
    }

    private Gtk.Box make_dock_section() {
        Gtk.Box box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);

        Gtk.ListBox listbox = new Gtk.ListBox();
        listbox.set_selection_mode(Gtk.SelectionMode.NONE);
        box.add(listbox);

        var box1 = this.make_row(listbox, "Position");
        Gtk.ButtonBox bbox = new Gtk.ButtonBox(Gtk.Orientation.HORIZONTAL);
        bbox.set_layout(Gtk.ButtonBoxStyle.SPREAD);
        box1.pack_end(bbox, true, true, 0);

        this.l_rbutton = new Gtk.RadioButton.with_label_from_widget(null, "Left");
        this.l_rbutton.toggled.connect(this.panel_position_changed);
        bbox.add(this.l_rbutton);

        this.t_rbutton = new Gtk.RadioButton.with_label_from_widget(l_rbutton, "Top");
        this.t_rbutton.toggled.connect(this.panel_position_changed);
        bbox.add(this.t_rbutton);

        this.b_rbutton = new Gtk.RadioButton.with_label_from_widget(l_rbutton, "Bottom");
        this.b_rbutton.toggled.connect(this.panel_position_changed);
        bbox.add(this.b_rbutton);

        var box2 = this.make_row(listbox, "Autohide");
        this.switch_autohide = new Gtk.Switch();
        this.switch_autohide.notify["active"].connect(this.panel_autohide_changed);
        box2.pack_end(this.switch_autohide, false, false, 0);

        var box3 = this.make_row(listbox, "Expand");
        this.switch_expand = new Gtk.Switch();
        this.switch_expand.notify["active"].connect(this.panel_expand_changed);
        box3.pack_end(this.switch_expand, false, false, 0);

        var box4 = this.make_row(listbox, "Reserve screen space");
        this.switch_reserve = new Gtk.Switch();
        this.switch_reserve.notify["active"].connect(this.panel_reserve_space_changed);
        box4.pack_end(this.switch_reserve, false, false, 0);

        var box5 = this.make_row(listbox, "Icon size");
        Gtk.Adjustment adj1 = new Gtk.Adjustment(15, 15, 200, 1, 10, 0);
        this.spin_icon = new Gtk.SpinButton(adj1, 0, 0);
        this.spin_icon.value_changed.connect(this.icon_size_changed);
        box5.pack_end(this.spin_icon, false, false, 0);

        var box6 = this.make_row(listbox, "Animation step size(px)");
        Gtk.Adjustment adj2 = new Gtk.Adjustment(1, 1, 50, 1, 10, 0);
        this.spin_step = new Gtk.SpinButton(adj2, 0, 0);
        this.spin_step.value_changed.connect(this.step_size_changed);
        box6.pack_end(this.spin_step, false, false, 0);

        var box7 = this.make_row(listbox, "Background transparency");
        Gtk.Adjustment adj3 = new Gtk.Adjustment(0, 0, 10, 1, 2, 0);
        this.spin_dock_transparency = new Gtk.SpinButton(adj3, 0, 0);
        this.spin_dock_transparency.value_changed.connect(this.transparency_dock_changed);
        box7.pack_end(this.spin_dock_transparency, false, false, 0);

        return box;
    }

    public void reveal() {
        this.show_all();
        this.current_child.show_all();
    }

    public void transparency_panel_changed(Gtk.SpinButton spin) {
        this.panel_settings.set_int("background-transparency", (int)this.spin_panel_transparency.get_value());
    }

    public void transparency_dock_changed(Gtk.SpinButton spin) {
        this.dock_settings.set_int("background-transparency", (int)this.spin_dock_transparency.get_value());
    }

    private void panel_position_changed(Gtk.ToggleButton rbutton) {
        if (!rbutton.get_active()) {
            return;
        }

        string position = rbutton.get_label();
        string actual = this.dock_settings.get_string("position");
        if (actual != position) {
            this.dock_settings.set_string("position", position);
        }
    }

    private void panel_autohide_changed(GLib.Object switcher, GLib.ParamSpec pspec) {
        bool active = this.switch_autohide.get_active();
        if (this.dock_settings.get_boolean("autohide") != active) {
            this.dock_settings.set_boolean("autohide", active);
        }
    }

    private void panel_expand_changed(GLib.Object switcher, GLib.ParamSpec pspec) {
        bool active = this.switch_expand.get_active();
        if (this.dock_settings.get_boolean("expand") != active) {
            this.dock_settings.set_boolean("expand", active);
        }
    }

    private void panel_reserve_space_changed(GLib.Object switcher, GLib.ParamSpec pspec) {
        bool active = this.switch_reserve.get_active();
        if (this.dock_settings.get_boolean("space-reserved") != active) {
            this.dock_settings.set_boolean("space-reserved", active);
        }
    }

    private void icon_size_changed(Gtk.SpinButton spin) {
        int size = (int)this.spin_icon.get_value();
        if (this.dock_settings.get_int("icon-size") != size) {
            this.dock_settings.set_int("icon-size", size);
        }
    }

    private void step_size_changed(Gtk.SpinButton spin) {
        int size = (int)this.spin_step.get_value();
        if (this.dock_settings.get_int("animation-step-size") != size) {
            this.dock_settings.set_int("animation-step-size", size);
        }
    }

    public void dock_settings_changed(GLib.Settings settings, string key) {
        this.update_dock_widgets(key);
    }

    public void panel_settings_changed(GLib.Settings settings, string key) {
        this.update_panel_widgets(key);
    }

    public void update_dock_widgets(string? key=null) {
        if (key != null) {
            switch (key) {
                case "icon-size":
                    this.spin_icon.set_value(this.dock_settings.get_int("icon-size"));
                    break;

                case "position":
                    switch (this.dock_settings.get_string("position")) {
                        case "Left":
                            this.l_rbutton.set_active(true);
                            break;

                        case "Bottom":
                            this.b_rbutton.set_active(true);
                            break;

                        case "Top":
                            this.t_rbutton.set_active(true);
                            break;

                        default:
                            this.l_rbutton.set_active(true);
                            break;
                    }
                    break;

                case "autohide":
                    this.switch_autohide.set_active(this.dock_settings.get_boolean("autohide"));
                    break;

                case "expand":
                    this.switch_expand.set_active(this.dock_settings.get_boolean("expand"));
                    break;

                case "space-reserved":
                    this.switch_reserve.set_active(this.dock_settings.get_boolean("space-reserved"));
                    break;

                case "animation-step-size":
                    this.spin_step.set_value(this.dock_settings.get_int("animation-step-size"));
                    break;

                case "background-transparency":
                    this.spin_dock_transparency.set_value(this.dock_settings.get_int("background-transparency"));
                    break;
            }
        } else {
            this.spin_icon.set_value(this.dock_settings.get_int("icon-size"));
            this.switch_autohide.set_active(this.dock_settings.get_boolean("autohide"));
            this.switch_expand.set_active(this.dock_settings.get_boolean("expand"));
            this.switch_reserve.set_active(this.dock_settings.get_boolean("space-reserved"));
            this.spin_step.set_value(this.dock_settings.get_int("animation-step-size"));
            this.spin_dock_transparency.set_value(this.dock_settings.get_int("background-transparency"));
            switch (this.dock_settings.get_string("position")) {
                case "Left":
                    this.l_rbutton.set_active(true);
                    break;

                case "Bottom":
                    this.b_rbutton.set_active(true);
                    break;

                case "Top":
                    this.t_rbutton.set_active(true);
                    break;

                default:
                    this.l_rbutton.set_active(true);
                    break;
            }
        }
    }

    public void update_panel_widgets(string? key=null) {
        if (key != null) {
            switch (key) {
                case "background-transparency":
                    this.spin_panel_transparency.set_value(this.panel_settings.get_int("background-transparency"));
                    break;
            }
        } else {
            this.spin_panel_transparency.set_value(this.panel_settings.get_int("background-transparency"));
        }
    }
}

