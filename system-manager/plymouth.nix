# Catppuccin Plymouth Boot Splash Configuration
# Theme assets are bundled in assets/plymouth/ and deployed via ubuntu-post
{
  noughtyConfig,
  lib,
  ...
}:
let
  palette = noughtyConfig.catppuccin.palette;

  # Boot configuration from config.toml
  plymouthEnabled = noughtyConfig.boot.grub_theme or true;
in
{
  config = lib.mkIf plymouthEnabled {
    # Deploy Plymouth configuration to set Catppuccin as default theme
    environment.etc."plymouth/plymouthd.conf".text = ''
      [Daemon]
      Theme=catppuccin-${palette.flavor}
      ShowDelay=0
    '';
  };
}
