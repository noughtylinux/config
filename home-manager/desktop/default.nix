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
  clockFormat = "24h";
  cursorSize = 32;
  desktopCompositor = noughtyConfig.desktop.compositor;
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

  audioPlayer = [ "org.gnome.Decibels.desktop" ];
  archiveManager = [ "org.gnome.FileRoller.desktop" ];
  documentViewer = [ "org.gnome.Papers.desktop" ];
  imageViewer = [ "org.gnome.Loupe.desktop" ];
  videoPlayer = [ "io.github.celluloid_player.Celluloid.desktop" ];
  # Packages whose D-Bus configuration files should be included in the
  # configuration of the D-Bus session-wide message bus.
  dbusPackages = with pkgs; [
    celluloid # video player
    dconf-editor # dconf GUI editor
    decibels # audio player
    file-roller # archive manager
    gcr # pinentry-gnome3 may not work on non-GNOME systems, without gcr registered on D-Bus
    gnome-calculator
    gnome-disk-utility
    gnome-font-viewer
    loupe # image viewer
    nautilus # file manager
    papers # document viewer
    resources # monitor system resources
    seahorse # GNOME keyring
    system-config-printer # printer configuration
    sushi # file previewer
  ];
in
{
  imports =
    lib.optionals (desktopCompositor != null) [
      ./apps/browser
      ./apps/terminal
    ]
    ++ lib.optional (builtins.pathExists (
      ./. + "compositor/${desktopCompositor}"
    )) ./compositor/${desktopCompositor};

  # Gate all desktop configuration on compositor being set
  config = lib.mkIf (desktopCompositor != null) {
    catppuccin = {
      kvantum.enable = true;
      cursors.enable = true;
    };

    # Packages whose D-Bus configuration files should be included in the
    # configuration of the D-Bus session-wide message bus.
    dbus = {
      packages = dbusPackages;
    };

    dconf.settings = with lib.hm.gvariant; {
      "io/github/celluloid-player/celluloid" = {
        csd-enable = false;
        dark-theme-enable = noughtyConfig.catppuccin.palette.isDark;
      };
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
      sessionPath = [
        "/usr/lib/gvfs"
      ];
      sessionVariables = {
        GDK_BACKEND = "wayland,x11";
        GIO_EXTRA_MODULES =
          if pkgs.stdenv.hostPlatform.isx86_64 then
            "/usr/lib/x86_64-linux-gnu/gio/modules"
          else if pkgs.stdenv.hostPlatform.isAarch64 then
            "/usr/lib/aarch64-linux-gnu/gio/modules"
          else
            throw "Unsupported architecture for Ubuntu gvfs integration";
        MOZ_ENABLE_WAYLAND = "1";
        NAUTILUS_4_EXTENSION_DIR = "${pkgs.nautilus-python}/lib/nautilus/extensions-4";
        NIXOS_OZONE_WL = "1";
        QT_QPA_PLATFORM = "wayland;xcb";
        QT_STYLE_OVERRIDE = "kvantum";
        QT_WAYLAND_DISABLE_WINDOWDECORATION = if config.wayland.windowManager.hyprland.enable then 1 else 0;
      };
    };

    gtk = {
      enable = true;
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
          gnome-firmware
          kdePackages.qt6ct
          kdePackages.qtstyleplugin-kvantum
          libsForQt5.qt5ct
          libsForQt5.qtstyleplugin-kvantum
          nautilus-python
          nautilus-open-any-terminal
          overskride
          pwvucontrol
          simple-scan
          wdisplays
          wlr-randr
          wl-clipboard
          wtype
        ]
        ++ (map (pkg: pkgs.${pkg}) (noughtyConfig.desktop.packages or [ ]))
        ++ dbusPackages;

      pointerCursor = {
        dotIcons.enable = true;
        gtk.enable = true;
        hyprcursor = {
          enable = config.wayland.windowManager.hyprland.enable;
          size = cursorSize;
        };
        size = cursorSize;
        x11.enable = true;
      };
    };

    qt = {
      enable = true;
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
      mimeApps = {
        enable = true;
        associations.added = {
          "application/x-7z-compressed" = archiveManager;
          "application/x-7z-compressed-tar" = archiveManager;
          "application/x-bzip" = archiveManager;
          "application/x-bzip-compressed-tar" = archiveManager;
          "application/x-compress" = archiveManager;
          "application/x-compressed-tar" = archiveManager;
          "application/x-cpio" = archiveManager;
          "application/x-gzip" = archiveManager;
          "application/x-lha" = archiveManager;
          "application/x-lzip" = archiveManager;
          "application/x-lzip-compressed-tar" = archiveManager;
          "application/x-lzma" = archiveManager;
          "application/x-lzma-compressed-tar" = archiveManager;
          "application/x-tar" = archiveManager;
          "application/x-tarz" = archiveManager;
          "application/x-xar" = archiveManager;
          "application/x-xz" = archiveManager;
          "application/x-xz-compressed-tar" = archiveManager;
          "application/zip" = archiveManager;
          "application/gzip" = archiveManager;
          "application/bzip2" = archiveManager;
          "application/vnd.rar" = archiveManager;

          "application/vnd.comicbook-rar" = documentViewer;
          "application/vnd.comicbook+zip" = documentViewer;
          "application/x-cb7" = documentViewer;
          "application/x-cbr" = documentViewer;
          "application/x-cbt" = documentViewer;
          "application/x-cbz" = documentViewer;
          "application/x-ext-cb7" = documentViewer;
          "application/x-ext-cbr" = documentViewer;
          "application/x-ext-cbt" = documentViewer;
          "application/x-ext-cbz" = documentViewer;
          "application/x-ext-djv" = documentViewer;
          "application/x-ext-djvu" = documentViewer;
          "image/vnd.djvu" = documentViewer;
          "application/pdf" = documentViewer;
          "application/x-bzpdf" = documentViewer;
          "application/x-ext-pdf" = documentViewer;
          "application/x-gzpdf" = documentViewer;
          "application/x-xzpdf" = documentViewer;
          "application/postscript" = documentViewer;
          "application/x-bzpostscript" = documentViewer;
          "application/x-gzpostscript" = documentViewer;
          "application/x-ext-eps" = documentViewer;
          "application/x-ext-ps" = documentViewer;
          "image/x-bzeps" = documentViewer;
          "image/x-eps" = documentViewer;
          "image/x-gzeps" = documentViewer;
          "image/tiff" = documentViewer;
          "application/oxps" = documentViewer;
          "application/vnd.ms-xpsdocument" = documentViewer;
          "application/illustrator" = documentViewer;

          #audio/3gpp;audio/3gpp2;audio/aac;audio/ac3;audio/AMR;audio/AMR-WB;audio/basic;audio/dv;audio/eac3;audio/flac;audio/m4a;audio/midi;audio/mp1;audio/mp2;audio/mp3;audio/mp4;audio/mpeg;audio/mpegurl;audio/mpg;audio/ogg;audio/opus;audio/prs.sid;audio/scpls;audio/vnd.rn-realaudio;audio/wav;audio/webm;audio/x-aac;audio/x-aiff;audio/x-ape;audio/x-flac;audio/x-gsm;audio/x-it;audio/x-m4a;audio/x-matroska;audio/x-mod;audio/x-mp1;audio/x-mp2;audio/x-mp3;audio/x-mpg;audio/x-mpeg;audio/x-mpegurl;audio/x-ms-asf;audio/x-ms-asx;audio/x-ms-wax;audio/x-ms-wma;audio/x-musepack;audio/x-pn-aiff;audio/x-pn-au;audio/x-pn-realaudio;audio/x-pn-realaudio-plugin;audio/x-pn-wav;audio/x-pn-windows-acm;audio/x-realaudio;audio/x-real-audio;audio/x-s3m;audio/x-sbc;audio/x-scpls;audio/x-shorten;audio/x-speex;audio/x-stm;audio/x-tta;audio/x-wav;audio/x-wavpack;audio/x-vorbis;audio/x-vorbis+ogg;audio/x-xm;
          "audio/mpeg" = audioPlayer;
          "audio/wav" = audioPlayer;
          "audio/x-aac" = audioPlayer;
          "audio/x-aiff" = audioPlayer;
          "audio/x-ape" = audioPlayer;
          "audio/x-flac" = audioPlayer;
          "audio/x-m4a" = audioPlayer;
          "audio/x-m4b" = audioPlayer;
          "audio/x-mp1" = audioPlayer;
          "audio/x-mp2" = audioPlayer;
          "audio/x-mp3" = audioPlayer;
          "audio/x-mpg" = audioPlayer;
          "audio/x-mpeg" = audioPlayer;
          "audio/x-mpegurl" = audioPlayer;
          "audio/x-opus+ogg" = audioPlayer;
          "audio/x-pn-aiff" = audioPlayer;
          "audio/x-pn-au" = audioPlayer;
          "audio/x-pn-wav" = audioPlayer;
          "audio/x-speex" = audioPlayer;
          "audio/x-vorbis" = audioPlayer;
          "audio/x-vorbis+ogg" = audioPlayer;
          "audio/x-wavpack" = audioPlayer;

          "image/jpeg" = imageViewer;
          "image/png" = imageViewer;
          "image/gif" = imageViewer;
          "image/webp" = imageViewer;
          "image/x-tga" = imageViewer;
          "image/vnd-ms.dds" = imageViewer;
          "image/x-dds" = imageViewer;
          "image/bmp" = imageViewer;
          "image/vnd.microsoft.icon" = imageViewer;
          "image/vnd.radiance" = imageViewer;
          "image/x-exr" = imageViewer;
          "image/x-portable-bitmap" = imageViewer;
          "image/x-portable-graymap" = imageViewer;
          "image/x-portable-pixmap" = imageViewer;
          "image/x-portable-anymap" = imageViewer;
          "image/x-qoi;image/svg+xml" = imageViewer;
          "image/svg+xml-compressed" = imageViewer;
          "image/avif" = imageViewer;
          "image/heic" = imageViewer;
          "image/jxl" = imageViewer;

          "application/mxf" = videoPlayer;
          "application/ogg" = videoPlayer;
          "application/ram" = videoPlayer;
          "application/sdp" = videoPlayer;
          "application/smil" = videoPlayer;
          "application/smil+xml" = videoPlayer;
          "application/vnd.apple.mpegurl" = videoPlayer;
          "application/vnd.ms-asf" = videoPlayer;
          "application/vnd.ms-wpl" = videoPlayer;
          "application/vnd.rn-realmedia" = videoPlayer;
          "application/vnd.rn-realmedia-vbr" = videoPlayer;
          "application/x-extension-mp4" = videoPlayer;
          "application/x-flash-video" = videoPlayer;
          "application/x-matroska" = videoPlayer;
          "application/x-netshow-channel" = videoPlayer;
          "application/x-ogg" = videoPlayer;
          "application/x-quicktime-media-link" = videoPlayer;
          "application/x-quicktimeplayer" = videoPlayer;
          "application/x-shorten" = videoPlayer;
          "application/x-smil" = videoPlayer;
          "application/xspf+xml" = videoPlayer;
          "video/3gp" = videoPlayer;
          "video/3gpp" = videoPlayer;
          "video/3gpp2" = videoPlayer;
          "video/dv" = videoPlayer;
          "video/divx" = videoPlayer;
          "video/fli" = videoPlayer;
          "video/mp2t" = videoPlayer;
          "video/mp4" = videoPlayer;
          "video/mp4v-es" = videoPlayer;
          "video/mpeg" = videoPlayer;
          "video/mpeg-system" = videoPlayer;
          "video/msvideo" = videoPlayer;
          "video/ogg" = videoPlayer;
          "video/quicktime" = videoPlayer;
          "video/vivo" = videoPlayer;
          "video/vnd.divx" = videoPlayer;
          "video/vnd.rn-realvideo" = videoPlayer;
          "video/vnd.vivo" = videoPlayer;
          "video/webm" = videoPlayer;
          "video/x-anim" = videoPlayer;
          "video/x-avi" = videoPlayer;
          "video/x-flc" = videoPlayer;
          "video/x-fli" = videoPlayer;
          "video/x-flic" = videoPlayer;
          "video/x-flv" = videoPlayer;
          "video/x-m4v" = videoPlayer;
          "video/x-matroska" = videoPlayer;
          "video/x-mpeg" = videoPlayer;
          "video/x-mpeg2" = videoPlayer;
          "video/x-ms-asf" = videoPlayer;
          "video/x-ms-asf-plugin" = videoPlayer;
          "video/x-ms-asx" = videoPlayer;
          "video/x-msvideo" = videoPlayer;
          "video/x-ms-wm" = videoPlayer;
          "video/x-ms-wmv" = videoPlayer;
          "video/x-ms-wmx" = videoPlayer;
          "video/x-ms-wvx" = videoPlayer;
          "video/x-nsv" = videoPlayer;
          "video/x-ogm+ogg" = videoPlayer;
          "video/x-theora" = videoPlayer;
          "video/x-theora+ogg" = videoPlayer;
          "video/x-totem-stream" = videoPlayer;
          "x-content/video-dvd" = videoPlayer;
          "x-content/video-vcd" = videoPlayer;
          "x-content/video-svcd" = videoPlayer;
          "x-scheme-handler/pnm" = videoPlayer;
          "x-scheme-handler/net" = videoPlayer;
          "x-scheme-handler/rtmp" = videoPlayer;
          "x-scheme-handler/mmsh" = videoPlayer;
          "x-scheme-handler/uvox" = videoPlayer;
          "x-scheme-handler/icy" = videoPlayer;
          "x-scheme-handler/icyx" = videoPlayer;
        };
        defaultApplications = {
          "audio/*" = audioPlayer;
          "application/pdf" = documentViewer;
          "image/*" = imageViewer;
          "video/*" = videoPlayer;
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
  };
}
