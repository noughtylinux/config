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
lib.mkIf (terminalEmulator == "kitty") {
  catppuccin = {
    kitty.enable = config.programs.kitty.enable;
  };

  programs = {
    kitty = {
      enable = true;
      font = {
        name = "FiraCode Nerd Font Mono";
        size = 16;
      };
      settings = {
        cursor_blink_interval = 0.75;
        cursor_shape = "block";
        cursor_shape_unfocused = "hollow";
        cursor_stop_blinking_after = 0;
        hide_window_decorations = if config.wayland.windowManager.hyprland.enable then true else false;
        scrollback_indicator_opacity = 0.50;
        scrollback_lines = 16384;
        shell = lib.mkIf (
          selectedShell != null && selectedShell != ""
        ) "${pkgs.${selectedShell}}/bin/${selectedShell} ${shellArgs}";
        draw_minimal_borders = "yes";
        window_border_width = "0pt";
        window_margin_width = 0;
        single_window_margin_width = 0;
        sync_to_monitor = "yes";
        term = "xterm-256color";
        # Mouse
        copy_on_select = true;
        mouse_hide_wait = 0;
        strip_trailing_spaces = "smart";
        wheel_scroll_multiplier = 5;
        # Bell
        enable_audio_bell = "no";
        visual_bell = 0.25;
      };
      shellIntegration = {
        enableBashIntegration = false;
        enableFishIntegration = false;
        enableZshIntegration = false;
      };
      extraConfig = ''
        cursor_trail 500
        cursor_trail_decay 0.175 0.425
        cursor_trail_start_threshold 2
      '';
    };
    rofi = lib.mkIf config.programs.rofi.enable {
      terminal = "${pkgs.kitty}/bin/kitty --single-instance";
    };
    fuzzel = lib.mkIf config.programs.fuzzel.enable {
      settings.main.terminal = "${pkgs.kitty}/bin/kitty --single-instance";
    };
  };

  wayland.windowManager.hyprland = lib.mkIf config.wayland.windowManager.hyprland.enable {
    settings = {
      bind = [
        "$mod, T, exec, ${pkgs.kitty}/bin/kitty --single-instance"
      ];
    };
  };

  # TODO: Enable terminal-exec when available (Home Manager 25.11+ or unstable)
  xdg = {
    #terminal-exec = {
    #  settings = {
    #    default = [ "kitty.desktop" ];
    #  };
    #};
  };
}
