{
  config,
  noughtyConfig,
  lib,
  pkgs,
  ...
}:
{
  home = {
    packages = with pkgs; [
      wayland-logout
    ];
  };
  # Wayfire is a Wayland compositor and stacking window manager
  # Additional applications are required to create a full desktop shell
  imports = [
    #  ./avizo # on-screen display for audio and backlight
    #  ./fuzzel # app launcher, emoji picker and clipboard manager
    #  ./hyprlock # screen locker
    ../components/hyprpaper # wallpaper setter
    #  ./hyprshot # screenshot grabber and annotator
    ../components/rofi # application launcher
    #  ./swaync # notification center
    #  ./waybar # status bar
    #  ./wlogout # session menu
  ];
  #TODO: IPC tooling for wayfire
  # https://github.com/killown/wayfire-rs
  # https://github.com/AR-CADE/wayfire-ipc
  # https://github.com/bluebyt/Wayfire-dots/tree/main/.config/ipc-scripts
  # TODO: Wayfire
  # Integrate this patch for colour picking support
  # https://github.com/WayfireWM/wayfire/pull/2852
  wayland.windowManager.wayfire = {
    enable = true;
    plugins = with pkgs.wayfirePlugins; [
      pixdecor
      wayfire-plugins-extra
      wcm
    ];
    settings = {
      # Window animations
      animate = {
        open_animation = "zap";
        close_animation = "spin";
        duration = 300;
      };
      autostart = {
        # Disable wf-shell autostart, we're using waybar et al instead
        autostart_wf_shell = false;
        button_layout = "dconf write /org/gnome/desktop/wm/preferences/button-layout \"':minimize,maximize,close'\"";
      };
      command = {
        # Super+E launches the file manager
        binding_files = "<super> KEY_E";
        command_files = "${lib.getExe pkgs.nautilus} --new-window";
        # Media controls
        binding_play_pause = "XF86AudioPlay";
        command_play_pause = "${lib.getExe pkgs.playerctl} play-pause";
        binding_previous = "XF86AudioPrev";
        command_previous = "${lib.getExe pkgs.playerctl} previous";
        binding_next = "XF86AudioNext";
        command_next = "${lib.getExe pkgs.playerctl} next";
      };
      core = {
        #plugins = "animate autostart blur command foreign-toplevel grid gtk-shell idle ipc ipc-rules move pixdecor place resize session-lock switcher vswitch wm-actions wobbly xdg-activation";
        plugins = "animate autostart blur command decoration foreign-toplevel grid gtk-shell idle ipc ipc-rules move place resize session-lock switcher vswitch wm-actions wobbly xdg-activation";
        vwidth = 8;
        vheight = 1;
        preferred_decoration_mode = "client";
      };
      # Window decorations (title bars, borders)
      decoration = {
        # Active window: use crust colour for visibility against surface
        active_color =
          let
            hex = noughtyConfig.catppuccin.palette.getColor "mantle";
            r = builtins.substring 1 2 hex;
            g = builtins.substring 3 2 hex;
            b = builtins.substring 5 2 hex;
            toFloat = hexStr: toString (builtins.div (builtins.fromTOML "x=0x${hexStr}").x 255.0);
          in
          "${toFloat r} ${toFloat g} ${toFloat b} 1.0";

        # Inactive window: use base for subtle, recessed appearance
        inactive_color =
          let
            hex = noughtyConfig.catppuccin.palette.getColor "base";
            r = builtins.substring 1 2 hex;
            g = builtins.substring 3 2 hex;
            b = builtins.substring 5 2 hex;
            toFloat = hexStr: toString (builtins.div (builtins.fromTOML "x=0x${hexStr}").x 255.0);
          in
          "${toFloat r} ${toFloat g} ${toFloat b} 1.0";
        button_order = "minimize maximize close";
        border_size = 2;
        font = "Work Sans Medium";
        title_height = 32;
      };
      pixdecor = {
        border_size = 2;
        # Color when focused
        fg_color =
          let
            hex = noughtyConfig.catppuccin.palette.getColor "mantle";
            r = builtins.substring 1 2 hex;
            g = builtins.substring 3 2 hex;
            b = builtins.substring 5 2 hex;
            toFloat = hexStr: toString (builtins.div (builtins.fromTOML "x=0x${hexStr}").x 255.0);
          in
          "${toFloat r} ${toFloat g} ${toFloat b} 1.0";
        # Color when not focused
        bg_color =
          let
            hex = noughtyConfig.catppuccin.palette.getColor "base";
            r = builtins.substring 1 2 hex;
            g = builtins.substring 3 2 hex;
            b = builtins.substring 5 2 hex;
            toFloat = hexStr: toString (builtins.div (builtins.fromTOML "x=0x${hexStr}").x 255.0);
          in
          "${toFloat r} ${toFloat g} ${toFloat b} 1.0";
        fg_text_color =
          let
            hex = noughtyConfig.catppuccin.palette.getColor "text";
            r = builtins.substring 1 2 hex;
            g = builtins.substring 3 2 hex;
            b = builtins.substring 5 2 hex;
            toFloat = hexStr: toString (builtins.div (builtins.fromTOML "x=0x${hexStr}").x 255.0);
          in
          "${toFloat r} ${toFloat g} ${toFloat b} 1.0";
        # Color when not focused
        bg_text_color =
          let
            hex = noughtyConfig.catppuccin.palette.getColor "subtext0";
            r = builtins.substring 1 2 hex;
            g = builtins.substring 3 2 hex;
            b = builtins.substring 5 2 hex;
            toFloat = hexStr: toString (builtins.div (builtins.fromTOML "x=0x${hexStr}").x 255.0);
          in
          "${toFloat r} ${toFloat g} ${toFloat b} 1.0";
        overlay_engine = "rounded_corners";
        #rounded_corner_radius = 4;
        always_decorate = "(app_id is \"kitty\")";
        #shadow_radius = 8;
        csd_titlebar_height = 32;
        shadow_color =
          let
            hex = noughtyConfig.catppuccin.palette.getColor "crust";
            r = builtins.substring 1 2 hex;
            g = builtins.substring 3 2 hex;
            b = builtins.substring 5 2 hex;
            toFloat = hexStr: toString (builtins.div (builtins.fromTOML "x=0x${hexStr}").x 255.0);
          in
          "${toFloat r} ${toFloat g} ${toFloat b} 0.6";
        effect_type = "smoke";
        effect_color =
          let
            hex = noughtyConfig.catppuccin.palette.getColor noughtyConfig.catppuccin.accent;
            r = builtins.substring 1 2 hex;
            g = builtins.substring 3 2 hex;
            b = builtins.substring 5 2 hex;
            toFloat = hexStr: toString (builtins.div (builtins.fromTOML "x=0x${hexStr}").x 255.0);
          in
          "${toFloat r} ${toFloat g} ${toFloat b} 0.6";
        button_layout = ":minimize,maximize,close";
        title_text_align = 1; # Centered
        title_font = "Work Sans 10";
      };
      # Grid snapping - position windows in screen regions
      grid = {
        duration = 300;
        type = "crossfade";
        # Slot keybindings for window positioning
        slot_l = "<super> <alt> KEY_LEFT"; # Snap to left half
        slot_r = "<super> <alt> KEY_RIGHT"; # Snap to right half
        slot_t = "<super> <alt> KEY_UP"; # Snap to top half
        slot_b = "<super> <alt> KEY_DOWN"; # Snap to bottom half
        #slot_c = "<super> KEY_C"; # Center/maximize
        #slot_tl = "<super> <shift> KEY_UP"; # Top-left quarter
        #slot_tr = "<super> <ctrl> KEY_UP"; # Top-right quarter
        #slot_bl = "<super> <shift> KEY_DOWN"; # Bottom-left quarter
        #slot_br = "<super> <ctrl> KEY_DOWN"; # Bottom-right quarter
        restore = "<super> KEY_DOWN"; # Restore original size
      };
      input = {
        xkb_layout = "gb";
        repeat_delay = 300;
        repeat_rate = 30;
        cursor_size = 32;
      };
      # Window movement - Super+Left Mouse to drag windows
      move = {
        activate = "<super> BTN_LEFT";
        enable_snap = true;
        enable_snap_off = true;
        snap_threshold = 10;
        snap_off_threshold = 10;
      };
      # Window placement for new windows
      place = {
        mode = "center";
      };
      # Window resizing - Super+Right Mouse to resize windows
      resize = {
        activate = "<super> BTN_RIGHT";
      };
      switcher = {
        next_view = "<alt> KEY_TAB";
        prev_view = "<alt> <shift> KEY_TAB";
      };
      # Virtual desktop switching with Ctrl+Alt+[1-8]
      vswitch = {
        binding_1 = "<ctrl> <alt> KEY_1";
        binding_2 = "<ctrl> <alt> KEY_2";
        binding_3 = "<ctrl> <alt> KEY_3";
        binding_4 = "<ctrl> <alt> KEY_4";
        binding_5 = "<ctrl> <alt> KEY_5";
        binding_6 = "<ctrl> <alt> KEY_6";
        binding_7 = "<ctrl> <alt> KEY_7";
        binding_8 = "<ctrl> <alt> KEY_8";
        binding_left = "<ctrl> <alt> KEY_LEFT";
        binding_right = "<ctrl> <alt> KEY_RIGHT";
        with_win_1 = "<super> <alt> KEY_1";
        with_win_2 = "<super> <alt> KEY_2";
        with_win_3 = "<super> <alt> KEY_3";
        with_win_4 = "<super> <alt> KEY_4";
        with_win_5 = "<super> <alt> KEY_5";
        with_win_6 = "<super> <alt> KEY_6";
        with_win_7 = "<super> <alt> KEY_7";
        with_win_8 = "<super> <alt> KEY_8";
      };
      # Window management actions
      wm-actions = {
        #toggle_fullscreen = "<super> KEY_F";
        toggle_maximize = "<super> KEY_UP";
        #minimize = "<super> KEY_N";
        #toggle_always_on_top = "<super> KEY_A";
        #toggle_sticky = "<super> KEY_S";
      };
    };
    xwayland.enable = true;
  };
  xdg = {
    portal = {
      config = {
        common = {
          "org.freedesktop.impl.portal.ScreenCast" = [ "wlr" ];
          "org.freedesktop.impl.portal.Screenshot" = [ "wlr" ];
        };
      };
      configPackages = [ config.wayland.windowManager.wayfire.package ];
    };
  };
}
