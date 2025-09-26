{
  lib,
  noughtyConfig,
  pkgs,
  ...
}:
let
  googleChromeEnabled = noughtyConfig.browser.google-chrome or false;
in
lib.mkIf googleChromeEnabled {
  catppuccin = {
    chromium.enable = true;
  };

  home = {
    packages = with pkgs; [
      google-chrome
    ];
  };
}
