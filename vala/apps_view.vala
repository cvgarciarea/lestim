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
/*
public class GMenuManager {

    public List<GMenu.TreeDirectory> get_categories() {
        var tree = GMenu.Tree.lookup("applications.menu", GMenu.TreeFlags.INCLUDE_EXCLUDED);
        var root = tree.get_root_directory();
        var dirs = new List<GMenu.TreeDirectory>();

        foreach (GMenu.TreeItem item in root.get_contents()) {
            if (item.get_type() == GMenu.TreeItemType.DIRECTORY) {
                dirs.append((GMenu.TreeDirectory) item);
            }
        }
        return dirs;
    }

    public List<GMenu.TreeEntry> get_entries_flat(GMenu.TreeDirectory directory) {
        var entries = new List<GMenu.TreeEntry>();

        foreach (GMenu.TreeItem item in directory.get_contents()) {
            switch (item.get_type()) {
            case GMenu.TreeItemType.DIRECTORY:
                entries.concat (get_entries_flat((GMenu.TreeDirectory) item));
                break;
            case GMenu.TreeItemType.ENTRY:
                entries.append((GMenu.TreeEntry) item);
                break;
            }
        }
        return entries;
    }

    public DesktopAppInfo get_desktop_app_info(GMenu.TreeEntry entry) {
        return new DesktopAppInfo.from_filename(entry.get_desktop_file_path());
    }

    /* Launch an application described in DesktopAppInfo *//*
    public void launch_desktop_app_info(DesktopAppInfo info) {
        try {
            info.launch(null, new AppLaunchContext());
        } catch (Error error) {}
    }
}
*/
public class AppsView: Gtk.Window {

    public bool shown = false;

    public LestimWindow parent;
    public Gtk.Box vbox;
    public Gtk.Entry entry;
    public Gtk.FlowBox grid;

    //public GMenuManager apps_manager;

    public AppsView(LestimWindow _parent) {
        parent = _parent;
        //apps_manager = new GMenuManager();

        set_name("AppsView");

        set_transient_for(parent);
        //set_modal(true);
        set_can_focus(true);
        set_border_width(10);
        set_keep_above(true);
        set_decorated(false);

        vbox = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        vbox.set_name("AppsBox");
        add(vbox);

        entry = new AppsEntry();
        entry.changed.connect(search_app);
        vbox.pack_start(entry, false, false, 20);

        Gtk.ScrolledWindow scrolled = new Gtk.ScrolledWindow(null, null);
        vbox.pack_start(scrolled, true, true, 0);

        grid = new Gtk.FlowBox();
        grid.set_name("AppsGrid");
        grid.set_selection_mode(Gtk.SelectionMode.NONE);
        grid.set_homogeneous(true);
        scrolled.add(grid);

        focus_out_event.connect(focus_out_event_cb);

        //show_apps();
        hide();
    }

    private bool focus_out_event_cb() {
        reveal(false);
        return true;
    }

    public void reveal(bool _visible) {
        if (_visible == shown) {
            return;
        }

        shown = _visible;

        if (shown) {
            entry.set_text("");

            int x, y, w, h;
            parent.panel.get_position(out x, out y);
            parent.panel.get_size(out w, out h);

            if (parent.panel.orientation == "Left") {
                move(w + 10, 0);
                set_size_request(DISPLAY_WIDTH - w - 10, DISPLAY_HEIGHT);
                resize(DISPLAY_WIDTH - w - 10, DISPLAY_HEIGHT);
            } else {
                set_size_request(DISPLAY_WIDTH, DISPLAY_HEIGHT - h - 10);
                resize(DISPLAY_WIDTH, DISPLAY_HEIGHT - h - 10);
                if (parent.panel.orientation == "Top") {
                    move(0, h + 10);
                } else {
                    move(0, 0);
                }
            }

            show_all();
            entry.grab_focus();
        } else {
            hide();
        }
    }

    public void show_apps(string search="") {
        /*foreach (var button in grid.get_children()) {
            grid.remove(button);
        }

        var categories = apps_manager.get_categories();

        foreach (var category in categories) {
            var entries = apps_manager.get_entries_flat(category);
            foreach (var entry in entries) {
                var app_info = apps_manager.get_desktop_app_info(entry);
                if (app_info != null) {
                    if (app_info.get_icon() != null) {
                        if (search == "" || search.down() in app_info.get_name().down()) {
                            Gtk.Button button = new AppButton(app_info, true);
                            grid.add(button);
                        }
                    }
                }
            }
        }

        foreach (var child in grid.get_children()) {
            child.set_vexpand_set(true);
            child.set_vexpand(false);
        }

        show_all();
    */
    }

    private void search_app(Gtk.Editable _entry) {
        show_apps(entry.get_text());
    }
}
