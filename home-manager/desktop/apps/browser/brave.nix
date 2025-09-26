{
  lib,
  noughtyConfig,
  pkgs,
  ...
}:
let
  braveEnabled = noughtyConfig.browser.brave or false;
in
lib.mkIf braveEnabled {
  catppuccin = {
    brave.enable = true;
  };

  home = {
    packages = with pkgs; [
      brave
    ];
  };
}
