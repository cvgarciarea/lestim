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


public class LestimWindow: Gtk.ApplicationWindow {

    //bool panel_orientation;
    //bool panel_autohide;
    //bool panel_expand;
    //bool panel_space_reserved;

    public Gtk.Box box;
    public LestimPanel panel;
    public LateralPanel lateral_panel;

    public LestimWindow() {
        set_title("Lestim");
        set_name("LestimWindow");
        set_type_hint(Gdk.WindowTypeHint.DESKTOP);
        set_size_request(DISPLAY_WIDTH, DISPLAY_HEIGHT);
        move(0, 0);

        box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        box.set_name("Canvas");
        add(box);

        panel = new LestimPanel();
        panel.show_apps.connect(show_apps);
        panel.show_lateral_panel.connect(show_lateral_panel);

        lateral_panel = new LateralPanel();
        lateral_panel.show_settings.connect(show_settings);
        lateral_panel.reveal_changed.connect(reveal_changed);

        load_settings();
    }

    public void show_apps(LestimPanel panel) {
    }

    public void show_lateral_panel(LestimPanel _panel, bool visible) {
        lateral_panel.reveal(visible);
    }

    public void show_settings(LateralPanel _panel) {
    }

    public void reveal_changed(LateralPanel _panel, bool visible) {
        panel.set_reveal_state(visible);
    }

    public void load_settings() {
        var object = get_config();
        panel.set_orientation(object.get_string_member("panel-orientation"));
        panel.set_icon_size((int)object.get_int_member("icon-size"));
    }
}
