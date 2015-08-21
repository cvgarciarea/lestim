VALAC = valac
VAPIS = --vapidir=./vapis
VALAPKG = --pkg gtk+-3.0 \
          --pkg gdk-3.0 \
          --pkg gee-0.8 \
          --pkg gdk-pixbuf-2.0 \
          --pkg libgnome-menu \
          --pkg gio-unix-2.0

SRC = src/lestim.vala \
      src/wallpaper_window.vala \
      src/dock.vala \
      src/widgets.vala \
      src/panel.vala \
      src/settings_window.vala \
      src/apps_view.vala \
      src/icon_view.vala \
      src/globals.vala

OPTIONS = -X "-DGMENU_I_KNOW_THIS_IS_UNSTABLE"
BIN = lestim

all:
	$(VALAC) $(VAPIS) $(VALAPKG) $(SRC) $(OPTIONS) -o $(BIN)

clean:
	rm -f $(BIN)

