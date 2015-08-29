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

private class AppsEntry: Gtk.Entry {

    public AppsEntry() {
        set_name("AppsEntry");
        set_placeholder_text("Search...");
        set("xalign", 0.015);
    }
}

public class AppsView: Gtk.Window {

    public bool shown = false;

    public GLib.Settings gsettings;

    public LestimDock dock;
    public Gtk.Box vbox;
    public Gtk.Entry entry;
    public Gtk.FlowBox grid;

    //public GMenuManager apps_manager;

    public AppsView(LestimDock dock) {
        this.set_name("AppsView");
        //this.set_modal(true);
        this.set_can_focus(true);
        this.set_border_width(10);
        this.set_keep_above(true);
        this.set_decorated(false);

        this.dock = dock;
        this.gsettings = new GLib.Settings("org.lestim.dock");

        //this.apps_manager = new GMenuManager();

        this.vbox = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        this.vbox.set_name("AppsBox");
        this.add(this.vbox);

        this.entry = new AppsEntry();
        this.entry.changed.connect(search_app);
        this.vbox.pack_start(this.entry, false, false, 20);

        Gtk.ScrolledWindow scrolled = new Gtk.ScrolledWindow(null, null);
        this.vbox.pack_start(scrolled, true, true, 0);

        this.grid = new Gtk.FlowBox();
        this.grid.set_name("AppsGrid");
        this.grid.set_selection_mode(Gtk.SelectionMode.NONE);
        this.grid.set_homogeneous(true);
        scrolled.add(this.grid);

        this.focus_out_event.connect(this.focus_out_event_cb);

        this.hide();
    }

    private bool focus_out_event_cb() {
        this.reveal(false);
        return true;
    }

    public void reveal(bool visible) {
        if (this.shown == visible) {
            return;
        }

        this.shown = visible;

        if (this.shown) {
            this.entry.set_text("");

            string position = this.gsettings.get_string("position");
            int x, y, w, h;
            this.dock.get_position(out x, out y);
            this.dock.get_size(out w, out h);

            if (position == "Left") {
                this.move(w + 10, 0);
                this.set_size_request(DISPLAY_WIDTH - w - 10, DISPLAY_HEIGHT);
                this.resize(DISPLAY_WIDTH - w - 10, DISPLAY_HEIGHT);
            } else {
                this.set_size_request(DISPLAY_WIDTH, DISPLAY_HEIGHT - h - 10);
                this.resize(DISPLAY_WIDTH, DISPLAY_HEIGHT - h - 10);
                if (position == "Top") {
                    this.move(0, h + 10);
                } else {
                    this.move(0, 0);
                }
            }

            this.show_all();
            this.entry.grab_focus();
        } else {
            this.hide();
        }
    }

    public void show_apps(string search="") {
        // Get apps from GMenuManager
        this.show_all();
    }

    private void search_app(Gtk.Editable entry) {
        this.show_apps(this.entry.get_text());
    }
}

