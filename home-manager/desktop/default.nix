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
  blues = [
    "blue"
    "sky"
    "sapphire"
    "lavender"
  ];
  pinks = [
    "pink"
    "rosewater"
    "flamingo"
  ];
  reds = [
    "red"
    "maroon"
  ];
  themeAccent =
    if lib.elem noughtyConfig.catppuccin.accent blues then
      ""
    else if noughtyConfig.catppuccin.accent == "green" then
      "-Green"
    else if noughtyConfig.catppuccin.accent == "peach" then
      "-Orange"
    else if lib.elem noughtyConfig.catppuccin.accent pinks then
      "-Pink"
    else if noughtyConfig.catppuccin.accent == "mauve" then
      "-Purple"
    else if lib.elem noughtyConfig.catppuccin.accent reds then
      "-Red"
    else if noughtyConfig.catppuccin.accent == "teal" then
      "-Teal"
    else if noughtyConfig.catppuccin.accent == "yellow" then
      "-Yellow"
    else
      "";
  themeShade = if noughtyConfig.catppuccin.palette.isDark then "-Dark" else "-Light";
  gtkThemeName = "Colloid${themeAccent}${themeShade}-Catppuccin";
  preferDark = noughtyConfig.catppuccin.palette.isDark;
  preferDarkDconf = if preferDark then "prefer-dark" else "prefer-light";
  preferDarkStr = if preferDark then "1" else "0";
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
      color-scheme = preferDarkDconf;
      cursor-size = cursorSize;
      cursor-theme = config.home.pointerCursor.name;
      document-font-name = config.gtk.font.name or "Work Sans 13";
      gtk-enable-primary-paste = true;
      gtk-theme = config.gtk.theme.name;
      icon-theme = config.gtk.iconTheme.name;
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
        gtk-application-prefer-dark-theme = "${preferDarkStr}"
        gtk-button-images = 1
        gtk-decoration-layout = "${buttonLayout}"
      '';
    };
    gtk3 = {
      extraConfig = {
        gtk-application-prefer-dark-theme = preferDark;
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
      name = gtkThemeName;
      package = pkgs.unstable.colloid-gtk-theme.override {
        colorVariants = [
          "standard"
          "light"
          "dark"
        ];
        sizeVariants = [
          "standard"
          "compact"
        ];
        themeVariants = [ "all" ];
        tweaks = [ "catppuccin" ];
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
    gnome-keyring = {
      enable = true;
    };
    # https://nixos.wiki/wiki/Bluetooth#Using_Bluetooth_headsets_with_PulseAudio
    # This is managed by Ubuntu
    mpris-proxy = {
      enable = lib.mkForce false;
    };
    polkit-gnome = {
      enable = true;
    };
    udiskie = {
      enable = true;
      automount = false;
      tray = "auto";
      notify = true;
    };
  };

  # XDG Desktop Portal systemd services - required on non-NixOS
  systemd.user.services = {
    xdg-desktop-portal = {
      Unit = {
        Description = "Portal service (Flatpak and others)";
        Documentation = "man:xdg-desktop-portal(1)";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };
      Service = {
        Type = "dbus";
        BusName = "org.freedesktop.portal.Desktop";
        ExecStart = "${pkgs.xdg-desktop-portal}/libexec/xdg-desktop-portal";
        Restart = "on-failure";
      };
      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };

    xdg-desktop-portal-gtk = {
      Unit = {
        Description = "Portal service (GTK/GNOME implementation)";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };
      Service = {
        Type = "dbus";
        BusName = "org.freedesktop.impl.portal.desktop.gtk";
        ExecStart = "${pkgs.xdg-desktop-portal-gtk}/libexec/xdg-desktop-portal-gtk";
        Restart = "on-failure";
        Slice = "session.slice";
      };
      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };

    xdg-desktop-portal-hyprland = lib.mkIf config.wayland.windowManager.hyprland.enable {
      Unit = {
        Description = "Portal service (Hyprland implementation)";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
        ConditionEnvironment = "WAYLAND_DISPLAY";
      };
      Service = {
        Type = "dbus";
        BusName = "org.freedesktop.impl.portal.desktop.hyprland";
        ExecStart = "${pkgs.xdg-desktop-portal-hyprland}/libexec/xdg-desktop-portal-hyprland";
        Restart = "on-failure";
        Slice = "session.slice";
      };
      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };

    xdg-document-portal = {
      Unit = {
        Description = "Portal service (document access for sandboxed apps)";
        Documentation = "man:xdg-document-portal(1)";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };
      Service = {
        Type = "dbus";
        BusName = "org.freedesktop.portal.Documents";
        ExecStart = "${pkgs.xdg-desktop-portal}/libexec/xdg-document-portal";
        Restart = "on-failure";
      };
      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };

    xdg-permission-store = {
      Unit = {
        Description = "Permission store for XDG desktop portals";
        Documentation = "man:xdg-permission-store(1)";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };
      Service = {
        Type = "dbus";
        BusName = "org.freedesktop.impl.portal.PermissionStore";
        ExecStart = "${pkgs.xdg-desktop-portal}/libexec/xdg-permission-store";
        Restart = "on-failure";
      };
      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
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
            icon_theme = config.gtk.iconTheme.name;
          };
        };
      };
      qt6ct = {
        target = "qt6ct/qt6ct.conf";
        text = lib.generators.toINI { } {
          Appearance = {
            icon_theme = config.gtk.iconTheme.name;
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
