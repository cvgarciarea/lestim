VALAC = valac
VAPIS = --vapidir=./vapis
VALAPKG = --pkg gtk+-3.0 \
          --pkg gdk-3.0 \
          --pkg gee-0.8 \
          --pkg gdk-pixbuf-2.0 \
          --pkg libgnome-menu \
          --pkg gio-unix-2.0

SRC = Lestim.vala \
      globals.vala \
      panel.vala \
      widgets.vala \
      lateral_panel.vala \
      settings_window.vala \
      apps_view.vala \
      icon_view.vala

OPTIONS = -X "-DGMENU_I_KNOW_THIS_IS_UNSTABLE"
BIN = lestim

all:
	$(VALAC) $(VAPIS) $(VALAPKG) $(SRC) $(OPTIONS) -o $(BIN)

clean:
	rm -f $(BIN)

