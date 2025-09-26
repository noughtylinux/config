{
  lib,
  noughtyConfig,
  ...
}:
let
  firefoxEnabled = noughtyConfig.browser.firefox or false;
in
lib.mkIf firefoxEnabled {
  catppuccin = {
    firefox.enable = true;
  };

  programs = {
    firefox = {
      enable = true;
    };
  };
}
