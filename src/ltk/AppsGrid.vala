namespace Ltk {

    private class CategoryButton : Gtk.ToggleButton {

        public signal void category_button_press_event(string filter_value);

        private string filter_value;

        public CategoryButton(string label, string filter_value) {
            Object(label: label);

            this.filter_value = filter_value;

            this.button_press_event.connect(() => {
                category_button_press_event(filter_value);
                return false;
            });
        }
    }

    class AppIcon : Gtk.Box {

        public signal void started();

        private App app;

        public AppIcon(App app) {
            Object(orientation: Gtk.Orientation.VERTICAL);

            this.app = app;

            this.build_gui();
        }

        public void build_gui() {
            // Basic setup
            base.homogeneous = false;

            // Setup button
            Gtk.Button button = new Gtk.Button();
            button.set_relief(Gtk.ReliefStyle.NONE);
            button.clicked.connect(() => {
                app.start();
                started();
            });
            this.pack_start(button);

            // Setup button image
            Gtk.Image image = null;

            string icon_path = app.get_icon_path();
            if (icon_path != null) {
                try {
                    Gdk.Pixbuf raw_image = null;

                    raw_image = new Gdk.Pixbuf.from_file(icon_path);

                    raw_image = raw_image.scale_simple(Constants.app_icon_size,
                                                       Constants.app_icon_size,
                                                       Gdk.InterpType.HYPER);

                    image = new Gtk.Image.from_pixbuf(raw_image);
                } catch  (GLib.Error e) {
                    image = null;
                }
            }

            // If we have an image we set it
            if (image != null) {
                button.set_image(image);
            } else {
                button.set_label("no image");
            }

            // Setup app name label
            string label1_str = app.get_name();
            if (label1_str.char_count() > 17) {
                label1_str = label1_str.slice(0, 14);
                label1_str = label1_str +"...";
            }

            Gtk.Label label1 = new Gtk.Label(label1_str);
            this.pack_start(label1);

            // Setup tooltip
            string tooltip;
            if (app.get_generic() != null) {
                tooltip = app.get_name()+"\n"+app.get_generic()+"\n"+app.get_comment();
            } else {
                tooltip = app.get_name()+"\n"+app.get_comment();
            }
            button.set_tooltip_text(tooltip);

        }
    }

    public class AppGrid : Gtk.Grid {

        private const int row_length = 6;

        public AppGrid() {
            this.set_column_spacing(15);
            this.set_row_spacing(15);
            if (Gdk.Screen.get_default().is_composited()) {
                //Draw background transparent
                base.draw.connect((context) => {
                    context.set_source_rgba(Constants.bg_color[0], Constants.bg_color[1],
                    Constants.bg_color[2], Constants.bg_color[3]);
                    context.set_operator(Cairo.Operator.SOURCE);
                    context.paint();

                    //Return false so that other callbacks for the 'draw' event
                    //will be invoked. (Other callbacks are responsible for the actual
                    //drawing of the widgets)
                    return false;
                });
            }
        }

        public new void add(AppIcon app_icon) {
            int number_of_children = (int)base.get_children().length();

            this.attach(app_icon,
                        (number_of_children % row_length),
                        (number_of_children / row_length) + 1,
                        1,
                        1);
        }

        public void clear() {
            //Removes all AppIcon from this AppGrid
            foreach (Gtk.Widget wdg in base.get_children()) {
                base.remove(wdg);
            }
        }
    }
}
