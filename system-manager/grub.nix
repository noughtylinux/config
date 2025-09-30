# Catppuccin GRUB Theme
# Dynamically themed GRUB boot menu using Catppuccin palette
# Also manages kernel VT color parameters for boot-time theming
{
  noughtyConfig,
  pkgs,
  lib,
  ...
}:
let
  palette = noughtyConfig.catppuccin.palette;

  # Boot configuration from config.toml
  grubThemeEnabled = noughtyConfig.boot.grub_theme or true;
  grubTimeout = noughtyConfig.boot.grub_timeout or 5;

  # Use centralized VT color mapping from palette
  vtColorMap = palette.vtColorMap;

  # Helper to extract RGB values for VT kernel parameters
  getRGBForVT = colorName: palette.getRGB colorName;

  # Generate VT kernel parameters with dynamic Catppuccin colors
  generateVTParams =
    let
      # Get RGB values for all 16 colors
      rgbValues = map getRGBForVT vtColorMap;

      # Extract red, green, blue components separately
      reds = map (rgb: toString rgb.r) rgbValues;
      greens = map (rgb: toString rgb.g) rgbValues;
      blues = map (rgb: toString rgb.b) rgbValues;

      # Join with commas for kernel parameters
      redParams = builtins.concatStringsSep "," reds;
      greenParams = builtins.concatStringsSep "," greens;
      blueParams = builtins.concatStringsSep "," blues;
    in
    "vt.default_red=${redParams} vt.default_grn=${greenParams} vt.default_blu=${blueParams}";

  # Dynamic Catppuccin kernel parameters for boot-time VT theming
  catppuccinKernelParams = generateVTParams;

  # Console font configuration based on grub_theme setting
  consoleFontFace = if grubThemeEnabled then "Terminus" else "Fixed";
  consoleFontSize = if grubThemeEnabled then "16x32" else "8x16";
  kernelConsoleFontParam = if grubThemeEnabled then "fbcon=font:TER16x32" else "";

  # Console setup configuration template
  consoleSetupConfig = ''
    # CONFIGURATION FILE FOR SETUPCON

    # Consult the console-setup(5) manual page.

    ACTIVE_CONSOLES="/dev/tty[1-6]"

    CHARMAP="UTF-8"

    CODESET="guess"
    FONTFACE="${consoleFontFace}"
    FONTSIZE="${consoleFontSize}"

    VIDEOMODE=

    # The following is an example how to use a braille font
    # FONT='lat9w-08.psf.gz brl-8x8.psf'
  '';

  # Get upstream catppuccin-grub package for static assets
  upstreamTheme = pkgs.catppuccin-grub.override {
    flavor = palette.flavor;
  };

  # Generate dynamic theme.txt with user's accent color
  # Based on upstream catppuccin-grub theme structure
  themeConfig = ''
    # Catppuccin GRUB Theme - ${palette.flavor}
    # Designed for any resolution

    # Global Property
    title-text: ""
    desktop-image: "background.png"
    desktop-image-scale-method: "stretch"
    desktop-color: "${palette.getColor "base"}"
    terminal-font: "Unifont Regular 16"
    terminal-left: "0"
    terminal-top: "0"
    terminal-width: "100%"
    terminal-height: "100%"
    terminal-border: "0"

    # Logo image
    + image {
      left = 50%-50
      top = 50%-50
      file = "logo.png"
    }

    # Show the boot menu
    + boot_menu {
      left = 50%-240
      top = 60%
      width = 480
      height = 30%
      item_font = "Unifont Regular 16"
      item_color = "${palette.getColor "text"}"
      selected_item_color = "${palette.getColor "text"}"
      icon_width = 32
      icon_height = 32
      item_icon_space = 20
      item_height = 36
      item_padding = 5
      item_spacing = 10
      selected_item_pixmap_style = "select_*.png"
    }

    # Show a countdown message using the label component
    + label {
      top = 82%
      left = 35%
      width = 30%
      align = "center"
      id = "__timeout__"
      text = "Booting in %d seconds"
      color = "${palette.getColor "text"}"
    }
  '';

  # Generate solid color background using ImageMagick for GRUB-compatible PNG
  backgroundPng =
    pkgs.runCommand "grub-background.png"
      {
        buildInputs = [ pkgs.imagemagick ];
      }
      ''
        convert -size 640x480 "xc:${palette.getColor "base"}" -depth 8 PNG8:$out
      '';

  # Generate selection graphics using ImageMagick for GRUB-compatible PNG
  # These are the highlight bars shown when selecting menu items
  selectCPng =
    pkgs.runCommand "grub-select-c.png"
      {
        buildInputs = [ pkgs.imagemagick ];
      }
      ''
        convert -size 8x36 "xc:${palette.getColor "surface1"}" -depth 8 PNG8:$out
      '';

  selectEPng =
    pkgs.runCommand "grub-select-e.png"
      {
        buildInputs = [ pkgs.imagemagick ];
      }
      ''
        convert -size 5x36 "xc:${palette.getColor "surface1"}" -depth 8 PNG8:$out
      '';

  selectWPng =
    pkgs.runCommand "grub-select-w.png"
      {
        buildInputs = [ pkgs.imagemagick ];
      }
      ''
        convert -size 5x36 "xc:${palette.getColor "surface1"}" -depth 8 PNG8:$out
      '';
in
{
  # Deploy dynamic theme configuration and generated assets (if enabled)
  environment.etc = lib.mkMerge [
    # Always configure kernel VT colors and timeout
    {
      "default/grub.d/99-catppuccin.cfg".text = ''
        # Catppuccin GRUB configuration
        ${lib.optionalString grubThemeEnabled ''
          GRUB_THEME="/boot/grub/themes/catppuccin/theme.txt"
          GRUB_GFXMODE="auto"
        ''}
        GRUB_TIMEOUT=${toString grubTimeout}
        GRUB_TIMEOUT_STYLE="menu"

        # Set GRUB terminal background to Catppuccin base color
        GRUB_BACKGROUND="${palette.getColor "base"}"
        GRUB_COLOR_NORMAL="${palette.getColor "text"}/${palette.getColor "base"}"
        GRUB_COLOR_HIGHLIGHT="${palette.getColor "base"}/${palette.selectedAccent}"

        # Dynamic Catppuccin kernel VT colors and console font
        # quiet loglevel=3 suppress EFI stub and early boot messages
        GRUB_CMDLINE_LINUX_DEFAULT="$GRUB_CMDLINE_LINUX_DEFAULT quiet loglevel=3 ${catppuccinKernelParams} ${kernelConsoleFontParam}"
      '';

      # Deploy console-setup configuration for initramfs
      "noughty/console-setup".text = consoleSetupConfig;
    }

    # Conditionally deploy theme assets
    (lib.mkIf grubThemeEnabled {
      "noughty/grub/themes/catppuccin/theme.txt".text = themeConfig;
      "noughty/grub/themes/catppuccin/background.png".source = backgroundPng;
      "noughty/grub/themes/catppuccin/select_c.png".source = selectCPng;
      "noughty/grub/themes/catppuccin/select_e.png".source = selectEPng;
      "noughty/grub/themes/catppuccin/select_w.png".source = selectWPng;
    })
  ];

  # Symlink static assets from upstream catppuccin-grub package (if theme enabled)
  systemd.tmpfiles.settings = lib.mkIf grubThemeEnabled {
    "10-grub-theme" = {
      "/etc/noughty/grub/themes/catppuccin/icons".L.argument = "${upstreamTheme}/icons";
      "/etc/noughty/grub/themes/catppuccin/logo.png".L.argument = "${upstreamTheme}/logo.png";
      "/etc/noughty/grub/themes/catppuccin/font.pf2".L.argument = "${upstreamTheme}/font.pf2";
    };
  };
}
