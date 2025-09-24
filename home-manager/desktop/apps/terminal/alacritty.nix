{
  config,
  lib,
  noughtyConfig,
  pkgs,
  ...
}:
let
  terminalEmulator = noughtyConfig.desktop.terminal-emulator or "";
in
lib.mkIf (terminalEmulator == "alacritty") {
  catppuccin = {
    alacritty.enable = config.programs.alacritty.enable;
  };

  programs = {
    alacritty = {
      enable = true;
      settings = {
        cursor = {
          style = {
            shape = "Block";
            blinking = "Always";
          };
        };
        env = {
          TERM = "xterm-256color";
        };
        font = {
          normal = {
            family = "FiraCode Nerd Font Mono";
          };
          bold = {
            family = "FiraCode Nerd Font Mono";
          };
          italic = {
            family = "FiraCode Nerd Font Mono";
          };
          bold_italic = {
            family = "FiraCode Nerd Font Mono";
          };
          size = 16;
          builtin_box_drawing = true;
        };
        mouse = {
          bindings = [
            {
              mouse = "Middle";
              action = "Paste";
            }
          ];
        };
        selection = {
          save_to_clipboard = true;
        };
        scrolling = {
          history = 50000;
          multiplier = 3;
        };
        terminal = {
          shell = {
            program = "${pkgs.fish}/bin/fish";
            args = [ "--interactive" ];
          };
        };
        window = {
          decorations = if config.wayland.windowManager.hyprland.enable then "None" else "Full";
          dimensions = {
            columns = 132;
            lines = 50;
          };
          padding = {
            x = 5;
            y = 5;
          };
          opacity = 1.0;
          blur = false;
        };
      };
    };
    fuzzel = lib.mkIf config.programs.fuzzel.enable {
      settings.main.terminal = "${pkgs.alacritty}/bin/alacritty";
    };
  };

  wayland.windowManager.hyprland = lib.mkIf config.wayland.windowManager.hyprland.enable {
    settings = {
      bind = [
        "$mod, T, exec, ${pkgs.alacritty}/bin/alacritty"
      ];
    };
  };

  # TODO: Enable terminal-exec when available (Home Manager 25.11+ or unstable)
  xdg = {
    #terminal-exec = {
    #  settings = {
    #    default = [ "Alacritty.desktop" ];
    #  };
    #};
  };
}
