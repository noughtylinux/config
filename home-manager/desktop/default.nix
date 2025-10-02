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
  catppuccinThemeGtk = noughtyConfig.catppuccin.gtk or false;
  catppuccinThemeQt = noughtyConfig.catppuccin.qt or false;
  clockFormat = "24h";
  cursorSize = 32;
  desktopShell = catppuccinThemeGtk || catppuccinThemeQt;
in
{
  imports = [
    ./apps/browser
    ./apps/terminal
    ./compositor/hyprland
  ];

  catppuccin = {
    kvantum.enable = catppuccinThemeQt;
    cursors.enable = true;
  };

  # Packages whose D-Bus configuration files should be included in the
  # configuration of the D-Bus session-wide message bus.
  # pinentry-gnome3 may not work on non-GNOME systems, but can be fixed by
  # the following:
  dbus = {
    packages = [ pkgs.gcr ];
  };

  dconf.settings = with lib.hm.gvariant; {
    "org/gnome/desktop/interface" = {
      clock-format = clockFormat;
      color-scheme = if noughtyConfig.catppuccin.palette.isDark then "prefer-dark" else "prefer-light";
      cursor-size = cursorSize;
      cursor-theme = config.home.pointerCursor.name;
      document-font-name = config.gtk.font.name or "Work Sans 13";
      gtk-enable-primary-paste = true;
      gtk-theme = config.gtk.theme.name;
      icon-theme = "Papirus-Dark";
      monospace-font-name = "FiraCode Nerd Font Mono Medium 13";
      text-scaling-factor = 1.0;
    };

    "org/gnome/desktop/sound" = {
      theme-name = "freedesktop";
    };

    "org/gnome/desktop/wm/preferences" = {
      button-layout = "${buttonLayout}";
      theme = config.gtk.theme.name;
    };

    "org/gtk/gtk4/Settings/FileChooser" = {
      clock-format = clockFormat;
    };

    "org/gtk/Settings/FileChooser" = {
      clock-format = clockFormat;
    };
  };

  home = {
    sessionVariables = {
      GDK_BACKEND = "wayland,x11";
      MOZ_ENABLE_WAYLAND = "1";
      NIXOS_OZONE_WL = "1";
      QT_QPA_PLATFORM = "wayland;xcb";
      QT_STYLE_OVERRIDE = "kvantum";
      QT_WAYLAND_DISABLE_WINDOWDECORATION = if config.wayland.windowManager.hyprland.enable then 1 else 0;
    };
  };

  gtk = {
    enable = catppuccinThemeGtk;
    font = {
      name = "Work Sans";
      size = 13;
      package = pkgs.work-sans;
    };
    gtk2 = {
      configLocation = "${config.xdg.configHome}/.gtkrc-2.0";
      extraConfig = ''
        gtk-application-prefer-dark-theme = "${noughtyConfig.catppuccin.palette.isDark}"
        gtk-button-images = 1
        gtk-decoration-layout = "${buttonLayout}"
      '';
    };
    gtk3 = {
      extraConfig = {
        gtk-application-prefer-dark-theme = noughtyConfig.catppuccin.palette.isDark;
        gtk-button-images = 1;
        gtk-decoration-layout = "${buttonLayout}";
      };
    };
    gtk4 = {
      extraConfig = {
        gtk-decoration-layout = "${buttonLayout}";
      };
    };
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.catppuccin-papirus-folders.override {
        flavor = config.catppuccin.flavor;
        accent = config.catppuccin.accent;
      };
    };
    theme = {
      name = "catppuccin-${config.catppuccin.flavor}-${config.catppuccin.accent}-standard";
      package = pkgs.catppuccin-gtk.override {
        accents = [ "${config.catppuccin.accent}" ];
        size = "standard";
        variant = config.catppuccin.flavor;
      };
    };
  };

  home = {
    packages =
      with pkgs;
      [
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
        kdePackages.qt6ct
        kdePackages.qtstyleplugin-kvantum
        libsForQt5.qt5ct
        libsForQt5.qtstyleplugin-kvantum
        loupe
        nautilus
        overskride
        papers
        pwvucontrol
        resources
        seahorse
        simple-scan
        system-config-printer
        wdisplays
        wlr-randr
        wl-clipboard
        wtype
      ]
      ++ (map (pkg: pkgs.${pkg}) (noughtyConfig.desktop.packages or [ ]));

    pointerCursor = {
      dotIcons.enable = true;
      gtk.enable = catppuccinThemeGtk;
      hyprcursor = {
        enable = config.wayland.windowManager.hyprland.enable;
        size = cursorSize;
      };
      size = cursorSize;
      x11.enable = desktopShell;
    };
  };

  qt = {
    enable = catppuccinThemeQt;
    platformTheme = {
      name = config.qt.style.name;
    };
    style = {
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

  xdg = {
    autostart = {
      enable = true;
    };
    configFile = {
      qt5ct = {
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
      qt6ct = {
        name = "Qt6 Settings";
        noDisplay = true;
      };
    };
    portal = {
      config = {
        common = {
          default =
            if config.wayland.windowManager.hyprland.enable then
              [
                "hyprland"
                "gtk"
              ]
            else
              [ "gtk" ];
          # For "Open With" dialogs. GTK portal provides the familiar GNOME-style app chooser.
          "org.freedesktop.impl.portal.AppChooser" = [ "gtk" ];
          "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
          # Inhibit is useful for preventing sleep during media playback
          "org.freedesktop.impl.portal.Inhibit" = [ "gtk" ];
          # GTK portal gives you proper print dialogs.
          "org.freedesktop.impl.portal.Print" = [ "gtk" ];
          # Security/credentials
          "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
          # GTK portal provides desktop settings that GTK apps query (fonts, themes, colour schemes).
          "org.freedesktop.impl.portal.Settings" = [ "gtk" ];
        };
      };
      # Add xset to satisfy xdg-screensaver requirements
      configPackages = [
        pkgs.xorg.xset
      ];
      enable = true;
      extraPortals = [
        pkgs.xdg-desktop-portal
        pkgs.xdg-desktop-portal-gtk
      ]
      ++ lib.optionals config.wayland.windowManager.hyprland.enable [
        pkgs.xdg-desktop-portal-hyprland
      ];
      xdgOpenUsePortal = true;
    };
  };
}
