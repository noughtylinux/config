{
  config,
  lib,
  pkgs,
  ...
}:
{
  catppuccin = {
    foot.enable = config.programs.foot.enable;
  };

  programs = {
    foot = {
      enable = true;
      # https://codeberg.org/dnkl/foot/src/branch/master/foot.ini
      server.enable = false;
      settings = {
        main = {
          font = "FiraCode Nerd Font Mono:size=16";
          term = "xterm-256color";
        };
        cursor = {
          style = "block";
          blink = "yes";
        };
        scrollback = {
          lines = 10240;
        };
      };
    };
    fuzzel = lib.mkIf config.programs.fuzzel.enable {
      settings.main.terminal = "${pkgs.foot}/bin/foot";
    };
  };

  wayland.windowManager.hyprland = lib.mkIf config.wayland.windowManager.hyprland.enable {
    settings = {
      bind = [
        "$mod, T, exec, ${pkgs.foot}/bin/foot"
      ];
    };
  };
}
