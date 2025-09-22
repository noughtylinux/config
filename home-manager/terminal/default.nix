{
  config,
  inputs,
  noughtyConfig,
  ...
}:
let
  selectedShell = noughtyConfig.terminal.shell or "fish";
  catppuccinAccent = noughtyConfig.catppuccin.accent or "blue";
  catppuccinFlavor = noughtyConfig.catppuccin.flavor or "mocha";
in
{
  imports = [
    inputs.catppuccin.homeModules.catppuccin
    ./bat.nix
  ];

  # Catppuccin is not enabled for everything by default
  # I have custom Catppuccin themes for some programs
  catppuccin = {
    accent = catppuccinAccent;
    flavor = catppuccinFlavor;
    fish.enable = config.programs.fish.enable;
    zsh-syntax-highlighting.enable = config.programs.zsh.enable;
  };

  # Terminal/shell configuration derived from TOML config
  # Always enable bash for scripts and compatibility
  programs = {
    fish.enable = selectedShell == "fish";
    bash.enable = true;
    zsh.enable = selectedShell == "zsh";
  };
}
