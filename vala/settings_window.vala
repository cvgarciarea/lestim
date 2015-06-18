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

    public signal void settings_changed();

    public Gtk.HeaderBar headerbar;
    public Gtk.Box hbox;
    public Gtk.ListBox listbox;
    public Gtk.Box box_switcher;
    public Gtk.Box current_child;

    //private bool first_background_time = true;

    public SettingsWindow() {
        set_name("SettingsWindow");
        set_title("Settings");
        set_icon_name("preferences-desktop");
        set_position(Gtk.WindowPosition.CENTER);
        resize(840, 580);

        headerbar = new Gtk.HeaderBar();
        headerbar.set_title("Settings");
        headerbar.set_show_close_button(true);
        set_titlebar(headerbar);

        hbox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        add(hbox);

        Gtk.ScrolledWindow scrolled = new Gtk.ScrolledWindow(null, null);
        scrolled.set_size_request(200, -1);
        hbox.pack_start(scrolled, false, false, 0);

        listbox = new Gtk.ListBox();
        listbox.set_selection_mode(Gtk.SelectionMode.SINGLE);
        listbox.row_activated.connect(row_activated_cb);
        scrolled.add(listbox);

        box_switcher = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        hbox.pack_start(box_switcher, true, true, 5);

        Gtk.Box child = make_panel_section();
        current_child = child;
        box_switcher.add(child);
        add_section("Panel", "user-home-symbolic", child);
        child.show_all();

        child = make_backgrounds_section();
        add_section("Background", "preferences-desktop-wallpaper-symbolic", child);

        delete_event.connect(delete_event_cb);

        hide();
    }

    public void add_section(string name, string icon, Gtk.Box child) {
        Gtk.ListBoxRow row = new Gtk.ListBoxRow();
        Gtk.Box box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        Gtk.Label label = new Gtk.Label(null);
        var image = get_image_from_name(icon);

        row.set_data("stack-child", child);
        label.set_markup("<b>" + name + "</b>");

        box.pack_start(image, false, false, 2);
        box.pack_start(label, false, false, 0);
        row.add(box);
        listbox.add(row);
    }

    private void row_activated_cb(Gtk.ListBox listbox, Gtk.ListBoxRow row) {
        if (row == null) {
            return;
        }

        box_switcher.remove(current_child);
        current_child = row.get_data("stack-child");
        box_switcher.add(row.get_data("stack-child"));
        show_all();
    }

    private void background_changed(Gtk.FlowBox fbox, Gtk.FlowBoxChild child) {
        if (child == null) {
            return;
        }

        var image = child.get_child();
        set_wallpaper(image.get_data("image-path"));
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

        Gtk.Box hbox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        hbox.set_border_width(10);
        hbox.pack_start(new Gtk.Label(label), false, false, 0);
        row.add(hbox);

        listbox.add(row);

        return hbox;
    }

    private Gtk.Box make_panel_section() {
        Gtk.Box box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);

        Gtk.ListBox listbox = new Gtk.ListBox();
        listbox.set_selection_mode(Gtk.SelectionMode.NONE);
        box.add(listbox);

        var box1 = make_row(listbox, "Orientation");
        Gtk.ComboBoxText combo = new Gtk.ComboBoxText();
        combo.append_text("Top");
        combo.append_text("Bottom");
        combo.append_text("Left");
        //combo.set_active({'Top': 0, 'Bottom': 1, 'Left': 2}[settings['panel-orientation']])
        //combo.connect('changed', self.panel_orientation_changed)
        box1.pack_end(combo, false, false, 0);

        var box2 = make_row(listbox, "Autohide");
        Gtk.Switch switch1 = new Gtk.Switch();
        //switch1.set_active(settings['panel-autohide'])
        //switch1.connect('notify::active', self.panel_autohide_changed)
        box2.pack_end(switch1, false, false, 0);

        var box3 = make_row(listbox, "Expand");
        Gtk.Switch switch2 = new Gtk.Switch();
        //switch2.set_active(settings['panel-expand'])
        //switch2.connect('notify::active', self.panel_expand_changed)
        box3.pack_end(switch2, false, false, 0);

        var box4 = make_row(listbox, "Reserve screen space");
        Gtk.Switch switch3 = new Gtk.Switch();
        //switch3.set_active(settings['panel-space-reserved'])
        //switch3.connect('notify::active', self.panel_reserve_space_changed)
        box4.pack_end(switch3, false, false, 0);

        return box;
    }

    public bool delete_event_cb () {
        hide();
        return true;
    }

    public void reveal() {
        show_all();
        current_child.show_all();
    }
}
/*
        box.connect('selected-children-changed', self.background_changed)
        scrolled.add(box)

        backgrounds = G.get_backgrounds()


    def make_panel_section(self):

        settings = G.get_settings()

        self.stack.add_titled(vbox, 'panel', 'Panel')

    def background_changed(self, widget):
        if widget.first_time:
            widget.first_time = False
            widget.unselect_all()
            return

        if widget.get_selected_children():
            image = widget.get_selected_children()[0].get_children()[0]
            file = image.file

            if os.path.isfile(file):
                GObject.idle_add(G.set_background, file, True)

    def panel_orientation_changed(self, combo):
        values = {0: 'Top', 1: 'Bottom', 2: 'Left'}
        value = values[combo.get_active()]
        G.set_a_setting('panel-orientation', value)
        self.emit('settings-changed')

    def panel_autohide_changed(self, switch, gparam):
        G.set_a_setting('panel-autohide', switch.get_active())
        self.emit('settings-changed')

    def panel_expand_changed(self, switch, gparam):
        G.set_a_setting('panel-expand', switch.get_active())
        self.emit('settings-changed')

    def panel_reserve_space_changed(self, switch, gparam):
        G.set_a_setting('panel-space-reserved', switch.get_active())
        self.emit('settings-changed')
*/
