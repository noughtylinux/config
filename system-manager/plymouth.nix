# Catppuccin Plymouth Boot Splash Configuration
# Uses catppuccin-plymouth package for PNG assets with dynamically generated .plymouth file
{
  noughtyConfig,
  pkgs,
  lib,
  ...
}:
let
  palette = noughtyConfig.catppuccin.palette;

  # Boot configuration from config.toml
  plymouthEnabled = noughtyConfig.boot.grub_theme or true;

  # Install catppuccin-plymouth with the user's selected flavor (for PNG assets)
  catppuccinPlymouth = pkgs.catppuccin-plymouth.override { variant = palette.flavor; };

  # Convert palette hex color (#RRGGBB) to Plymouth format (0xRRGGBB)
  toPlymouthColor =
    colorName:
    let
      hex = palette.getColor colorName;
      # Strip the # prefix and add 0x prefix
      hexValue = builtins.substring 1 (-1) hex;
    in
    "0x${hexValue}";

  # Generate dynamic .plymouth theme file using Catppuccin palette colors
  plymouthThemeConfig = ''
    [Plymouth Theme]
    Name=catppuccin-${palette.flavor}
    Description=catppuccin-${palette.flavor}
    ModuleName=two-step

    [two-step]
    Font=Noto Sans 12
    TitleFont=Noto Sans Light 30
    ImageDir=/usr/share/plymouth/themes/catppuccin-${palette.flavor}
    DialogHorizontalAlignment=.5
    DialogVerticalAlignment=.5
    TitleHorizontalAlignment=.5
    TitleVerticalAlignment=.5
    HorizontalAlignment=.5
    VerticalAlignment=.5
    WatermarkHorizontalAlignment=.5
    WatermarkVerticalAlignment=.5
    Transition=none
    TransitionDuration=0.0
    BackgroundStartColor=${toPlymouthColor "base"}
    BackgroundEndColor=${toPlymouthColor "base"}
    ProgressBarBackgroundColor=${toPlymouthColor "surface0"}
    ProgressBarForegroundColor=${toPlymouthColor "base"}
    MessageBelowAnimation=true

    [boot-up]
    UseEndAnimation=false

    [shutdown]
    UseEndAnimation=false

    [reboot]
    UseEndAnimation=false
  '';
in
{
  config = lib.mkIf plymouthEnabled {
    # Install Plymouth theme package (for PNG assets)
    environment.systemPackages = [ catppuccinPlymouth ];

    # Deploy Plymouth daemon configuration
    environment.etc."plymouth/plymouthd.conf".text = ''
      [Daemon]
      Theme=catppuccin-${palette.flavor}
      ShowDelay=0
    '';

    # Deploy PNG assets from package to staging area
    systemd.tmpfiles.settings."10-plymouth-assets" = {
      "/etc/noughty/plymouth/catppuccin-${palette.flavor}"."L+" = {
        argument = "${catppuccinPlymouth}/share/plymouth/themes/catppuccin-${palette.flavor}";
      };
    };

    # Deploy dynamically generated .plymouth theme file
    environment.etc."noughty/plymouth/catppuccin-${palette.flavor}.plymouth".text = plymouthThemeConfig;
  };
}
