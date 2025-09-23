{
  config,
  ...
}:
{
  catppuccin.micro.enable = config.programs.micro.enable;

  programs = {
    micro = {
      enable = true;
      settings = {
        autosu = true;
        diffgutter = true;
        paste = true;
        rmtrailingws = true;
        savecursor = true;
        saveundo = true;
        scrollbar = true;
        scrollbarchar = "┇";
        scrollmargin = 4;
        scrollspeed = 1;
      };
    };
  };
}
