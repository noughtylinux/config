_: {
  # hyprpaper is a wallpaper manager and part of the hyprland suite
  services = {
    hyprpaper = {
      enable = true;
      settings = {
        splash = false;
        preload = [ "/etc/noughty/backgrounds/Catppuccin-1920x1200.png" ];
        wallpaper = [ ", /etc/noughty/backgrounds/Catppuccin-1920x1200.png" ];
      };
    };
  };
}
