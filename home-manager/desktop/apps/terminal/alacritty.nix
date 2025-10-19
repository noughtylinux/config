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
  windowDecorations =
    if config.wayland.windowManager.wayfire.enable then
      "Full"
    else if config.wayland.windowManager.hyprland.enable then
      "None"
    else
      "Full";
in
lib.mkIf (terminalEmulator == "alacritty") {
  catppuccin = {
    alacritty.enable = config.programs.alacritty.enable;
  };

  # User specific dconf terminal-related settings
  dconf.settings = with lib.hm.gvariant; {
    "com/github/stunkymonkey/nautilus-open-any-terminal" = {
      terminal = "${pkgs.alacritty}/bin/alacritty";
    };
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
          TERM = "alacritty";
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
          history = 16384;
          multiplier = 3;
        };
        terminal = {
          shell = lib.mkIf (selectedShell != null && selectedShell != "") {
            program = "${pkgs.${selectedShell}}/bin/${selectedShell}";
            args = [ "${shellArgs}" ];
          };
        };
        window = {
          decorations = windowDecorations;
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
    rofi = lib.mkIf config.programs.rofi.enable {
      terminal = "${pkgs.alacritty}/bin/alacritty";
    };
    fuzzel = lib.mkIf config.programs.fuzzel.enable {
      settings.main.terminal = "${pkgs.alacritty}/bin/alacritty";
    };
  };

  wayland.windowManager = {
    hyprland = lib.mkIf config.wayland.windowManager.hyprland.enable {
      settings = {
        bind = [
          "$mod, T, exec, ${pkgs.alacritty}/bin/alacritty"
        ];
      };
    };
    wayfire = lib.mkIf config.wayland.windowManager.wayfire.enable {
      settings = {
        command = {
          # Super+T launches a terminal
          binding_terminal = "<super> KEY_T";
          command_terminal = "${pkgs.alacritty}/bin/alacritty";
        };
      };
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
