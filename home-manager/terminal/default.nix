{
  noughtyConfig,
  ...
}:
let
  selectedShell = noughtyConfig.terminal.shell or "fish";
in
{
  # Terminal/shell configuration derived from TOML config
  programs = {
    fish.enable = selectedShell == "fish";
    bash.enable = selectedShell == "bash";
    zsh.enable = selectedShell == "zsh";
  };
}
