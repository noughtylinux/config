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
  imports = [
    ./apps/browser
    ./apps/terminal
    ./compositor/hyprland
  ];

  catppuccin = {
    kvantum.enable = catppuccinThemeQt;
  };

  # Packages whose D-Bus configuration files should be included in the
  # configuration of the D-Bus session-wide message bus.
  # pinentry-gnome3 may not work on non-GNOME systems, but can be fixed by
  # the following:
  dbus = {
    packages = [ pkgs.gcr ];
  };

  dconf.settings = with lib.hm.gvariant; {
    "org/gnome/desktop/interface" = lib.mkIf catppuccinThemeGtk {
      clock-format = "24h";
      color-scheme = "prefer-dark";
      cursor-size = 32;
      cursor-theme = "catppuccin-${config.catppuccin.flavor}-${config.catppuccin.accent}-cursors";
      document-font-name = config.gtk.font.name or "Fira Sans 12";
      gtk-enable-primary-paste = true;
      gtk-theme = "catppuccin-${config.catppuccin.flavor}-${config.catppuccin.accent}-standard";
      icon-theme = "Papirus-Dark";
      monospace-font-name = "FiraCode Nerd Font Mono Medium 13";
      text-scaling-factor = 1.0;
    };

    "org/gnome/desktop/sound" = {
      theme-name = "freedesktop";
    };

    "org/gnome/desktop/wm/preferences" = lib.mkIf catppuccinThemeGtk {
      button-layout = "${buttonLayout}";
      theme = "catppuccin-${config.catppuccin.flavor}-${config.catppuccin.accent}-standard";
    };

    "org/gtk/gtk4/Settings/FileChooser" = {
      clock-format = "24h";
    };

    "org/gtk/Settings/FileChooser" = {
      clock-format = "24h";
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
      name = "Fira Sans";
      size = 12;
      package = pkgs.fira-sans;
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
      celluloid
      dconf-editor
      decibels
      file-roller
      gnome-calculator
      gnome-disk-utility
      gnome-font-viewer
      libsForQt5.qtstyleplugin-kvantum
      libsForQt5.qt5ct
      loupe
      nautilus
      overskride
      papers
      papirus-folders
      pwvucontrol
      resources
      seahorse
      simple-scan
      system-config-printer
      wdisplays
      wlr-randr
      wl-clipboard
      wtype
    ];

    pointerCursor = {
      name = "catppuccin-${config.catppuccin.flavor}-${config.catppuccin.accent}-cursors";
      package = pkgs.catppuccin-cursors.${catppuccinCursorPkg};
      size = 32;
      gtk.enable = true;
      x11.enable = true;
    };
  };

  qt = {
    enable = true;
    platformTheme = lib.mkIf catppuccinThemeQt {
      name = "kvantum";
    };
    style = lib.mkIf catppuccinThemeQt {
      name = "kvantum";
    };
  };

  services = {
    # https://nixos.wiki/wiki/Bluetooth#Using_Bluetooth_headsets_with_PulseAudio
    # This is managed by the Ubuntu-pre setup
    mpris-proxy = {
      enable = false;
    };
    gnome-keyring = {
      enable = true;
    };
    udiskie = {
      enable = true;
      automount = false;
      tray = "auto";
      notify = true;
    };
  };

  systemd.user.sessionVariables = lib.mkIf catppuccinThemeQt {
    QT_STYLE_OVERRIDE = "kvantum";
  };

  xdg = {
    autostart = {
      enable = true;
    };
    configFile = {
      qt5ct = lib.mkIf catppuccinThemeQt {
        target = "qt5ct/qt5ct.conf";
        text = lib.generators.toINI { } {
          Appearance = {
            icon_theme = "Papirus-Dark";
          };
        };
      };
      qt6ct = lib.mkIf catppuccinThemeQt {
        target = "qt6ct/qt6ct.conf";
        text = lib.generators.toINI { } {
          Appearance = {
            icon_theme = "Papirus-Dark";
          };
        };
      };
    };
    desktopEntries = {
      kvantummanager = {
        name = "Kvantum Manager";
        noDisplay = true;
      };
      qt5ct = {
        name = "Qt5 Settings";
        noDisplay = true;
      };
    };
    portal = {
      config = {
        common = {
          default = [
            "gtk"
          ];
          "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
        };
      };
      # Add xset to satisfy xdg-screensaver requirements
      configPackages = [
        pkgs.xorg.xset
      ];
      enable = true;
      xdgOpenUsePortal = true;
    };
  };
}
