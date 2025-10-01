# Catppuccin Plymouth Boot Splash Configuration
# Dynamically generates .plymouth theme file using Catppuccin palette
# Static assets (PNG files) remain in assets/plymouth/ and are deployed via ubuntu-post
{
  noughtyConfig,
  lib,
  ...
}:
let
  palette = noughtyConfig.catppuccin.palette;

  # Boot configuration from config.toml
  plymouthEnabled = noughtyConfig.boot.grub_theme or true;

  # Convert palette hex color (#RRGGBB) to Plymouth format (0xRRGGBB)
  toPlymouthColor =
    colorName:
    let
      hex = palette.getColor colorName;
      # Strip the # prefix and add 0x prefix
      hexValue = builtins.substring 1 (-1) hex;
    in
    "0x${hexValue}";

  # Generate dynamic .plymouth theme file
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
    # Deploy Plymouth daemon configuration
    environment.etc."plymouth/plymouthd.conf".text = ''
      [Daemon]
      Theme=catppuccin-${palette.flavor}
      ShowDelay=0
    '';

    # Deploy dynamically generated .plymouth theme file
    environment.etc."noughty/plymouth/catppuccin-${palette.flavor}.plymouth".text = plymouthThemeConfig;
  };
}
