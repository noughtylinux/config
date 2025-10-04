{
  config,
  lib,
  pkgs,
  ...
}:
{
  home = {
    packages = lib.optionals config.programs.firefox.enable [
      pkgs.browsh
    ];
  };
}
