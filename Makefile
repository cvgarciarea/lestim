VALAC = valac
VAPIS = --vapidir=./vapis
VALAPKG = --pkg gtk+-3.0 \
          --pkg gdk-3.0 \
          --pkg gee-0.8 \
          --pkg gdk-pixbuf-2.0 \
          --pkg libgnome-menu-3.0 \
          --pkg gio-unix-2.0

LIBS_SRC = src/libs/pulse.vala
LTK_SRC = src/ltk/calendar.vala \
          src/ltk/apps_grid.vala

SRC = src/lestim.vala \
      src/background_window.vala \
      src/dock.vala \
      src/widgets.vala \
      src/panel.vala \
      src/settings_window.vala \
      src/apps_view.vala \
      src/globals.vala

OPTIONS = -X "-DGMENU_I_KNOW_THIS_IS_UNSTABLE" --target-glib 2.32 #--disable-warnings
BIN = lestim

BIN_DIR = /usr/share/lestim
BIN_DESTINATION = /usr/share/lestim/lestim
LOCAL_EXECUTABLE = data/lestim
SYSTEM_EXECUTABLE = /usr/bin/lestim
DESKTOP_FILE = data/lestim.desktop
DESKTOP_FILE_DESTINATION = /usr/share/xsessions/lestim.desktop
DOCK_GSCHEMA = data/org.lestim.dock.gschema.xml
PANEL_GSCHEMA = data/org.lestim.panel.gschema.xml
GSCHEMAS_DIR = /usr/share/glib-2.0/schemas/

all:
	echo "Starting compilation"
	$(VALAC) $(VAPIS) $(VALAPKG) $(LIBS_SRC) $(LTK_SRC) $(SRC) $(OPTIONS) -o $(BIN)
	echo "Compilation finished successfully"

clean:
	rm -f $(BIN)

install: all
	echo "Starting the installation"
	mkdir -p $(BIN_DIR)
	cp $(BIN) $(BIN_DESTINATION)
	chmod +x $(BIN_DESTINATION)
	cp $(LOCAL_EXECUTABLE) $(SYSTEM_EXECUTABLE)
	chmod +x $(SYSTEM_EXECUTABLE)
	cp $(DESKTOP_FILE) $(DESKTOP_FILE_DESTINATION)
	cp $(DOCK_GSCHEMA) $(GSCHEMAS_DIR)
	cp $(PANEL_GSCHEMA) $(GSCHEMAS_DIR)
	glib-compile-schemas $(GSCHEMAS_DIR)
	echo "Installation finished successfully"

