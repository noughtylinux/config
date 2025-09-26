{
  config,
  ...
}:
{
  catppuccin.atuin.enable = config.programs.gh.extensions.atuin;

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
