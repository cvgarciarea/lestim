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
    public Gtk.Box vbox;
    public Gtk.Stack stack;
    public Gtk.StackSwitcher stack_switcher;

    //private bool first_background_time = true;

    public SettingsWindow() {
        set_name("SettingsWindow");
        set_title("Settings");
        resize(840, 580);

        headerbar = new Gtk.HeaderBar();
        headerbar.set_title("Settings");
        headerbar.set_show_close_button(true);
        set_titlebar(headerbar);

        vbox = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        add(vbox);

        stack = new Gtk.Stack();
        stack.set_transition_type(Gtk.StackTransitionType.SLIDE_LEFT_RIGHT);
        stack.set_transition_duration(200);
        stack.set_hexpand(true);
        vbox.pack_start(stack, true, true, 0);

        stack_switcher = new Gtk.StackSwitcher();
        stack_switcher.set_stack(stack);
        headerbar.set_custom_title(stack_switcher);

        make_backgrounds_section();
        make_panel_section();

        delete_event.connect(delete_event_cb);

        hide();
    }

    private void make_backgrounds_section() {
        Gtk.Box box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        Gtk.ScrolledWindow scrolled = new Gtk.ScrolledWindow(null, null);
        box.pack_start(scrolled, true, true, 0);

        Gtk.FlowBox fbox = new Gtk.FlowBox();
        fbox.set_homogeneous(true);
        fbox.set_selection_mode(Gtk.SelectionMode.SINGLE);
        scrolled.add(fbox);

        Gee.ArrayList<string> backgrounds = get_backgrounds();

        foreach (string x in backgrounds) {
            GLib.File file = GLib.File.new_for_path(x);
            if (file.query_exists()) {
                try {
                    Gdk.Pixbuf pixbuf = new Gdk.Pixbuf.from_file_at_size(x, 200, 100);
                    Gtk.Image image = new Gtk.Image.from_pixbuf(pixbuf);
                    fbox.add(image);
                } catch {}
            }
        }

        stack.add_titled(box, "Background", "Background");
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

    private void make_panel_section() {
        Gtk.Box box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        Gtk.Box hbox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        box.add(hbox);

        Gtk.ScrolledWindow scrolled = new Gtk.ScrolledWindow(null, null);
        scrolled.set_size_request(400, -1);
        hbox.pack_start(scrolled, true, false, 0);

        Gtk.ListBox listbox = new Gtk.ListBox();
        listbox.set_selection_mode(Gtk.SelectionMode.NONE);
        scrolled.add(listbox);

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

        stack.add_titled(box, "Panel", "Panel");
    }

    public bool delete_event_cb () {
        hide();
        return true;
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
