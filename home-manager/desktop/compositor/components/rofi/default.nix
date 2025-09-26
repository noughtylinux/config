{
  config,
  lib,
  pkgs,
  ...
}:
{
  catppuccin.rofi.enable = true;
  home = {
    file."${config.xdg.configHome}/rofi/launchers/rofi-appgrid/style.rasi".source = ./rofi-appgrid.rasi;
  };

  programs = {
    rofi = {
      enable = true;
      package = pkgs.unstable.rofi;
    };
  };

  wayland.windowManager.hyprland = lib.mkIf config.wayland.windowManager.hyprland.enable {
    settings = {
      bindr = [
        "$mod, $mod_L, exec, ${pkgs.procps}/bin/pkill rofi || rofi -theme ${config.xdg.configHome}/rofi/launchers/rofi-appgrid/style.rasi -show drun"
      ];
    };
  };
}
