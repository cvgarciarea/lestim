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

private class Calendar: Gtk.Calendar {
    public Calendar() {
        set_name("LateralCalendar");
    }
}

private class CalendarItem: Gtk.Box {
    public Gtk.Label time_label;
    public Gtk.Label day_label;
    public Gtk.Revealer revealer;
    public Calendar calendar;

    private DateTime time;
    private int day;

    public bool show_seconds = false;

    public CalendarItem() {
        set_orientation(Gtk.Orientation.VERTICAL);
        set_name("CalendarItem");

        Gtk.EventBox box1 = new Gtk.EventBox();
        box1.button_release_event.connect(show_calendar);
        pack_start(box1, false, false, 0);

        time_label = new Gtk.Label("");
        time_label.set_name("TimeLabel");
        box1.add(time_label);

        Gtk.EventBox box2 = new Gtk.EventBox();
        box2.button_release_event.connect(show_calendar);
        pack_start(box2, false, false, 0);

        day_label = new Gtk.Label("");
        day_label.set_name("DayLabel");
        box2.add(day_label);

        revealer = new Gtk.Revealer();
        revealer.set_reveal_child(false);
        pack_start(revealer, false, false, 0);

        calendar = new Calendar();
        revealer.add(calendar);

        time = new DateTime.now_local();

        GLib.Timeout.add(1000, () => {update_clock(); return true;});
    }

    public bool show_calendar(Gtk.Widget box, Gdk.EventButton event) {
        revealer.set_reveal_child(!revealer.get_child_revealed());
        return true;
    }

    protected bool update_clock() {
        time = new DateTime.now_local();
        int current_day = time.get_day_of_month();
        int current_month = time.get_month();
        int current_year = time.get_year();
        string format = "%H:%M";
        string date = "%d/%d/%d".printf(current_day, current_month, current_year);

        time_label.set_label(time.format(format + (show_seconds ? ":%S": "")));
        day_label.set_label(date);

        return true;
    }
}

private class MonitorsItem: Gtk.Box {
    public Gtk.Box network_item;
    public Gtk.Box battery_item;
    public Gtk.Label network_label;
    public Gtk.Label battery_label;

    public string battery_state = "";
    public int battery_percentage = 0;

    private string battery_path = "/sys/class/power_supply/BAT1/status";

    public MonitorsItem() {
        set_orientation(Gtk.Orientation.HORIZONTAL);

        GLib.File file = GLib.File.new_for_path(battery_path);
        if (file.query_exists()) {
            make_battery_item();
        }

        network_item = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        network_item.pack_start(get_image("network-wireless-signal-excellent-symbolic"), true, true, 10);
        pack_start(network_item);

        network_label = new Gtk.Label("");
        network_item.pack_start(network_label, false, false, 0);
    }

    private void make_battery_item() {
        battery_item = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        battery_item.pack_start(get_image("battery-symbolic"), true, true, 10);
        pack_start(battery_item, true, true, 0);

        battery_label = new Gtk.Label("0%");
        battery_item.pack_end(battery_label, false, false, 0);

        GLib.Timeout.add(1000, () => {
            GLib.File file = GLib.File.new_for_path(battery_path);
            if (!file.query_exists()) {
                return false;
            }

            check_battery_state();
            check_battery_percentage();
            return true;
        });
    }

    private void check_battery_state() {
        string status;
        FileUtils.get_contents(battery_path, out status);
        status = status.replace("\n", "");
        if (status != battery_state && status != "Unknown") {
            //battery_state = status;
            //battery_label.set_label(battery_state);
        }
    }

    private void check_battery_percentage() {
        int percentage = 0;

        if (percentage != battery_percentage) {
            battery_percentage = percentage;
            battery_label.set_label((string)percentage + "%");
        }
    }
}

public class LateralPanel: Gtk.Window {

    public signal void reveal_changed(bool visible);
    public signal void power_off();
    public signal void reboot();
    public signal void lock_screen();
    public signal void show_settings();

    public bool shown = false;
    public int last_position = DISPLAY_WIDTH;
    public int volume = 0;
    public int brightness = 0;

    public Gtk.Box vbox;
    public Gtk.Box monitors;
    public Gtk.Box hbox_volume;
    public Gtk.Box hbox_brightness;

    public LateralPanel() {
        move(DISPLAY_WIDTH, 0);
        set_keep_above(true);
        set_size_request(300, DISPLAY_HEIGHT);
        set_type_hint(Gdk.WindowTypeHint.DND);
        set_name("LateralPanel");

        vbox = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        add(vbox);

        CalendarItem calendar = new CalendarItem();
        vbox.pack_start(calendar, false, false, 10);

        monitors = new MonitorsItem();
        vbox.pack_start(monitors, false, false, 0);

        Gtk.Scale scale_v = new Gtk.Scale.with_range(Gtk.Orientation.HORIZONTAL, 0, 100, 10);
        scale_v.set_value(volume);
        scale_v.set_draw_value(false);
        //scale.connect('value-changed', self.__volume_changed)

        hbox_volume = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        hbox_volume.pack_start(get_image("audio-volume-high-symbolic", 24), false, false, 1);
        hbox_volume.pack_end(scale_v, false, false, 0);
        vbox.pack_start(hbox_volume, false, false, 1);

        Gtk.Scale scale_b = new Gtk.Scale.with_range(Gtk.Orientation.HORIZONTAL, 0, 100, 10);
        scale_b.set_value(brightness);
        scale_b.set_draw_value(false);
        //scale.connect('value-changed', self.__brightness_changed)

        hbox_brightness = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        hbox_brightness.pack_start(get_image("display-brightness-symbolic", 24), false, false, 1);
        hbox_brightness.pack_end(scale_b, true, true, 0);
        vbox.pack_start(hbox_brightness, false, false, 1);

        Gtk.Box hbox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        vbox.pack_end(hbox, false, false, 10);

        Gtk.Button shutdown_button = new Gtk.Button();
        shutdown_button.set_name("ShutdownButton");
        shutdown_button.set_tooltip_text("Shutdown");
        shutdown_button.set_image(get_image("system-shutdown-symbolic", 48));
        shutdown_button.clicked.connect(power_off_cb);
        hbox.pack_start(shutdown_button, true, true, 10);

        Gtk.Button reboot_button = new Gtk.Button();
        reboot_button.set_name("RebootButton");
        reboot_button.set_tooltip_text("Reboot");
        reboot_button.set_image(get_image("view-refresh-symbolic", 48));
        reboot_button.clicked.connect(reboot_cb);
        hbox.pack_start(reboot_button, true, true, 10);

        Gtk.Button lock_button = new Gtk.Button();
        lock_button.set_name("LockButton");
        lock_button.set_tooltip_text("Lock");
        lock_button.set_image(get_image("system-lock-screen-symbolic", 48));
        shutdown_button.clicked.connect(lock_screen_cb);
        hbox.pack_start(lock_button, true, true, 10);

        Gtk.Button settings_button = new Gtk.Button();
        settings_button.set_name("SettingsButton");
        settings_button.set_tooltip_text("Settings");
        settings_button.set_image(get_image("preferences-system-symbolic", 48));
        settings_button.clicked.connect(show_settings_cb);
        hbox.pack_start(settings_button, true, true, 10);

        focus_out_event.connect(focus_out_event_cb);
    }

    public void reveal(bool visible) {
        if (visible != shown) {
            shown = visible;
            if (shown) {
                _reveal();
            }

            else {
                _disreveal();
            }
        }
    }

    private void _reveal() {
        show_all();
        reveal_changed(true);

        int w; int h;
        get_size(out w, out h);

        int x; int y;
        get_position(out x, out y);

        GLib.Timeout.add(20, () => {
            bool t = x > DISPLAY_WIDTH - w;
            if (x == last_position || !t) {
                move(DISPLAY_WIDTH - w, 0);
                last_position = 0;
                return false;
            }

            else {
                int avance = (x - (DISPLAY_WIDTH - w)) / 2;
                x -= avance;
                move(x, 0);
                last_position = x;
                return true;
            }
        });
    }

    private void _disreveal() {
        reveal_changed(false);

        int w; int h;
        get_size(out w, out h);

        int x; int y;
        get_position(out x, out y);

        GLib.Timeout.add(20, () => {
            if (x == last_position || x > DISPLAY_WIDTH) {
                move(DISPLAY_WIDTH, 0);
                last_position = 0;
                hide();
                return false;
            }

            else {
                int avance = (DISPLAY_WIDTH - x) / 2;
                x += avance;
                last_position = x;
                move(x, 0);
                return true;
            }
        });
    }

    private bool focus_out_event_cb(Gtk.Widget self, Gdk.EventFocus event) {
        reveal(false);
        return true;
    }

    private void power_off_cb(Gtk.Button button) {
        reveal(false);
        power_off();
    }

    private void reboot_cb(Gtk.Button button) {
        reveal(false);
        reboot();
    }

    private void lock_screen_cb(Gtk.Button button) {
        reveal(false);
        lock_screen();
    }

    private void show_settings_cb(Gtk.Button button) {
        reveal(false);
        show_settings();
    }
}
