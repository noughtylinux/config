{
  config,
  lib,
  noughtyConfig,
  pkgs,
  ...
}:
let
  selectedShell = noughtyConfig.terminal.shell or "bash";
  shellArgs = if selectedShell == "fish" || selectedShell == "zsh" then "--interactive" else "";
  terminalEmulator = noughtyConfig.desktop.terminal-emulator or "";
in
lib.mkIf (terminalEmulator == "foot") {
  catppuccin = {
    foot.enable = config.programs.foot.enable;
  };

  # User specific dconf terminal-related settings
  dconf.settings = with lib.hm.gvariant; {
    "com/github/stunkymonkey/nautilus-open-any-terminal" = {
      terminal = "${pkgs.foot}/bin/foot";
    };
  };

  programs = {
    foot = {
      enable = true;
      # https://codeberg.org/dnkl/foot/src/branch/master/foot.ini
      server.enable = false;
      settings = {
        main = {
          font = "FiraCode Nerd Font Mono:size=16";
          shell = lib.mkIf (
            selectedShell != null && selectedShell != ""
          ) "${pkgs.${selectedShell}}/bin/${selectedShell} ${shellArgs}";
          term = "foot";
        };
        cursor = {
          style = "block";
          blink = "yes";
        };
        scrollback = {
          lines = 16384;
        };
      };
    };
    rofi = lib.mkIf config.programs.rofi.enable {
      terminal = "${pkgs.foot}/bin/foot";
    };
    fuzzel = lib.mkIf config.programs.fuzzel.enable {
      settings.main.terminal = "${pkgs.foot}/bin/foot";
    };
  };

  wayland.windowManager = {
    hyprland = lib.mkIf config.wayland.windowManager.hyprland.enable {
      settings = {
        bind = [
          "$mod, T, exec, ${pkgs.foot}/bin/foot"
        ];
      };
    };
    wayfire = lib.mkIf config.wayland.windowManager.wayfire.enable {
      settings = {
        command = {
          # Super+T launches a terminal
          binding_terminal = "<super> KEY_T";
          command_terminal = "$${pkgs.foot}/bin/foot";
        };
      };
    };
  };

  # TODO: Enable terminal-exec when available (Home Manager 25.11+ or unstable)
  xdg = {
    #terminal-exec = {
    #  settings = {
    #    default = [ "foot.desktop" ];
    #  };
    #};
  };
}
