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

    public enum Mounts {
        JANUARY,
        FEBRUARY,
        MARCH,
        APRIL,
        MAY,
        JUNE,
        JULY,
        AUGUST,
        SEPTEMBER,
        OCTOBER,
        NOVEMBER,
        DECEMBER
    }

    public enum WeekDays {
        SUNDAY,
        MONDAY,
        TUESDAY,
        WEDNESDAY,
        THURSDAY,
        FRIDAY,
        SATURDAY
    }

    public string[] get_month_names() {
        return { "January",
                 "February",
                 "March",
                 "April",
                 "May",
                 "June",
                 "July",
                 "August",
                 "September",
                 "October",
                 "November",
                 "December" };
    }

    public string get_month_name(int index) {
        return get_month_names()[index];
    }

    public string[] get_week_days() {
        return { "Sunday",
                 "Monday",
                 "Tuesday",
                 "Wednesday",
                 "Thursday",
                 "Friday",
                 "Saturday" };
    }

    public string get_week_day(int index) {
        return get_week_days()[index];
    }

    public string get_day_abbr(int index) {
        return "%c".printf(get_week_days()[index][0]);
    }

    public GLib.DateTime get_datetime_from_string(string date) {
        string[] date_splited = date.split("/");
        int day = int.parse(date_splited[0]);
        int month = int.parse(date_splited[1]);
        int year = int.parse(date_splited[2]);

        return new GLib.DateTime.local(year, month, day, 0, 0, 0.0);
    }

    public class CalendarButton: Gtk.Button {

        public Gtk.Label label_widget;

        public CalendarButton(int day, bool good_month=true, bool current_day=false) {
            this.set_name("CalendarButton");

            this.label_widget = new Gtk.Label(day.to_string());
            this.label_widget.set_name("CalendarButtonLabel");
            this.add(this.label_widget);
        }
    }

    public class Calendar: Gtk.Box {

        public static int button_radius = 15;
        public static int button_space = 1;

        public string current_date;

        public Gtk.Box month_box;
        public Gtk.Label month_label;
        public Gtk.Grid grid;

        public Calendar() {
            this.set_name("LestimCalendar");
            this.set_orientation(Gtk.Orientation.VERTICAL);
            this.set_size_request(100, 200);
            this.set_margin_top(10);
            this.set_margin_bottom(10);
            this.set_margin_left(10);
            this.set_margin_right(10);

            this.month_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            this.pack_start(this.month_box, false, false, 2);

            Gtk.Button button_back = new Gtk.Button();
            button_back.add(get_image_from_name("pan-start-symbolic", 24));
            button_back.clicked.connect(this.prev_month);
            this.month_box.pack_start(button_back, false, false, 0);

            this.month_label = new Gtk.Label(null);
            this.month_box.pack_start(this.month_label, true, true, 0);

            Gtk.Button button_forward = new Gtk.Button();
            button_forward.add(get_image_from_name("pan-end-symbolic", 24));
            button_forward.clicked.connect(this.next_month);
            this.month_box.pack_end(button_forward, false, false, 0);

            this.grid = new Gtk.Grid();
            this.pack_end(this.grid, true, true, 2);

            this.reload();
            this.show_all();
        }

        public void reload(string? a=null) {
            string date;
            if (a == null) {
                string time;
                get_current_time(false, out time, out date);
            } else {
                date = a;
            }

            if (date == this.current_date) {
                return;
            }

            this.current_date = date;
            this.remove(this.grid);

            this.grid = new Gtk.Grid();
            this.grid.set_row_homogeneous(true);
            this.grid.set_column_homogeneous(true);
            this.grid.set_row_spacing(this.button_space);
            this.grid.set_column_spacing(this.button_space);
            this.pack_end(this.grid, true, true, 2);

            string[] days = get_week_days();
            for (int i = 0; i < days.length; i++) {
                string abbr = get_day_abbr(i);
                this.grid.attach(new Gtk.Label(abbr), i, 0, 1, 1);
            }

            GLib.DateTime datetime = get_datetime_from_string(date);
            datetime = datetime.add_days(datetime.get_day_of_month() * -1 + 1);

            int month = datetime.get_month();
            int x = datetime.get_day_of_week() - 1;  // after, add 1
            int y = 1;  // because in y=0 is occupied by the days abbreviations

            if (x == 6) {  // in datetime, 7 is Sunday
                x = 0;
            }

            this.month_label.set_label(get_month_name(month - 1));

            for (int i = 1; i < 32; i++) {  // anyone month has 32 days
                datetime = datetime.add_days((i > 1)? 1: 0);  // the first day is added in the second datetime definition
                if (datetime.get_month() != month) {
                    break;
                }

                x += 1;
                if (x == 7) {
                    x = 0;
                    y += 1;
                }

                CalendarButton button = new CalendarButton(i);
                this.grid.attach(button, x, y, 1, 1);
            }

            this.show_all();
        }

        public void prev_month(Gtk.Button button) {
            string[] date = this.current_date.split("/");
            int day = int.parse(date[0]);
            int month = int.parse(date[1]) - 1;
            int year = int.parse(date[2]);

            if (month == 0) {
                month = 12;
                year -= 1;
            }

            GLib.DateTime datetime = new GLib.DateTime.local(year, month, day, 0, 0, 0.0);
            this.reload(datetime.format("%d/%m/%Y"));
        }

        public void next_month(Gtk.Button button) {
            string[] date = this.current_date.split("/");
            int day = int.parse(date[0]);
            int month = int.parse(date[1]) + 1;
            int year = int.parse(date[2]);

            if (month == 13) {
                month = 1;
                year++;
            }

            GLib.DateTime datetime = new GLib.DateTime.local(year, month, day, 0, 0, 0.0);
            this.reload(datetime.format("%d/%m/%Y"));
        }
    }
}

