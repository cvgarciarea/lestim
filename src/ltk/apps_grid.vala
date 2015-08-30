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

namespace Constants {

    private static const string application_name = "Rocket-Launcher";
    private static const string application_icon = "rocket-launcher";

    private static const string fallback_icon = "application-x-executable";
    private static const int app_icon_size = 100;

    private static const double[] bg_color = { 0.811, 0.811, 0.811, 0.7 };

    public static const string[] category_button_values = { "",
                                              "AudioVideo",
                                              "Audio",
                                              "Video",
                                              "Development",
                                              "Education",
                                              "Game",
                                              "Graphics",
                                              "Network",
                                              "Office",
                                              "Science",
                                              "Settings",
                                              "System",
                                              "Utility" };

    public static const string[] category_button_names = { "All",
                                             "Multimedia",
                                             "Audio",
                                             "Video",
                                             "Development",
                                             "Education",
                                             "Game",
                                             "Graphics",
                                             "Network",
                                             "Office",
                                             "Science",
                                             "Settings",
                                             "System",
                                             "Utility" };

    public static const uint category_button_count = 14;

}

namespace Ltk {

    public class CategoryButton: Gtk.ToggleButton {

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

    public class ApplicationHandler : GLib.Object {

        public signal void selection_changed();

        private string[] directories;
        private string[] directories_fallback = {
            "/usr/share/applications",
            "/usr/local/share/applications",
            GLib.Environment.get_home_dir()+"/.local/share/applications"
        };

        private App[] apps;
        private int[] apps_selected;
        private IconManager icon_manager = new IconManager();

        public ApplicationHandler() {
            // Setup the environment
            setup_environment();

            //Scan applications
            apps = scan_applications();

            // Set filter to all
            filter_all();
        }

        private void setup_environment() {
            //Select right directories to search in

            //If XDG_DATA_DIRS is set use all listed directories+/applications
            //to search for desktop files. Also search in some default locations
            //If XDG_DATA_DIRS is not set only search in default locations
            //Notice: It is not checked whether these directories exist, but
            //it should not be a problem if they don't.
            string directories_environ = GLib.Environment.get_variable("XDG_DATA_DIRS");

            if (directories_environ != null) {
                List<string> directories_l = new List<string>();

                //Append values from $XDG_DATA_DIRS
                foreach (string dir in directories_environ.split(":")) {
                    //Append '/' if necessary
                    //then append "applications"
                    if (dir.to_utf8()[dir.length-1] != '/') {
                        dir = string.join("", dir, "/applications");
                    } else {
                        dir = string.join("", dir, "applications");
                    }
                    directories_l.append(dir);
                }

                //Append fallback values if they aren't already in list
                foreach (string fallback_dir in directories_fallback) {
                    bool contains = false;
                    foreach (string dir in directories_l) {
                        if (fallback_dir == dir) {
                            contains = true;
                            break;
                        }
                    }
                    if (!contains) {
                        directories_l.append(fallback_dir);
                    }
                }

                //Convert List to array
                directories = new string[directories_l.length()];
                for (int i = 0; i < directories_l.length(); i++) {
                    directories[i] = directories_l.nth_data(i);
                }
            } else {
                directories = directories_fallback;
            }
        }

        private App[] scan_applications() {
            // Go through all directories containing .desktop files
            // and create a list of (absolute) paths to .desktop files.
            GLib.List<string> desktop_file_list = new GLib.List<string>();

            foreach (string d in directories) {
                GLib.File directory = GLib.File.new_for_path(d);

                // If the directory does not exist we simly skip it.
                if (directory.query_exists() == false) {
                    continue;
                }

                try {
                    // Go through all files in this directory
                    GLib.FileEnumerator enm = directory.enumerate_children(
                                FileAttribute.STANDARD_NAME,
                                GLib.FileQueryInfoFlags.NONE);
                    GLib.FileInfo fileInfo;
                    while((fileInfo = enm.next_file()) != null) {

                        // If the file has the right suffix we'll add
                        // it to the list.
                        string x = d+"/"+fileInfo.get_name();
                        if (x.has_suffix(".desktop")) {
                            desktop_file_list.append(x);
                        }
                    }
                }
                catch (Error e) {
                }
            }

            // We create an Object from every .desktop file in our list
            // and put this object in a list (which we return).
            //
            // If we support threading we do this threaded,
            // if not we just do it in one thread.
            List<App> apps = new List<App>();

            if (Thread.supported()) {
                // Create a list of all running threads
                GLib.List<Thread> thread_list = new GLib.List<Thread>();

                // Create and start all threads
                foreach (string desktop_file in desktop_file_list) {
                    try {
                        AppCreationWorker worker = new AppCreationWorker(desktop_file, icon_manager);
                        Thread t = new GLib.Thread<App?>.try("AppCreationWorker", worker.thread_func);
                        thread_list.append(t);
                    } catch (Error e) {
                        string error_str = "";
                        error_str += "Error occured while creating a worker for a .desktop file in multi threaded mode\n";
                        error_str += "File: " +desktop_file +"\n";
                        error_str += "Application seemed to have support for multithreading\n";
                        error_str += "Error: \"" +e.message +"\"\n";
                        error_str += "Ignoring this .desktop_file file ...\n";
                    }
                }

                // Wait for all threads to finish
                foreach (Thread<App> t in thread_list) {
                    App app = t.join();

                    if (app != null) {
                        apps.append(app);
                    }
                }
            } else {
                foreach (string desktop_file in desktop_file_list) {
                    AppCreationWorker worker = new AppCreationWorker(desktop_file, icon_manager);
                    App app = worker.thread_func();

                    if (app != null) {
                        apps.append(app);
                    }
                }
            }

            //Sort our list of apps
            apps.sort((a,b) => {
                return GLib.strcmp(a.get_name(), b.get_name());
            });

            // Convert to array
            App[] apps_ar = new App[apps.length()];
            for (int i = 0; i < apps.length(); i++) {
                apps_ar[i] = apps.nth_data(i);
            }
            return apps_ar;
        }

        public App[] get_apps() {
            return apps;
        }

        public int[] get_selected_apps() {
            return apps_selected;
        }

        public void filter_all() {
            int[] all = new int[apps.length];

            for (int i = 0; i < apps.length; i++) {
                all[i] = i;
            }

            this.apps_selected = all;
            selection_changed();
        }

        public void filter_categorie(string? filter) {
            if (filter == null || filter == "") {
                filter_all();
                return;
            }

            List<int> filtered_list = new List<int>();

            for (int i = 0; i < apps.length; i++) {
                App app = apps[i];
                string[] categories = app.get_categories();

                for (int p = 0; p < categories.length; p++) {
                    if (filter == categories[p]) {
                        filtered_list.append(i);
                        break;
                    }
                }
            }

            // Convert list to array
            int[] filtered_ar = new int[filtered_list.length()];
            for (int i = 0; i < filtered_list.length(); i++) {
                filtered_ar[i] = filtered_list.nth_data(i);
            }

            // Set value and send signal
            this.apps_selected = filtered_ar;
            selection_changed();
        }

        public void filter_string(string? filter) {
            if (filter == null || filter == "") {
                filter_all();
                return;
            }

            List<int> filtered_list = new List<int>();

            for (int i = 0; i < apps.length; i++) {
                App app = apps[i];

                // Check for matching name
                if (app.get_name().down().contains(filter.down())) {
                    filtered_list.append(i);
                    continue;
                }

                // Check for matching generic name
                string gen = app.get_generic();
                if (gen != null) {
                    if (gen.down().contains(filter.down())) {
                        filtered_list.append(i);
                        continue;
                    }
                }

                // Check for matching category
                string[] categories = app.get_categories();
                if (categories != null) {
                    for (int p = 0; p < categories.length; p++) {
                        if (categories[p].down().contains(filter.down())) {
                            filtered_list.append(i);
                            break;
                        }
                    }
                }
            }

            // Convert list to array
            int[] filtered_ar = new int[filtered_list.length()];
            for (int i = 0; i < filtered_list.length(); i++) {
                filtered_ar[i] = filtered_list.nth_data(i);
            }

            // Set value and send signal
            this.apps_selected = filtered_ar;
            selection_changed();
        }
    }

    public class AppCreationWorker : GLib.Object {
        private string data;
        private IconManager icon_manager;

        public AppCreationWorker(string data, IconManager icon_manager) {
            this.data = data;
            this.icon_manager = icon_manager;
        }

        public App? thread_func() {
            App new_app = new App(data, icon_manager);

            if (new_app.is_valid()) {
                return new_app;
            }

            return null;
        }
    }

    public class IconThemeBaseDirectories : GLib.Object {
        private static string[] icon_directories;

        public static string[] get_theme_base_directories() {
            if (icon_directories == null) {
                icon_directories = setup_theme_base_directories();
            }

            return icon_directories;
        }

        private static string[] setup_theme_base_directories() {
            // Create a list of base directories, because a list is
            // easier to handle.
            // We later convert that list to an array.
            List<string> base_dirs_l = new List<string>();
            string[] base_dirs;

            // Add '$HOME/.icons' to list of base directories
            string? home_dir = GLib.Environment.get_variable("HOME");
            if (home_dir != null) {
                if (home_dir.to_utf8()[home_dir.length-1] != '/') {
                    home_dir = string.join("", home_dir, "/.icons");
                } else {
                    home_dir = string.join("", home_dir, ".icons");
                }

                // Check if directory is a valid directory
                bool valid = is_valid_directory(home_dir);

                // Check if directory is already contained in list
                // if not, we add it.
                if (valid) {
                    bool contained = false;
                    foreach (string contained_dir in base_dirs_l) {
                        if (contained_dir == home_dir) {
                            contained = true;
                            break;
                        }
                    }

                    if (!contained) {
                        base_dirs_l.append(home_dir);
                    }
                }

            } else {
                string warn_str = "";
            }

            // Add '/usr/share/icons' and '/usr/local/share/icons'
            string[] default_locations = {"/usr/share/icons", "/usr/local/share/icons"};
            foreach (string default_dir in default_locations) {
                bool valid = is_valid_directory(default_dir);

                // Check if directory is a valid directory
                if (valid) {
                    // Check if directory is already contained in list
                    // if not, we add it.
                    bool contained = false;
                    foreach (string contained_dir in base_dirs_l) {
                        if (contained_dir == default_dir) {
                            contained = true;
                            break;
                        }
                    }

                    if (!contained) {
                        base_dirs_l.append(default_dir);
                    }
                }
            }

            // Add directories from XDG_DATA_DIRS to list of base
            // directories.
            string? xdg_data_dirs = GLib.Environment.get_variable("XDG_DATA_DIRS");
            if (xdg_data_dirs != null) {
                foreach (string new_dir in xdg_data_dirs.split(":")) {
                    // Append '/icons' or 'icons'
                    if (new_dir.to_utf8()[new_dir.length-1] != '/') {
                        new_dir = string.join("", new_dir, "/icons");
                    } else {
                        new_dir = string.join("", new_dir, "icons");
                    }

                    // Check if directory is a valid directory
                    bool valid = is_valid_directory(new_dir);

                    // Check if directory is already contained in list
                    // if not, we add it.
                    if (valid) {
                        bool contained = false;
                        foreach (string contained_dir in base_dirs_l) {
                            if (contained_dir == new_dir) {
                                contained = true;
                                break;
                            }
                        }

                        if (!contained) {
                            base_dirs_l.append(new_dir);
                        }
                    }
                }
            } else {
            }

            // Convert List to array
            base_dirs = new string[base_dirs_l.length()];
            for (int i = 0; i < base_dirs_l.length(); i++) {
                base_dirs[i] = base_dirs_l.nth_data(i);
            }

            return base_dirs;
        }

        private static bool is_valid_directory(string path) {
            // Check if file exists
            GLib.File file = GLib.File.new_for_path(path);
            if (!file.query_exists()) {
                return false;
            }

            // If file is directory it is valid
            GLib.FileType file_type = file.query_file_type(GLib.FileQueryInfoFlags.NONE);
            if (file_type == GLib.FileType.DIRECTORY) {
                return true;
            }

            // If file is regular file it is not valid
            if (file_type == GLib.FileType.REGULAR) {
                return false;
            }

            // If file is a symlink, we check if the file it is
            // linking to is valid.
            if (file_type == GLib.FileType.SYMBOLIC_LINK) {
                GLib.FileInfo file_info;
                try {
                    file_info = file.query_info("*", GLib.FileQueryInfoFlags.NONE);
                } catch (GLib.Error e) {
                    return false;
                }

                string symlink_target = file_info.get_symlink_target();
                return is_valid_directory(symlink_target);
            }

            // This should not happen
            string error_str = "";
            error_str += "Error occured while scanning for directories,\n";
            error_str += "that contain icon themes.\n";
            error_str += "Unknown error occured in '" +path +"'\n";
            error_str += "Ignoring dir \"" +path +"\"\n";
            return false;
        }
    }

    public class IconTheme : GLib.Object {
        /**
         * This is the absolute path to the theme directory, NOT to the
         * 'index.theme' file of the theme.
        **/
        private string path;

        /**
         * If the IconTheme is valid.
         * The theme is not valid if no index.theme exists or it is
         * malformed.
        **/
        private bool valid;

        /**
         * This is the 'internal' name because there is also the user
         * visisble name.
         * This is the name that the icon theme directoriy has, NOT
         * the name that is set in the 'index.theme' file.
         * (which should be shown to the user)
        **/
        private string? internal_name;

        /**
         * This is an array of parent IconThemes.
         * Parent IconThemes are specified in the 'index.theme' file
         * in the 'Inherits=' line.
        **/
        private IconTheme[] parents;

        /**
         * List of sub directory that actually contain the icon files
         * of this theme.
         * These sub directories are given as groups in the
         * 'index.theme' file.
        **/
        private IconDirectory[] icon_directories;

        public IconTheme(string? name) {
            valid = true;

            internal_name = name;
            if (internal_name == null) {
                valid = false;
                return;
            }

            this.path = find_path();
            if (!valid) {
                return;
            }

            parse_index_file();
            if (!valid) {
                return;
            }
        }

        public void doo() { }

        public bool is_valid() {
            doo();
            return valid;
        }

        private void parse_index_file() {
            // Locate path for index.theme file
            string index_path;
            if (path.to_utf8()[path.length-1] != '/') {
                index_path = string.join("", path, "/index.theme");
            } else {
                index_path = string.join("", path, "index.theme");
            }

            //Open KeyFile
            GLib.KeyFile kf = new GLib.KeyFile();
            try {
                kf.load_from_file(index_path, GLib.KeyFileFlags.NONE);
            } catch (KeyFileError e) {
                valid = false;
                return;
            } catch (FileError e) {
                valid = false;
                return;
            }

            // If KeyFile does not have the top group '[Icon Theme]'
            // it is not valid.
            if (!kf.has_group("Icon Theme")) {
                valid = false;
                return;
            }

            string[] directories;

            // If KeyFile does not have the 'Directories' key inside
            // the '[Icon Theme]' group it is not valid.
            try {
                if (!kf.has_key("Icon Theme", "Directories")) {
                    valid = false;
                    return;
                }
                directories = kf.get_string("Icon Theme", "Directories").split(",");
            } catch (KeyFileError e) {
                valid = false;
                return;
            }

            // Scan for parent icon themes
            // A theme does not need to have parents set.
            try {
                List<IconTheme> parents_l = new List<IconTheme>();
                if (kf.has_key("Icon Theme", "Inherits")) {
                    string p = kf.get_string("Icon Theme", "Inherits");
                    string[] parents = p.split(",");
                    for (int i = 0; i < parents.length; i++) {
                        string parent = parents[i];

                        // We ignore the hicolor theme.
                        // This is against the standard, but we still
                        // do this to prevent not finding an icon theme
                        // if a theme has hicolor as an explicit parent.
                        // We will manually look in the hicolor theme after
                        // we've searched the last theme.
                        if (parent != "hicolor") {
                            IconTheme newTheme = new IconTheme(parent);
                            if (newTheme.is_valid()) {
                                parents_l.append(newTheme);
                            }
                        }
                    }
                }
                this.parents = new IconTheme[parents_l.length()];
                for (int i = 0; i < parents_l.length(); i++) {
                    this.parents[i] = parents_l.nth_data(i);
                }
            } catch (KeyFileError e) {
                valid = false;
                return;
            }

            // Create an IconDirectory from every directory group
            // with the corresponding keys (and key values).

            // Create File for IconTheme directory, which we need
            // to get the path for sub directories.
            GLib.File parent_dir = GLib.File.new_for_path(this.path);

            // We create a list of sub directories,
            // that we later convert to an array
            List<IconDirectory> icon_directories_l = new List<IconDirectory>();

            // We look at every 'directory' group,
            // take all its keys and the corresponding key values
            // and add them to a mx2 matrix.
            // We then create an Object out of that matrix.
            for (int i = 0; i < directories.length; i++) {
                string[] keys;
                try {
                    // If an item in the 'Directory' list does not
                    // exist as a group in this KeyValue File we ignore
                    // that item.
                    if (!kf.has_group(directories[i])) {
                        continue;
                    } else {
                        keys = kf.get_keys(directories[i]);
                    }
                } catch (KeyFileError e) {
                    valid = false;
                    return;
                }

                // Create mx2 Matrix
                string[,] key_value_matrix = new string[keys.length, 2];

                // Add all properties of directory
                for (int p = 0; p < keys.length; p++) {
                    string val = null;
                    try {
                        val = kf.get_string(directories[i], keys[p]);
                    } catch (KeyFileError e) {
                        valid = false;
                        return;
                    }

                    key_value_matrix[p, 0] = keys[p];
                    key_value_matrix[p, 1] = val;
                }

                // Get absolut path for sub directory
                GLib.File child_dir_f = parent_dir.resolve_relative_path(directories[i]);
                string child_dir = child_dir_f.get_parse_name();

                // Create IconDirectory object and add it to the directory
                // list if its valid.
                IconDirectory ic_dir = new IconDirectory(
                                        key_value_matrix,
                                        child_dir);

                if (ic_dir.is_valid()) {
                    icon_directories_l.append(ic_dir);
                }
            }

            // Sort list by maximum icon size
            CompareFunc<IconDirectory> sortFunc = (a, b) => {
                // This sort function actually returns 1 when it should
                // return -1 and vice versa.
                // This is so we can easily sort our list with
                // in descending order.
                int size_a = a.maximum_size();
                int size_b = b.maximum_size();

                if (size_a < size_b) {
                    return 1;
                } else if (size_a == size_b) {
                    return 0;
                } else {
                    return -1;
                }
            };
            icon_directories_l.sort(sortFunc);

            // Convert list to array
            icon_directories = new IconDirectory[icon_directories_l.length()];
            for (int i = 0; i < icon_directories_l.length(); i++) {
                icon_directories[i] = icon_directories_l.nth_data(i);
            }
        }

        private string? find_path() {
            // Go through every base dir in list of base dirs
            foreach (string d in IconThemeBaseDirectories.get_theme_base_directories()) {

                GLib.File base_dir = GLib.File.new_for_path(d);

                // Check if any sub directory of this base dir has the
                // name of this theme.
                // If we found the correct sub directory we return
                // its path.
                try {
                    FileEnumerator child_enum = base_dir.enumerate_children(
                                    "*",
                                    GLib.FileQueryInfoFlags.NONE);

                    GLib.FileInfo child_info;
                    while ((child_info = child_enum.next_file()) != null) {
                        string child_name = child_info.get_name();

                        if (child_name == this.internal_name) {
                            GLib.File child_file = base_dir.resolve_relative_path(child_name);
                            return child_file.get_path();
                        }
                    }
                } catch (Error e) {
                    valid = false;
                    return null;
                }
            }
            valid = false;
            return null;
        }

        public string? get_icon(string name, bool ignore_svg = false) {
            // Look in all directories of this current theme for the specified
            // icon.
            foreach(IconDirectory icon_directory in icon_directories) {
                // We ignore directories containing svg if we don't
                // support them.
                if (ignore_svg && icon_directory.is_scalable()) {
                    continue;
                }

                string? icon_path = icon_directory.get_icon(name);

                if (icon_path != null) {
                    return icon_path;
                }
            }

            // If we haven't found the icon in the current theme we then try
            // to find it in all parent themes.
            for (int i = 0; i < parents.length; i++) {
                string icon_path = parents[i].get_icon(name, ignore_svg);

                if (icon_path != null) {
                    return icon_path;
                }
            }

            // If we haven't found the icon at all we return null
            return null;
        }
    }

    public class IconDirectory : GLib.Object {
        private int size;
        private IconDirectoryType type;
        private int max_size;
        private int min_size;
        private int threshold;

        private string directory;
        private GLib.Tree<string, string> icons;

        private bool valid;

        public IconDirectory(string[, ] properties, string directory_abs) {
            //
            valid = true;
            directory = directory_abs;
            icons = new GLib.Tree<string, string>((a,b) => {
                return strcmp(a, b);
            });

            // Set some defaults, which we will override with values
            // from matrix.
            size = -1;
            type = IconDirectoryType.Threshold;
            max_size = -1;
            min_size = -1;
            threshold = 2;

            // Scan all icons in given directory
            create_icon_list();
            if (!valid) {
                return;
            }

            // Read values from matrix
            scan_matrix(properties);
            if (!valid) {
                return;
            }
        }

        private void scan_matrix(string[, ] matrix) {
            for (int i = 0; i < matrix.length[0]; i++) {
                string key = matrix[i, 0].down();
                if (key == "size") {
                    size = int.parse(matrix[i, 1]);
                } else if (key == "type") {
                    string val = matrix[i, 1].down();
                    if (val == "fixed") {
                        type = IconDirectoryType.Fixed;
                    } else if (val == "scalable") {
                        type = IconDirectoryType.Scalable;
                    } else if (val == "threshold") {
                        type = IconDirectoryType.Threshold;
                    }
                } else if (key == "maxsize") {
                    max_size = int.parse(matrix[i, 1]);
                } else if (key == "minsize") {
                    min_size = int.parse(matrix[i, 1]);
                } else if (key == "threshold") {
                    threshold = int.parse(matrix[i, 1]);
                }

                // It is totally okay if there are other keys.
                // Most themes include a "Context=" key.
                // But we're not interested in that.
            }

            // The only value that is mandatory to be set is 'Size'
            if (size == -1) {
                valid = false;
                return;
            }

            // If 'Type' has not been set it is already set
            // to 'Threshold'.

            // If 'Threshold' has not been set it is already set
            // to 2.

            // If 'MaxSize' or 'MinSize' has not been set
            // we set it to 'Size'.
            if (max_size == -1) {
                max_size = size;
            }
            if (min_size == -1) {
                min_size = size;
            }
        }

        private void create_icon_list() {
            GLib.File dir = GLib.File.new_for_path(directory);
            try {
                FileEnumerator child_enum = dir.enumerate_children(
                                GLib.FileAttribute.STANDARD_NAME,
                                GLib.FileQueryInfoFlags.NONE);

                GLib.FileInfo child_info;
                while ((child_info = child_enum.next_file()) != null) {
                    string child_name = child_info.get_name();
                    string child_name_d = child_name.down();

                    if (child_name_d.has_suffix(".png") ||
                        child_name_d.has_suffix(".svg") ||
                        child_name_d.has_suffix(".xpm")) {

                        string child_name_key = child_name.slice(0, child_name.length-4);

                        this.icons.insert(child_name_key, directory+"/"+child_name);
                    }
                }
            } catch (Error e) {
                // This probably means that a directory that is given
                // in the index.theme file is not present.
                // We just silently ignore this.
                valid = false;
                return;
            }
        }

        public bool is_valid() {
            return valid;
        }

        public bool is_scalable() {
            if (type == IconDirectoryType.Scalable) {
                return true;
            }
            return false;
        }

        public int maximum_size() {
            switch (type) {
            case IconDirectoryType.Fixed:
                return size;
            case IconDirectoryType.Scalable:
                return max_size;
            case IconDirectoryType.Threshold:
                return size+threshold;
            default:
                return 0;
            }
        }

        public string? get_icon(string name) {
            if (!valid) {
                return null;
            }

            string icon_path = null;
            bool found_icon = icons.lookup_extended(name, null, out icon_path);

            if (found_icon) {
                return icon_path;
            }

            return null;
        }
    }

    private enum IconDirectoryType {
        Fixed,
        Scalable,
        Threshold;
    }

    public class IconManager : GLib.Object {
        /**
         * Don't access this directly !
         * Only access it through get_current_theme()
        **/
        private static IconTheme current_theme = null;

        /**
         * This is used if the current theme does not contain the icon.
         * This is probably always 'hicolor'
        **/
        private static IconTheme fallback_theme = null;

        static construct {
            IconManager.current_theme = null;
            IconManager.fallback_theme = new IconTheme("hicolor");
        }

        private enum IconThemeProvider {
            X11,
            GNOME,
            LXDE,
            GTK3,
            GTK2
        }

        public IconManager() {
            //
        }

        private IconTheme get_current_theme() {
            lock (IconManager.current_theme) {
                // If current theme is not set at all
                // we set a new current theme.
                if (current_theme == null) {
                    // Guess the current theme
                    string? new_icon_theme = guess_current_theme_default();

                    // If we could not guess the current theme
                    // we use the fallback_theme.
                    if (new_icon_theme == null) {
                        IconManager.current_theme = IconManager.fallback_theme;
                        return IconManager.current_theme;
                    }

                    IconManager.current_theme = new IconTheme(new_icon_theme);

                    // If we guessed the current theme and it is
                    // invalid we use the fallback theme.
                    if (current_theme.is_valid() == false) {
                        IconManager.current_theme = IconManager.fallback_theme;
                    }

                    return IconManager.current_theme;
                }
            }

            // If current theme is set, we return it.
            return IconManager.current_theme;
        }

        private static string? guess_current_theme_default() {
            IconThemeProvider[] providers = { IconThemeProvider.X11,
                                              IconThemeProvider.LXDE,
                                              IconThemeProvider.GTK3,
                                              IconThemeProvider.GTK2,
                                              IconThemeProvider.GNOME };

            return guess_current_theme(providers);
        }

        private static string? guess_current_theme(IconThemeProvider[] providers) {
            // Detect theme
            string? theme = null;
            foreach (IconThemeProvider provider in providers) {
                switch (provider) {
                case IconThemeProvider.X11:
                    theme = guess_current_theme_x11();
                    break;
                case IconThemeProvider.GNOME:
                    theme = guess_current_theme_gnome();
                    break;
                case IconThemeProvider.LXDE:
                    theme = guess_current_theme_lxde();
                    break;
                case IconThemeProvider.GTK3:
                    theme = guess_current_theme_gtk3();
                    break;
                case IconThemeProvider.GTK2:
                    theme = guess_current_theme_gtk2();
                    break;
                default:
                    break;
                }

                if (theme != null) {
                    return theme;
                }
            }
            return null;
        }

        private static string? guess_current_theme_x11() {
            // Declare some constants which we need later
            const uint8 XSETTINGS_TYPE_INT = 0;
            const uint8 XSETTINGS_TYPE_STRING = 1;
            const uint8 XSETTINGS_TYPE_COLOR = 2;
            const uint8 LSBFIRST = 0;
            const uint8 MSBFIRST = 1;

            // Get default display
            X.Display default_display = new X.Display(null);
            if (default_display == null) {
                return null;
            }

            // XGrabServer()
            default_display.flush();
            default_display.grab_server();
            default_display.flush();

            // Create selection for settings
            X.Atom settings_selection1;
            settings_selection1 = default_display.intern_atom("_XSETTINGS_S0", false);

            // Get owner window of settings selection
            X.Window settings_window;
            settings_window = default_display.get_selection_owner(settings_selection1);

            // Get different selection for settings
            X.Atom settings_selection2 = default_display.intern_atom("_XSETTINGS_SETTINGS", false);

            // Get settings property using settings_selection2 from
            // owner window of settings_selection1
            X.Atom type_atom;
            int format;
            ulong n_items;
            ulong bytes_after;
            uint8* data;
            int result;

            result = default_display.get_window_property(settings_window,
                                                 settings_selection2,
                                                 0,
                                                 long.MAX,
                                                 false,
                                                 settings_selection2,
                                                 out type_atom,
                                                 out format,
                                                 out n_items,
                                                 out bytes_after,
                                                 out data);

            // XUngrabServer()
            default_display.flush();
            default_display.ungrab_server();
            default_display.flush();

            if (result != X.ErrorCode.SUCCESS) {
                X.free(data);
                return null;
            }
            if (type_atom != settings_selection2 || format != 8) {
                X.free(data);
                return null;
            }

            // Convert uint8* to uint8[]
            uint8[] data_ar = new uint8[n_items];
            for (ulong i = 0; i < n_items; i++) {
                data_ar[i] = *(data+i);
            }

            // Free original data
            X.free(data);

            // Create DataInputStream from data
            GLib.MemoryInputStream mem_is;
            mem_is = new GLib.MemoryInputStream.from_data(
                data_ar, (element) => {
                    X.free(element);
                });
            GLib.DataInputStream data_is = new GLib.DataInputStream(mem_is);

            // Read byte stream
            try {
                // Read 1B (byte-order)
                uint8 byte_order = data_is.read_byte();

                if (byte_order == LSBFIRST) {
                    data_is.set_byte_order(DataStreamByteOrder.LITTLE_ENDIAN);
                } else if (byte_order == MSBFIRST) {
                    data_is.set_byte_order(DataStreamByteOrder.BIG_ENDIAN);
                }

                // Skip 3B (unused bytes)
                data_is.skip(3);

                // Skip 4B (SERIAL)
                data_is.skip(4);

                // Read 4B (NSETTINGS)
                uint32 nsettings = data_is.read_int32();

                // Read all the settings
                for (int i = 0; i < nsettings; i++) {
                    uint8 type;
                    uint16 name_len;
                    string name = "";

                    // Read 1B (SETTING_TYPE)
                    type = data_is.read_byte();

                    // Skip 1B (unused)
                    data_is.skip(1);

                    // Read 2B (name-len)
                    name_len = data_is.read_int16();

                    // Read XB (name)
                    for (int p = 0; p < name_len; p++) {
                        name += ((char)data_is.read_byte()).to_string();
                    }

                    // Skip XB (padding)
                    {
                        uint32 pad_len = (4 - (name_len % 4)) % 4;
                        data_is.skip(pad_len);
                    }

                    // Skip 4B (last-change-serial)
                    data_is.skip(4);

                    if (type == XSETTINGS_TYPE_INT) {
                        // Skip 4B (value)
                        data_is.skip(4);
                    } else if (type == XSETTINGS_TYPE_STRING) {
                        // Read 4B (value-len)
                        uint32 value_len = (uint32)data_is.read_int32();

                        if (name == "Net/IconThemeName") {
                            // Read XB (value)
                            string value_str = "";
                            for (int p = 0; p < value_len; p++) {
                                value_str += ((char)data_is.read_byte()).to_string();
                            }

                            return value_str;
                        } else {
                            // Skip XB (value)
                            data_is.skip(value_len);
                        }

                        // Skip XB (padding)
                        uint32 pad_len = (4 - (value_len % 4)) % 4;
                        data_is.skip(pad_len);
                    } else if (type == XSETTINGS_TYPE_COLOR) {
                        // Skip 4x 2B (value)
                        data_is.skip(8);
                    }
                }
                data_is.close();
                mem_is.close();
                X.free(data);
            } catch (GLib.IOError e) {
                try { data_is.close(); } catch (Error e) { }
                try { mem_is.close(); } catch (Error e) { }
                X.free(data);

                return null;
            }
            return null;
        }

        private static string? guess_current_theme_gnome() {
            string[] argv = new string[3];
            argv[0] = "gconftool-2";
            argv[1] = "-g";
            argv[2] = "/desktop/gnome/interface/icon_theme";

            string cmd_stdout = "";
            string cmd_stderr = "";
            int exit_status = 0;

            try {
                GLib.Process.spawn_sync(null,
                                        argv,
                                        GLib.Environ.get(),
                                        SpawnFlags.SEARCH_PATH,
                                        null,
                                        out cmd_stdout,
                                        out cmd_stderr,
                                        out exit_status);

            } catch (SpawnError e) {
                return null;
            }

            // If the printed value of gconftool-2 is not valid
            // we cannot determine the icon theme via gconf (Gnome)
            if (cmd_stdout == "" || cmd_stdout == null) {
                return null;
            }

            // We remove newline control characters from stdout
            // and return it
            cmd_stdout = cmd_stdout.replace("\n", "");

            return cmd_stdout;
        }

        private static string? guess_current_theme_lxde() {
            // Look for location of desktop.conf file
            string? file_path = null;

            string session = GLib.Environment.get_variable("DESKTOP_SESSION");
            if (session == null) {
                session = "LXDE";
            }

            // Look for desktop.conf file
            // in $XDG_CONFIG_HOME/lxsession/$DESKTOP_SESSION/desktop.conf
            string? xdg_config_home = GLib.Environment.get_variable("XDG_CONFIG_HOME");
            if (xdg_config_home != null) {
                if (xdg_config_home.to_utf8()[xdg_config_home.length-1] != '/') {
                    file_path = string.join("", xdg_config_home, "/lxsession/", session, "/desktop.conf");
                } else {
                    file_path = string.join("", xdg_config_home, "lxsession/", session, "/desktop.conf");
                }

                // If desktop.conf file doesnt exists, we continue
                // searching for it.
                GLib.File file = GLib.File.new_for_path(file_path);
                if (file.query_exists() == false) {
                    file_path = null;
                }
            }

            // Look for desktop.conf file in all directories
            // in $XDG_CONFIG_DIRS
            if (file_path == null) {
                string[] environment_variables = GLib.Environment.get_variable("XDG_CONFIG_DIRS").split(":");
                foreach (string env in environment_variables) {
                    string? env_variable = GLib.Environment.get_variable(env);

                    if (env_variable != null) {
                        if (env_variable.to_utf8()[env_variable.length-1] != '/') {
                            file_path = string.join("", env_variable, "lxsession/", session, "/desktop.conf");
                        } else {
                            file_path = string.join("", env_variable, "lxsession/", session, "/desktop.conf");
                        }

                        // If desktop.conf file doesnt exists, we continue
                        // searching for it.
                        GLib.File file = GLib.File.new_for_path(file_path);
                        if (file.query_exists() == false) {
                            file_path = null;
                            continue;
                        } else {
                            break;
                        }
                    }
                }
            }

            // Lastly we look for desktop.conf file
            // in /etc/xdg/lxsession/$DESKTOP_SESSION/
            if (file_path == null) {
                file_path = "";
                file_path += "/etc/xdg/lxsession/";
                file_path += session;
                file_path += "/desktop.conf";

                GLib.File fallback_file = GLib.File.new_for_path(file_path);
                if (fallback_file.query_exists() == false) {
                    file_path = null;
                }
            }

            // If we did not find a file path for desktop.conf file
            // we cannot determine the icon theme via the LXDE
            // desktop.conf file.
            if (file_path == null) {
                return null;
            }

            // Open desktop.conf file as a KeyFile
            GLib.KeyFile file = new GLib.KeyFile();
            try {
                file.load_from_file(file_path, GLib.KeyFileFlags.NONE);
            } catch (KeyFileError e) {
                return null;
            } catch (FileError e) {
                return null;
            }

            // If file does not contain a group [GTK] we cannot use it
            // to determine icon theme
            if (!file.has_group("GTK")) {
                return null;
            }

            // If file does not have the 'sNet/IconThemeName' key inside
            // the '[GTK]' group we cannot use it to determine the
            // current icon theme.
            try {
                if (!file.has_key("GTK", "sNet/IconThemeName")) {
                    return null;
                }

                // Return the set icon theme
                string icon_theme_name = file.get_string("GTK", "sNet/IconThemeName");
                return icon_theme_name;
            } catch (KeyFileError e) {
                return null;
            }
        }

        private static string? guess_current_theme_gtk3() {
            // Look for location of settings.ini file
            string? file_path = null;

            // Look for settings.ini file in $XDG_CONFIG_HOME
            file_path = GLib.Environment.get_variable("XDG_CONFIG_HOME");
            if (file_path != null) {
                if (file_path.to_utf8()[file_path.length-1] != '/') {
                    file_path = string.join("", file_path, "/gtk-3.0/settings.ini");
                } else {
                    file_path = string.join("", file_path, "gtk-3.0/settings.ini");
                }

                // If settings.ini file doesnt exists, we continue
                // searching for it.
                GLib.File file = GLib.File.new_for_path(file_path);
                if (file.query_exists() == false) {
                    file_path = null;
                }
            }

            // Look for settings.ini file in $HOME/.config
            if (file_path == null) {
                file_path = GLib.Environment.get_variable("HOME");
                if (file_path != null) {
                    if (file_path.to_utf8()[file_path.length-1] != '/') {
                        file_path = string.join("", file_path, "/.config/gtk-3.0/settings.ini");
                    } else {
                        file_path = string.join("", file_path, ".config/gtk-3.0/settings.ini");
                    }

                    // If settings.ini file doesnt exists, we continue
                    // searching for it.
                    GLib.File file = GLib.File.new_for_path(file_path);
                    if (file.query_exists() == false) {
                        file_path = null;
                    }
                }
            }

            // Look for settings.ini file in all directories
            // in $XDG_CONFIG_DIRS
            if (file_path == null) {
                string[] environment_variables = GLib.Environment.get_variable("XDG_CONFIG_DIRS").split(":");
                foreach (string env in environment_variables) {
                    string? env_variable = GLib.Environment.get_variable(env);

                    if (env_variable != null) {
                        if (env_variable.to_utf8()[env_variable.length-1] != '/') {
                            file_path = string.join("", env_variable, "/gtk-3.0/settings.ini");
                        } else {
                            file_path = string.join("", env_variable, "gtk-3.0/settings.ini");
                        }

                        // If settings.ini file doesnt exists, we continue
                        // searching for it.
                        GLib.File file = GLib.File.new_for_path(file_path);
                        if (file.query_exists() == false) {
                            file_path = null;
                            continue;
                        } else {
                            break;
                        }
                    }
                }
            }

            // If we did not find a file path for setting.ini file
            // we cannot determine the icon theme via the gtk3
            // settings.ini file.
            if (file_path == null) {
                return null;
            }

            // Parse settings.ini file
            // and look for icon theme

            // Open settings.ini file as a KeyFile
            GLib.KeyFile file = new GLib.KeyFile();
            try {
                file.load_from_file(file_path, GLib.KeyFileFlags.NONE);
            } catch (KeyFileError e) {
                return null;
            } catch (FileError e) {
                return null;
            }

            // If file does not contain a group [Settings] it is malformed
            if (!file.has_group("Settings")) {
                return null;
            }

            // If file does not have the 'gtk-icon-theme-name' key inside
            // the '[Settings]' group we cannot use it to determine the
            // current icon theme.
            try {
                if (!file.has_key("Settings", "gtk-icon-theme-name")) {
                    return null;
                }

                // Return the set icon theme
                string icon_theme_name = file.get_string("Settings", "gtk-icon-theme-name");
                return icon_theme_name;
            } catch (KeyFileError e) {
                return null;
            }
        }

        private static string? guess_current_theme_gtk2() {
            // Look for location of .gtkrc-2.0 file
            string? file_path = null;

            // Look for .gtkrc-2.0 file in $GTK2_RC_FILE
            file_path = GLib.Environment.get_variable("GTK2_RC_FILE");
            if (file_path != null) {
                // If .gtkrc-2.0 file doesnt exists, we continue
                // searching for it.
                GLib.File file = GLib.File.new_for_path(file_path);
                if (file.query_exists() == false) {
                    file_path = null;
                }
            }

            // Look for .gtkrc-2.0 file in $HOME
            if (file_path == null) {
                file_path = GLib.Environment.get_variable("HOME");
                if (file_path != null) {
                    if (file_path.to_utf8()[file_path.length-1] != '/') {
                        file_path = string.join("", file_path, "/.gtkrc-2.0");
                    } else {
                        file_path = string.join("", file_path, ".gtkrc-2.0");
                    }

                    // If .gtkrc-2.0 file doesnt exists, we continue
                    // searching for it.
                    GLib.File file = GLib.File.new_for_path(file_path);
                    if (file.query_exists() == false) {
                        file_path = null;
                    }
                }
            }

            // If we did not find a file path for .gtkrc-2.0 file
            // we cannot determine the icon theme via the gtk2
            // .gtkrc-2.0 file.
            if (file_path == null) {
                return null;
            }

            // Parse .gtkrc-2.0 file and look for icon theme
            GLib.File file = GLib.File.new_for_path(file_path);
            GLib.FileInputStream file_i_stream;
            GLib.DataInputStream data_i_stream;
            try {
                file_i_stream = file.read();
                data_i_stream = new DataInputStream(file_i_stream);
            } catch (Error e) {
                return null;
            }

            // Identify the correct line which contains
            // gtk-icon-theme-name="theme-name".
            string line;
            bool found = false;
            try {
                while ((line = data_i_stream.read_line(null)) != null) {
                    if (line.contains("gtk-icon-theme-name")) {
                        found = true;
                        break;
                    }
                }
            } catch (IOError e) {
                return null;
            }

            // If we did not find a line containing "gtk-icon-theme-name"
            // we cannot determine the icon theme via the gtk2
            // .gtkrc-2.0 file.
            if (!found) {
                return null;
            }

            // Extract theme name out of the selected line
            line = line.strip();

            // Remove 'gtk-icon-theme-name'
            if (line.length < 19) {
                return null;
            }
            line = line.substring(19, line.length-19);
            line = line.strip();

            // Remove '='
            if (line.length < 1) {
                return null;
            }
            line = line.substring(1, line.length-1);
            line = line.strip();

            // Remove first '"'
            if (line.length < 1) {
                return null;
            }
            line = line.substring(1, line.length-1);
            line = line.strip();

            // Remove last '"'
            if (line.length < 1) {
                return null;
            }
            line = line.splice(line.length-1, line.length, "");
            line = line.strip();

            return line;
        }

        public string get_icon(string name, bool ignore_svg = false) {
            string? icon_str = null;

            // We first try to get the icon from the current theme
            icon_str = get_current_theme().get_icon(name, ignore_svg);
            if (icon_str != null) {
                return icon_str;
            }

            // Then we try to get the icon from the fallback theme
            icon_str = fallback_theme.get_icon(name, ignore_svg);
            if (icon_str != null) {
                return icon_str;
            }

            // If neither the current theme (or themes it inherits from)
            // nor the fallback theme contains the icon we need we try
            // to guess the correct icon.

            // We first test if the given icon is an actual absolute path
            GLib.File icon_file = GLib.File.new_for_path(name);
            if (icon_file.query_exists()) {
                return name;
            }

            // We also search in '/usr/share/pixmaps'
            string icon_file_path = "/usr/share/pixmaps/"+name;
            icon_file = GLib.File.new_for_path(icon_file_path);
            if (icon_file.query_exists()) {
                return icon_file_path;
            }

            // If icon is not null but we still cant find it
            // we use an fallback icon
            icon_str = get_current_theme().get_icon("application-x-executable", ignore_svg);
            return icon_str;
        }
    }

    public class App: GLib.Object {

        private string? desktop_file = null;
        private string app_name;
        private string? app_generic_name = null;
        private string app_exec;
        private string[]? app_categories = null;
        private string app_comment;
        private string? app_icon = null;
        private string? app_icon_path = null;
        private string? app_path = null;
        private bool app_terminal;

        private bool valid = true;

        public App(string desktopfile, IconManager icon_manager) {
            // Parse the given desktopfile
            parse_desktopfile(desktopfile);
            if (!valid) {
                return;
            }

            // Try to get the absolute path of the icon file
            // (We don't want svg)
            // If we don't have an icon we use fallback
            // If fallback does not exist, we have no icon.
            if (app_icon == null) {
                this.app_icon_path = icon_manager.get_icon("application-x-executable", true);
            } else {
                this.app_icon_path = icon_manager.get_icon(app_icon, true);
            }
        }

        public string get_desktop_file() {
            return desktop_file;
        }

        public string get_name() {
            return app_name;
        }

        public string? get_generic() {
            return app_generic_name;
        }

        public string[]? get_categories() {
        return app_categories;
        }

        public string get_comment() {
            return app_comment;
        }

        public string? get_icon() {
            return app_icon;
        }

        public string? get_icon_path() {
            return app_icon_path;
        }

        private void parse_desktopfile(string? path) {
            //Open KeyFile
            this.desktop_file = path;
            GLib.KeyFile kf = new GLib.KeyFile();
            if (path == null) {
                valid = false;
                return;
            }

            try {
                kf.load_from_file(path, GLib.KeyFileFlags.NONE);
            }
            catch (KeyFileError e) {
                valid = false;
                return;
            }
            catch (FileError e) {
                valid = false;
                return;
            }

            //Test if KeyFile is valid & load keys
            try {
                if (!kf.has_group("Desktop Entry")) {
                    valid = false;
                    return;
                }

                // --- <Name>
                try {
                    app_name = kf.get_value("Desktop Entry", "Name");
                } catch (KeyFileError e) {
                    valid = false;
                    return;
                }

                // --- <Type>
                if (!kf.has_key("Desktop Entry", "Type") || kf.get_value("Desktop Entry", "Type") != "Application") {
                    valid = false;
                    return;
                }

                // --- <Exec>
                try {
                    app_exec = kf.get_value("Desktop Entry", "Exec");
                } catch (KeyFileError e) {
                    valid = false;
                    return;
                }

                // --- <NoDisplay>
                if (kf.has_key("Desktop Entry", "NoDisplay")) {
                    if (kf.get_value("Desktop Entry", "NoDisplay") == "true") {
                        valid = false;
                        return;
                    }
                }

                // --- <Hidden>
                if (kf.has_key("Desktop Entry", "Hidden")) {
                    if (kf.get_value("Desktop Entry", "Hidden") == "true") {
                        valid = false;
                        return;
                    }
                }

                // --- <GenericName>
                try {
                    app_generic_name = kf.get_value("Desktop Entry", "GenericName");
                } catch (KeyFileError e) {

                }

                // --- <Comment>
                try {
                    app_comment = kf.get_value("Desktop Entry", "Comment");
                } catch (KeyFileError e) {

                }

                // --- <Icon>
                try {
                    app_icon = kf.get_value("Desktop Entry", "Icon");
                } catch (KeyFileError e) {

                }

                // --- <Categories>
                try {
                    app_categories = kf.get_value("Desktop Entry", "Categories").split_set(";", 0);
                } catch (KeyFileError e) {

                }

                // --- <Path>
                try {
                    app_path = kf.get_value("Desktop Entry", "Path");
                } catch (KeyFileError e) {

                }

                // --- <Terminal>
                if (kf.has_key("Desktop Entry", "Terminal")) {
                    if (kf.get_value("Desktop Entry", "Terminal") == "true") {
                        app_terminal = true;
                    }
                }

            }
            catch (KeyFileError e) {
                valid = false;
                return;
            }

        }

        public bool is_valid() {
            return valid;
        }

        public void start() {
            //TODO:
            //FIXME:
            // - Pay attention to applications with "Terminal" flag set to "true"
            // - Pay attention to applications with "Path" flag set
            // - Pay attention to applications with "TryExec" flag set

            //Remove unused arguments specified in desktopFiles,
            //which confuse spawn_command_line_async() method
            //
            //These are not arguments to be given to the programm,
            //but hints for programms managing desktopFiles what
            //types of data this programm can open.
            //
            //We should NOT pass these values to the programm.
            string exec_string = this.app_exec;
            string[] suffixes = { "%f", "%F", "%u", "%U", "%d", "%D", "%n",
                                  "%N", "%i", "%c", "%k", "%v", "%m" };
            foreach (string suffix in suffixes) {
                exec_string = exec_string.replace(suffix, "");
            }

            //Start program
            try {

                GLib.Pid pid;
                string[] argvp;
                try {
                    GLib.Shell.parse_argv(exec_string, out argvp);
                } catch (GLib.ShellError e) {
                    return;
                }

                GLib.Process.spawn_async_with_pipes(
                                        app_path,
                                        argvp,
                                        GLib.Environ.get(),
                                        SpawnFlags.SEARCH_PATH |
                                        SpawnFlags.STDOUT_TO_DEV_NULL |
                                        SpawnFlags.STDERR_TO_DEV_NULL,
                                        null,
                                        out pid,
                                        null,
                                        null,
                                        null);

            } catch (SpawnError e) {
            }
        }
    }

    public class AppIcon: Gtk.Box {

        public signal void started();

        private App app;

        public AppIcon(App app) {
            Object(orientation: Gtk.Orientation.VERTICAL);

            this.app = app;

            this.build_gui();
        }

        private void drag_begin_cb(Gtk.Widget widget, Gdk.DragContext context) {
            Gdk.Pixbuf pixbuf = new Gdk.Pixbuf.from_file_at_size(this.app.get_icon_path(), 48, 48);
            Gtk.drag_set_icon_pixbuf(context, pixbuf, 24, 24);
        }

        private void drag_data_get_cb(Gtk.Widget widget, Gdk.DragContext context,
                                      Gtk.SelectionData selection_data,
                                      uint target_type, uint time) {

            string? data = this.app.get_desktop_file();
            if (target_type == Target.STRING && data != null) {
                selection_data.set(
                    selection_data.get_target(),
                    BYTE_BITS,
                    (uchar[])data.to_utf8());

            } else {
                GLib.assert_not_reached();
            }
        }

        private void convert_long_to_bytes(long number, out uchar [] buffer) {
            buffer = new uchar[sizeof(long)];
            for (int i=0; i<sizeof(long); i++) {
                buffer[i] = (uchar) (number & 0xFF);
                number = number >> 8;
            }
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

            Gtk.drag_source_set(
                button,
                Gdk.ModifierType.BUTTON1_MASK,
                apps_target_list,
                Gdk.DragAction.COPY);

            button.drag_begin.connect(this.drag_begin_cb);
            button.drag_data_get.connect(this.drag_data_get_cb);

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

    public class AppGrid: Gtk.Grid {

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
