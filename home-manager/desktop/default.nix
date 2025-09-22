{
  config,
  lib,
  noughtyConfig,
  pkgs,
  ...
}:
let
  buttonLayout =
    if config.wayland.windowManager.hyprland.enable then "appmenu" else "close,minimize,maximize";
  catppuccinAccent = noughtyConfig.catppuccin.accent or "blue";
  catppuccinFlavor = noughtyConfig.catppuccin.flavor or "mocha";
  # Create a Catppuccin cursor package name like "mochaBlue"
  catppuccinCursorPkg =
    catppuccinFlavor
    + (lib.strings.toUpper (builtins.substring 0 1 catppuccinAccent))
    + (builtins.substring 1 (-1) catppuccinAccent);
  catppuccinThemeGtk = noughtyConfig.catppuccin.gtk or false;
  catppuccinThemeQt = noughtyConfig.catppuccin.qt or false;
in
{
  # Catppuccin is not enabled for everything by default
  # I have custom Catppuccin themes for some programs
  catppuccin = {
    accent = catppuccinAccent;
    flavor = catppuccinFlavor;
    kvantum.enable = config.qt.enable;
  };

  dconf.settings = with lib.hm.gvariant; {
    "org/gnome/desktop/interface" = lib.mkIf catppuccinThemeGtk {
      color-scheme = "prefer-dark";
      cursor-size = 32;
      cursor-theme = "catppuccin-${config.catppuccin.flavor}-${config.catppuccin.accent}-cursors";
      gtk-theme = "catppuccin-${config.catppuccin.flavor}-${config.catppuccin.accent}-standard";
      icon-theme = "Papirus-Dark";
    };

    "org/gnome/desktop/wm/preferences" = lib.mkIf catppuccinThemeGtk {
      button-layout = "${buttonLayout}";
      theme = "catppuccin-${config.catppuccin.flavor}-${config.catppuccin.accent}-standard";
    };
  };

  gtk = {
    cursorTheme = lib.mkIf catppuccinThemeGtk {
      name = "catppuccin-${config.catppuccin.flavor}-${config.catppuccin.accent}-cursors";
      package = pkgs.catppuccin-cursors.${catppuccinCursorPkg};
      size = 32;
    };
    enable = true;
    font = lib.mkIf catppuccinThemeGtk {
      name = "Work Sans 12";
      package = pkgs.work-sans;
    };
    gtk2 = {
      configLocation = "${config.xdg.configHome}/.gtkrc-2.0";
      extraConfig = ''
        gtk-application-prefer-dark-theme = 1
        gtk-button-images = 1
        gtk-decoration-layout = "${buttonLayout}"
      '';
    };
    gtk3 = {
      extraConfig = {
        gtk-application-prefer-dark-theme = 1;
        gtk-button-images = 1;
        gtk-decoration-layout = "${buttonLayout}";
      };
    };
    gtk4 = {
      extraConfig = {
        gtk-decoration-layout = "${buttonLayout}";
      };
    };
    iconTheme = lib.mkIf catppuccinThemeGtk {
      name = "Papirus-Dark";
      package = pkgs.catppuccin-papirus-folders.override {
        flavor = config.catppuccin.flavor;
        accent = config.catppuccin.accent;
      };
    };
    theme = lib.mkIf catppuccinThemeGtk {
      name = "catppuccin-${config.catppuccin.flavor}-${config.catppuccin.accent}-standard";
      package = pkgs.catppuccin-gtk.override {
        accents = [ "${config.catppuccin.accent}" ];
        size = "standard";
        variant = config.catppuccin.flavor;
      };
    };
  };

  home = lib.mkIf (catppuccinThemeQt || catppuccinThemeGtk) {
    packages = with pkgs; [
      (catppuccin-kvantum.override {
        accent = config.catppuccin.accent;
        variant = config.catppuccin.flavor;
      })
      libsForQt5.qtstyleplugin-kvantum
      libsForQt5.qt5ct
      papirus-folders
    ];

    pointerCursor = {
      name = "catppuccin-${config.catppuccin.flavor}-${config.catppuccin.accent}-cursors";
      package = pkgs.catppuccin-cursors.${catppuccinCursorPkg};
      size = 32;
      gtk.enable = true;
      x11.enable = true;
    };
  };

  qt = lib.mkIf catppuccinThemeQt {
    enable = true;
    platformTheme.name = "kvantum";
    style = {
      name = "kvantum";
    };
  };

  systemd.user.sessionVariables = lib.mkIf catppuccinThemeQt {
    QT_STYLE_OVERRIDE = "kvantum";
  };

  xdg.configFile = lib.mkIf catppuccinThemeQt {
    qt5ct = {
      target = "qt5ct/qt5ct.conf";
      text = lib.generators.toINI { } {
        Appearance = {
          icon_theme = "Papirus-Dark";
        };
      };
    };
    qt6ct = {
      target = "qt6ct/qt6ct.conf";
      text = lib.generators.toINI { } {
        Appearance = {
          icon_theme = "Papirus-Dark";
        };
      };
    };
  };
}
