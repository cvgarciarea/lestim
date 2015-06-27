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

    private Gtk.Label time_label;
    private  Gtk.Label day_label;
    private Gtk.Revealer revealer;
    private Calendar calendar;

    private DateTime time;

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

        GLib.Timeout.add(1000, update_clock);
    }

    public bool show_calendar(Gtk.Widget box, Gdk.EventButton event) {
        revealer.set_reveal_child(!revealer.get_child_revealed());
        return true;
    }

    private bool update_clock() {
        time = new DateTime.now_local();
        int current_day = time.get_day_of_month();
        int current_month = time.get_month();
        int current_year = time.get_year();
        string format = "%H:%M";
        string date = "%d/%d/%d".printf(current_day, current_month, current_year);
        string time_markup = "<b><big><big><big><big><big><big><big>" + time.format(format + (show_seconds ? ":%S": "")) + "</big></big></big></big></big></big></big></b>";

        time_label.set_markup(time_markup);
        day_label.set_markup("<big><big>" + date + "</big></big>");

        return true;
    }
}

private class MonitorItem: Gtk.Box {

    public Gtk.Image icon;
    public Gtk.Label label;

    public MonitorItem() {
        label = new Gtk.Label(null);
        icon = new Gtk.Image();

        set_orientation(Gtk.Orientation.VERTICAL);
        pack_start(icon, true, true, 0);
        pack_end(label, false, false, 0);

        show_all();
    }

    public void set_icon(string icon_name) {
        remove(icon);

        icon = get_image_from_name(icon_name);
        pack_start(icon, true, true, 0);
        show_all();
    }

    public void set_label(string text) {
        label.set_label(text);
    }
}

private class BatteryItem: MonitorItem {

    public string state = "";
    public int percentage = 0;
    public string battery_path;

    public BatteryItem(string _path) {
        set_label("100%");
        set_icon("battery-symbolic");

        battery_path = _path;

        GLib.Timeout.add(1000, check);
    }

    private bool check() {
        GLib.File file = GLib.File.new_for_path(battery_path);
        if (!file.query_exists()) {
            return false;
        }

        check_battery_state();
        check_battery_percentage();
        return true;
    }

    private void check_battery_state() {
        string status;
        try {
            GLib.FileUtils.get_contents(battery_path, out status);
            status = status.replace("\n", "");
            if (status != state && status != "Unknown") {
                state = status;
                set_label(state);
            }
        } catch {}
    }

    private void check_battery_percentage() {
        int _percentage = 0;

        if (_percentage != percentage) {
            percentage = _percentage;
            set_label((string)percentage + "%");
        }
    }
}

private class NetworkItem: MonitorItem {
    public NetworkItem() {
        set_label("Network");
        set_icon("network-wireless-signal-excellent-symbolic");
    }
}

private class MonitorsItem: Gtk.Box {

    private string battery_path = "/sys/class/power_supply/BAT1/status";

    public BatteryItem battery_item;
    public NetworkItem network_item;

    public MonitorsItem() {
        set_orientation(Gtk.Orientation.HORIZONTAL);

        GLib.File file = GLib.File.new_for_path(battery_path);
        if (file.query_exists()) {
            battery_item = new BatteryItem(battery_path);
            pack_start(battery_item, true, true, 0);
        }

        network_item = new NetworkItem();
        pack_start(network_item, true, true, 0);
    }
}

private class PowerButton: Gtk.Button {

    public string? icon_name = null;
    public Gtk.Image? image = null;

    public PowerButton() {
        set_name("PowerButton");
        set_image_from_string("image-x-generic-symbolic");
        show_all();
    }

    public void set_image_from_string(string icon_name) {
        image = get_image_from_name(icon_name, 48);
        set_image(image);
        show_all();
    }
}

private class ShutdownButton: PowerButton {
    public ShutdownButton() {
        set_name("ShutdownButton");
        set_tooltip_text("Shutdown");
        set_image_from_string("system-shutdown-symbolic");
    }
}

private class RebootButton: PowerButton {
    public RebootButton() {
        set_name("RebootButton");
        set_tooltip_text("Reboot");
        set_image_from_string("view-refresh-symbolic");
    }
}

private class LockButton: PowerButton {
    public LockButton() {
        set_name("LockButton");
        set_tooltip_text("Lock");
        set_image_from_string("system-lock-screen-symbolic");
    }
}

private class SettingsButton: PowerButton {
    public SettingsButton() {
        set_name("SettingsButton");
        set_tooltip_text("Settings");
        set_image_from_string("preferences-system-symbolic");
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
    public int current_y = 0;

    public Gtk.Box vbox;
    public Gtk.Box monitors;
    public Gtk.Box hbox_volume;
    public Gtk.Box hbox_brightness;
    public Gtk.Image volume_icon;

    public LateralPanel() {
        set_name("LateralPanel");
        set_can_focus(false);
        set_keep_above(true);
        set_size_request(300, DISPLAY_HEIGHT);
        set_type_hint(Gdk.WindowTypeHint.DOCK);
        move(DISPLAY_WIDTH, 0);

        vbox = new Gtk.Box(Gtk.Orientation.VERTICAL, 5);
        add(vbox);

        CalendarItem calendar = new CalendarItem();
        vbox.pack_start(calendar, false, false, 10);

        monitors = new MonitorsItem();
        vbox.pack_start(monitors, false, false, 0);

        Gtk.Scale scale_v = new Gtk.Scale.with_range(Gtk.Orientation.HORIZONTAL, 0, 100, 10);
        scale_v.set_name("VolumeScale");
        scale_v.set_value(volume);
        scale_v.set_draw_value(false);

        hbox_volume = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 10);
        hbox_volume.set_margin_left(2);
        hbox_volume.pack_start(get_image_from_name("audio-volume-high-symbolic", 24), false, false, 1);
        hbox_volume.pack_end(scale_v, true, true, 0);
        vbox.pack_start(hbox_volume, false, false, 1);

        Gtk.Scale scale_b = new Gtk.Scale.with_range(Gtk.Orientation.HORIZONTAL, 0, 100, 10);
        scale_b.set_name("BrightnessScale");
        scale_b.set_value(brightness);
        scale_b.set_draw_value(false);
        //scale.connect('value-changed', self.__brightness_changed)

        hbox_brightness = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 10);
        hbox_brightness.set_margin_left(2);
        hbox_brightness.pack_start(get_image_from_name("display-brightness-symbolic", 24), false, false, 1);
        hbox_brightness.pack_end(scale_b, true, true, 0);
        vbox.pack_start(hbox_brightness, false, false, 1);

        Gtk.Box hbox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        vbox.pack_end(hbox, false, false, 10);

        ShutdownButton shutdown_button = new ShutdownButton();
        shutdown_button.clicked.connect(shutdown_request);
        hbox.pack_start(shutdown_button, true, true, 10);

        RebootButton reboot_button = new RebootButton();
        reboot_button.clicked.connect(reboot_request);
        hbox.pack_start(reboot_button, true, true, 10);

        LockButton lock_button = new LockButton();
        lock_button.clicked.connect(lock_screen_request);
        hbox.pack_start(lock_button, true, true, 10);

        SettingsButton settings_button = new SettingsButton();
        settings_button.clicked.connect(show_settings_request);
        hbox.pack_start(settings_button, true, true, 10);
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
                move(DISPLAY_WIDTH - w, current_y);
                last_position = 0;
                return false;
            }

            else {
                int avance = (x - (DISPLAY_WIDTH - w)) / 2;
                x -= avance;
                move(x, current_y);
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
                move(DISPLAY_WIDTH, current_y);
                last_position = 0;
                hide();
                return false;
            }

            else {
                int avance = (DISPLAY_WIDTH - x) / 2;
                x += avance;
                last_position = x;
                move(x, current_y);
                return true;
            }
        });
    }

    private bool focus_out_event_cb(Gtk.Widget self, Gdk.EventFocus event) {
        reveal(false);
        return true;
    }

    private void shutdown_request(Gtk.Button button) {
        reveal(false);
        power_off();
    }

    private void reboot_request(Gtk.Button button) {
        reveal(false);
        reboot();
    }

    private void lock_screen_request(Gtk.Button button) {
        reveal(false);
        lock_screen();
    }

    private void show_settings_request(Gtk.Button button) {
        reveal(false);
        show_settings();
    }
}
