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

private class CalendarItem: Gtk.Box {

    private Gtk.Label time_label;
    private Gtk.Label day_label;
    private Gtk.Revealer revealer;
    private Ltk.Calendar calendar;

    public bool show_seconds = false;

    public CalendarItem() {
        this.set_orientation(Gtk.Orientation.VERTICAL);
        this.set_name("CalendarItem");

        Gtk.EventBox box1 = new Gtk.EventBox();
        box1.button_release_event.connect(this.show_calendar);
        this.pack_start(box1, false, false, 0);

        this.time_label = new Gtk.Label(null);
        this.time_label.set_name("TimeLabel");
        box1.add(this.time_label);

        Gtk.EventBox box2 = new Gtk.EventBox();
        box2.button_release_event.connect(this.show_calendar);
        pack_start(box2, false, false, 0);

        this.day_label = new Gtk.Label(null);
        this.day_label.set_name("DayLabel");
        box2.add(this.day_label);

        this.revealer = new Gtk.Revealer();
        this.revealer.set_reveal_child(false);
        this.pack_start(this.revealer, false, false, 0);

        this.calendar = new Ltk.Calendar();
        this.revealer.add(this.calendar);

        GLib.Timeout.add(1000, this.update_clock);
    }

    public bool show_calendar(Gtk.Widget box, Gdk.EventButton event) {
        this.revealer.set_reveal_child(!this.revealer.get_child_revealed());
        return true;
    }

    private bool update_clock() {
        string time;
        string date;

        get_current_time(show_seconds, out time, out date);

        string time_markup = "<b><big><big><big><big><big><big><big>%s</big></big></big></big></big></big></big></b>".printf(time);
        string date_marpup = "<big><big>%s</big></big>".printf(date);

        this.time_label.set_markup(time_markup);
        this.day_label.set_markup(date_marpup);

        return true;
    }
}

private class MonitorItem: Gtk.Box {

    public Gtk.Image icon;
    public Gtk.Label label;

    public MonitorItem() {
        this.label = new Gtk.Label(null);
        this.icon = new Gtk.Image();

        this.set_orientation(Gtk.Orientation.VERTICAL);
        this.pack_start(this.icon, true, true, 0);
        this.pack_end(this.label, false, false, 0);

        this.show_all();
    }

    public void set_icon(string icon_name) {
        this.remove(this.icon);

        this.icon = get_image_from_name(icon_name);
        this.pack_start(this.icon, true, true, 0);
        this.show_all();
    }

    public void set_label(string text) {
        this.label.set_label(text);
    }
}

private class BatteryItem: MonitorItem {

    public string state = "";
    public int percentage = 0;
    public string battery_path;

    public BatteryItem(string path) {
        this.set_label("100%");
        this.set_icon("battery-symbolic");

        this.battery_path = path;

        //GLib.Timeout.add(1000, this.check);
    }

    private bool check() {
        GLib.File file = GLib.File.new_for_path(this.battery_path);
        if (!file.query_exists()) {
            return false;
        }

        this.check_battery_state();
        this.check_battery_percentage();
        return true;
    }

    private void check_battery_state() {
        string status;
        try {
            GLib.FileUtils.get_contents(this.battery_path, out status);
            status = status.replace("\n", "");
            if (status != state && status != "Unknown") {
                state = status;
                this.set_label(state);
            }
        } catch {}
    }

    private void check_battery_percentage() {
        int percentage = 0;

        if (this.percentage != percentage) {
            this.percentage = percentage;
            this.set_label(percentage.to_string() + "%");
        }
    }
}

private class NetworkItem: MonitorItem {
    public NetworkItem() {
        this.set_label("Network");
        this.set_icon("network-wireless-signal-excellent-symbolic");
    }
}

private class MonitorsItem: Gtk.Box {

    private string battery_path = "/sys/class/power_supply/BAT1/status";

    public BatteryItem battery_item;
    public NetworkItem network_item;

    public MonitorsItem() {
        this.set_orientation(Gtk.Orientation.HORIZONTAL);

        GLib.File file = GLib.File.new_for_path(battery_path);
        if (file.query_exists()) {
            this.battery_item = new BatteryItem(battery_path);
            this.pack_start(this.battery_item, true, true, 0);
        }

        this.network_item = new NetworkItem();
        this.pack_start(this.network_item, true, true, 0);
    }
}

private class PowerButton: Gtk.Button {

    public string? icon_name = null;
    public Gtk.Image? image = null;

    public PowerButton() {
        this.set_name("PowerButton");
        this.set_image_from_string("image-x-generic-symbolic");
        this.show_all();
    }

    public void set_image_from_string(string icon_name) {
        this.image = get_image_from_name(icon_name, 48);
        this.set_image(this.image);
        this.show_all();
    }
}

private class ShutdownButton: PowerButton {
    public ShutdownButton() {
        this.set_name("ShutdownButton");
        this.set_tooltip_text("Shutdown");
        this.set_image_from_string("system-shutdown-symbolic");
    }
}

private class RebootButton: PowerButton {
    public RebootButton() {
        this.set_name("RebootButton");
        this.set_tooltip_text("Reboot");
        this.set_image_from_string("view-refresh-symbolic");
    }
}

private class LockButton: PowerButton {
    public LockButton() {
        this.set_name("LockButton");
        this.set_tooltip_text("Lock");
        this.set_image_from_string("system-lock-screen-symbolic");
    }
}

private class SettingsButton: PowerButton {
    public SettingsButton() {
        this.set_name("SettingsButton");
        this.set_tooltip_text("Settings");
        this.set_image_from_string("preferences-system-symbolic");
    }
}

public class LestimPanel: Gtk.Window {

    public signal void reveal_changed(bool visible);
    public signal void power_off();
    public signal void reboot();
    public signal void lock_screen();
    public signal void show_settings();

    public GLib.Settings gsettings;
    Pulse.Stream stream;
    Pulse.StreamContainer stream_container;

    public bool shown = false;
    public int last_position = DISPLAY_WIDTH;
    public int brightness = 0;
    public int current_y = 0;

    public Gtk.Box vbox;
    public Gtk.Box monitors;
    public Gtk.Box hbox_volume;
    public Gtk.Image image_volume;
    public Gtk.Box hbox_brightness;
    public Gtk.Image volume_icon;

    public LestimPanel() {
        this.set_name("LestimPanel");
        this.set_can_focus(false);
        this.set_keep_above(true);
        this.set_size_request(300, DISPLAY_HEIGHT);
        this.set_type_hint(Gdk.WindowTypeHint.DOCK);
        this.move(DISPLAY_WIDTH, 0);

        this.gsettings = new GLib.Settings("org.lestim.panel");
        this.gsettings.changed.connect(this.settings_changed_cb);

        this.stream = new Pulse.Stream();
        this.stream_container = new Pulse.StreamContainer(Pulse.StreamType.SINK);

        this.vbox = new Gtk.Box(Gtk.Orientation.VERTICAL, 5);
        this.add(this.vbox);

        CalendarItem calendar = new CalendarItem();
        this.vbox.pack_start(calendar, false, false, 10);

        this.monitors = new MonitorsItem();
        this.vbox.pack_start(this.monitors, false, false, 0);

        this.hbox_volume = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 10);
        this.hbox_volume.set_margin_left(2);
        this.vbox.pack_start(this.hbox_volume, false, false, 1);

        this.image_volume = get_image_from_name("audio-volume-high-symbolic", 24);
        this.hbox_volume.pack_start(this.image_volume, false, false, 1);

        Gtk.Scale scale_v = new Gtk.Scale.with_range(Gtk.Orientation.HORIZONTAL, 0, 100, 10);
        scale_v.set_name("VolumeScale");
        scale_v.set_value(this.stream.relative_volume);
        scale_v.set_draw_value(false);
        scale_v.value_changed.connect(this.volume_changed);
        this.hbox_volume.pack_end(scale_v, true, true, 0);

        Gtk.Scale scale_b = new Gtk.Scale.with_range(Gtk.Orientation.HORIZONTAL, 0, 100, 10);
        scale_b.set_name("BrightnessScale");
        scale_b.set_value(this.brightness);
        scale_b.set_draw_value(false);
        //scale.connect('value-changed', self.__brightness_changed)

        this.hbox_brightness = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 10);
        this.hbox_brightness.set_margin_left(2);
        this.hbox_brightness.pack_start(get_image_from_name("display-brightness-symbolic", 24), false, false, 1);
        this.hbox_brightness.pack_end(scale_b, true, true, 0);
        this.vbox.pack_start(this.hbox_brightness, false, false, 1);

        Gtk.Box hbox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        this.vbox.pack_end(hbox, false, false, 10);

        ShutdownButton shutdown_button = new ShutdownButton();
        shutdown_button.clicked.connect(this.shutdown_request);
        hbox.pack_start(shutdown_button, true, true, 2);

        RebootButton reboot_button = new RebootButton();
        reboot_button.clicked.connect(this.reboot_request);
        hbox.pack_start(reboot_button, true, true, 2);

        LockButton lock_button = new LockButton();
        lock_button.clicked.connect(this.lock_screen_request);
        hbox.pack_start(lock_button, true, true, 2);

        SettingsButton settings_button = new SettingsButton();
        settings_button.clicked.connect(this.show_settings_request);
        hbox.pack_start(settings_button, true, true, 2);
        
        this.realize.connect(this.realize_cb);
    }

    public void realize_cb(Gtk.Widget self) {
        this.reload_transparency();
    }

    public void volume_changed(Gtk.Range scale) {
        int volume = (int)scale.get_value();
        this.stream_container.set_muted(this.stream, false);
        this.stream_container.set_volume(this.stream, volume);

        string name;
        this.hbox_volume.remove(this.image_volume);

        if (volume == 0) {
            name = "audio-volume-muted-symbolic";
        } else if (volume > 0 && volume <= 33) {
            name = "audio-volume-low-symbolic";
        } else if (volume > 33 && volume <= 66) {
            name = "audio-volume-medium-symbolic";
        } else {
            name = "audio-volume-high-symbolic";
        }

        this.image_volume = get_image_from_name(name, 24);
        this.hbox_volume.pack_start(this.image_volume, false, false, 1);
        this.hbox_volume.show_all();
    }

    public void settings_changed_cb(GLib.Settings gsettings, string key) {
        switch (key) {
            case "background-transparency":
                this.reload_transparency();
                break;
        }
    }

    public void reload_transparency() {
        double transp = 1.0 - (double)(this.gsettings.get_int("background-transparency")) / 10.0;
        var window = this.get_window();
        window.set_opacity(transp);
    }

    public void reveal(bool visible) {
        if (this.shown != visible) {
            this.shown = visible;
            if (this.shown) {
                this._reveal();
            }

            else {
                this._disreveal();
            }
        }
    }

    private void _reveal() {
        this.show_all();
        this.reveal_changed(true);

        int w; int h;
        this.get_size(out w, out h);

        int x; int y;
        this.get_position(out x, out y);

        GLib.Timeout.add(20, () => {
            bool t = x > DISPLAY_WIDTH - w;
            if (x == last_position || !t) {
                this.move(DISPLAY_WIDTH - w, current_y);
                this.last_position = 0;
                return false;
            }

            else {
                int avance = (x - (DISPLAY_WIDTH - w)) / 2;
                x -= avance;
                this.move(x, current_y);
                this.last_position = x;
                return true;
            }
        });
    }

    private void _disreveal() {
        this.reveal_changed(false);

        int w; int h;
        this.get_size(out w, out h);

        int x; int y;
        this.get_position(out x, out y);

        GLib.Timeout.add(20, () => {
            if (x == this.last_position || x > DISPLAY_WIDTH) {
                this.move(DISPLAY_WIDTH, this.current_y);
                this.last_position = 0;
                this.hide();
                return false;
            }

            else {
                int avance = (DISPLAY_WIDTH - x) / 2;
                x += avance;
                last_position = x;
                this.move(x, this.current_y);
                return true;
            }
        });
    }

    private bool focus_out_event_cb(Gtk.Widget self, Gdk.EventFocus event) {
        this.reveal(false);
        return true;
    }

    private void shutdown_request(Gtk.Button button) {
        this.reveal(false);
        this.power_off();
    }

    private void reboot_request(Gtk.Button button) {
        this.reveal(false);
        this.reboot();
    }

    private void lock_screen_request(Gtk.Button button) {
        this.reveal(false);
        this.lock_screen();
    }

    private void show_settings_request(Gtk.Button button) {
        this.reveal(false);
        this.show_settings();
    }
}
