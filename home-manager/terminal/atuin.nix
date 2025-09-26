{
  config,
  ...
}:
{
  # Creates an infinite recursion if you do `catppuccin.atuin.enable = config.programs.atuin;`
  catppuccin.atuin.enable = true;

  programs = {
    atuin = {
      enable = true;
      enableBashIntegration = config.programs.bash.enable;
      enableFishIntegration = config.programs.fish.enable;
      enableZshIntegration = config.programs.zsh.enable;
      flags = [ "--disable-up-arrow" ];
      settings = {
        update_check = false;
      };
    };
  };
}
