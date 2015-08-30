/*

     Extracted from https://github.com/AnsgarKlein/Rocket-Launcher
     Great proyect!!!

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

    Adapted for Lestim by Cristian García <cristian99garcia@gmail.com>

*/

class AppsView: Gtk.Window {

    private Ltk.AppGrid app_grid;
    private Ltk.CategoryButton[] category_buttons;
    private Gtk.ScrolledWindow scrolled;
    private Gtk.Entry search_entry;

    private Ltk.AppIcon[] app_icons;
    private Ltk.ApplicationHandler application_handler;

    private const int border_size = 25;

    public AppsView() {
        Object(type: Gtk.WindowType.TOPLEVEL);

        // Set application icon
        set_application_icon();

        // Refresh application icon if style changes
        base.style_set.connect(set_application_icon);

        // Create ApplicationHandler
        application_handler = new Ltk.ApplicationHandler();

        Ltk.App[] apps = application_handler.get_apps();

        this.app_icons = new Ltk.AppIcon[apps.length];
        for (int i = 0; i < apps.length; i++) {
            Ltk.AppIcon appicon = new Ltk.AppIcon(apps[i]);
            appicon.started.connect(() => {
                this.hide_Window();
            });
            app_icons[i] = appicon;
        }

        // Setup Gui
        build_gui();

        //Setup Signals

        // Refresh AppGrid if selection of apps to show changed
        application_handler.selection_changed.connect(() => {
            // Receive indices for apps to add
            int[] selection = application_handler.get_selected_apps();

            // Remove all elements from AppGrid
            app_grid.clear();

            // Add selected apps back to AppGrid
            for (int i = 0; i < selection.length; i++) {
                app_grid.add(app_icons[selection[i]]);
            }
        });

        // Hide window on delete_event (don't delete it)
        this.delete_event.connect(() => {
            hide_Window();
            return true;
        });

        // Hide window if escape is pressed
        base.key_press_event.connect((k) => {
            if (Gdk.Key.Escape == k.keyval) {
                hide_Window();
                return true;
            } else {
                return false;
            }
        });

        // Hide window if it loses focus
        base.focus_out_event.connect(() => {
            hide_Window();
            return true;
        });
    }

    private void set_application_icon() {
        try {
            base.set_icon(Gtk.IconTheme.get_default().load_icon(Constants.application_icon, 256, 0));
        } catch (Error e) {
            try {
                base.set_icon(Gtk.IconTheme.get_default().load_icon(Constants.fallback_icon, 256, 0));
            } catch (Error e) {
            }
        }
    }

    private void build_gui() {
        base.set_title(Constants.application_name);
        base.set_position(Gtk.WindowPosition.CENTER);
        base.set_decorated(false);
        base.set_keep_above(true);
        base.stick();
        base.set_deletable(false);
        base.set_skip_taskbar_hint(true);
        base.set_has_resize_grip(false);
        base.set_default_size(750, 600);
        base.set_border_width(border_size);

        // Prerequesites for transparency and cairo drawing in general
        base.set_app_paintable(true);
        base.set_visual(screen.get_rgba_visual());

        // On draw event: draw window semi transparent
        base.draw.connect(on_draw);

        // Create main grid
        Gtk.Grid outer_grid = new Gtk.Grid();
        outer_grid.set_column_homogeneous(false);
        outer_grid.set_row_homogeneous(false);

        // Create scrolled area
        scrolled = new Gtk.ScrolledWindow(null, null);
        scrolled.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
        outer_grid.attach(scrolled, 0, 0, 1, 2);

        // Create AppGrid
        app_grid = new Ltk.AppGrid();
        foreach (Ltk.AppIcon app_icon in app_icons) {
            app_grid.add(app_icon);
        }
        app_grid.set_hexpand(true);
        scrolled.add_with_viewport(app_grid);

        // Create search entry
        search_entry = new Gtk.Entry();
        search_entry.activate.connect(() => {
            application_handler.filter_string(search_entry.get_text());
        });
        search_entry.changed.connect(() => {
            // Deactivate all category buttons
            foreach (Ltk.CategoryButton ctbtn in category_buttons) {
                ctbtn.set_active(false);
            }

            // Filter applications
            string text = search_entry.get_text();
            if (text == "") {
                application_handler.filter_all();
            } else {
                application_handler.filter_string(text);
            }
        });
        outer_grid.attach(search_entry, 1, 0, 1, 1);

        // Create category buttons
        Gtk.Box button_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        button_box.set_spacing(1);
        button_box.set_vexpand(true);
        outer_grid.attach(button_box, 1, 1, 1, 1);

        category_buttons = new Ltk.CategoryButton[Constants.category_button_count];
        for (int i = 0; i < Constants.category_button_count; i++) {
            Ltk.CategoryButton category_button;
            category_button = new Ltk.CategoryButton(Constants.category_button_names[i],
                                                 Constants.category_button_values[i]);

            category_button.set_relief(Gtk.ReliefStyle.NONE);
            category_button.category_button_press_event.connect((category) => {
                // Reset entry text
                search_entry.set_text("");

                // Deactivate all other category buttons
                foreach (Ltk.CategoryButton ctbtn in category_buttons) {
                    ctbtn.set_active(false);
                }

                // Filter applications
                application_handler.filter_categorie(category);
            });

            button_box.add(category_button);
            category_buttons[i] = category_button;
        }


        this.add(outer_grid);
    }

    public void toggle_visibiliy() {
        if (this.get_visible()) {
            hide_Window();
        } else {
            show_Window();
            this.search_entry.grab_focus();
            this.activate_focus();
        }
    }

    public void show_Window() {
        //Show the application window
        this.show_all();
    }

    public void hide_Window() {
        // Hide the application window

        // Make sure the window looks exactly as if the application
        // had just started.
        // We do all this before we hide the window and not before we
        // show it again! (To reduce time to show window)
        application_handler.filter_all();
        scrolled.get_vadjustment().set_value(0);
        search_entry.set_text("");
        search_entry.grab_focus();

        this.hide();
    }

    public void exit_program() {
        // Kill the Gtk loop which is the main loop of the
        // application at the same time
        // ==> we quit the application
        Gtk.main_quit();
    }

    private bool on_draw(Cairo.Context ctx) {
        // Draw everywhere on window
        ctx.set_source_rgba(Constants.bg_color[0], Constants.bg_color[1],
                            Constants.bg_color[2], Constants.bg_color[3]);
        ctx.set_operator(Cairo.Operator.SOURCE);
        ctx.paint();

        return false;
    }
}

