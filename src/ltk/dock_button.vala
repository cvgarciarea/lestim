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

namespace Ltk {

    public enum IconFrom {
        NAME,
        FILE
    }

    public class DockButton: Gtk.EventBox {

        public signal void right_click();
        public signal void left_click();

        public GLib.Settings gsettings;
        public Gtk.Box box;
        public Gtk.Image image;

        public string? icon_name = null;
        public string? icon_path = null;
        private int icon_from = IconFrom.NAME;

        public DockButton() {
            this.set_vexpand(false);
            this.set_hexpand(false);

            this.gsettings = new GLib.Settings("org.lestim.dock");
            this.gsettings.changed.connect(this.settings_changed_cb);

            this.box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            this.add(this.box);

            this.image = new Gtk.Image();
            this.box.add(this.image);

            this.button_release_event.connect(this.button_release_event_cb);
        }

        private void settings_changed_cb(GLib.Settings gsettings, string key) {
            if (key == "icon-size") {
                if (this.icon_from == IconFrom.NAME) {
                    this.set_image_from_icon_name(this.icon_name);
                } else if (this.icon_from == IconFrom.FILE) {
                    this.set_image_from_path(this.icon_path);
                }
            }
        }

        private bool button_release_event_cb(Gtk.Widget self, Gdk.EventButton event) {
            if (event.button == 1) {
                this.left_click();
            } else if (event.button == 3) {
                this.right_click();
            }

            return true;
        }

        public void set_image_from_icon_name(string name) {
            this.icon_from = IconFrom.NAME;
            this.icon_name = name;
            this.icon_path = null;
            int size = this.gsettings.get_int("icon-size");

            this.box.remove(this.image);

            this.image = get_image_from_name(this.icon_name, size);
            this.box.add(this.image);
            this.show_all();
        }

        public void set_image_from_path(string path) {
            this.icon_from = IconFrom.FILE;
            this.icon_name = null;
            this.icon_path = path;
            int size = this.gsettings.get_int("icon-size");

            this.box.remove(this.image);

            this.image = new Gtk.Image.from_pixbuf(new Gdk.Pixbuf.from_file_at_size(this.icon_path, size, size));
            this.box.add(this.image);
            this.show_all();
        }
    }

    private class ShowAppsButton: DockButton {
        public ShowAppsButton() {
            this.set_name("DockAppsButton");
            this.set_image_from_icon_name("view-grid-symbolic");
        }
    }

    private class ShowLateralPanelButton: DockButton {
        public ShowLateralPanelButton() {
            this.set_name("ShowLateralPanelButton");
            this.set_image_from_icon_name("go-previous-symbolic");
        }
    }

    public class FavoriteAppButton: DockButton {

        private Ltk.App app;

        public FavoriteAppButton(Ltk.App app) {
            this.set_name("FavoriteAppButton");

            this.app = app;
            this.set_image_from_path(this.app.get_icon_path());
            this.left_click.connect(() => {
                this.app.start();
            });
        }
    }
}
