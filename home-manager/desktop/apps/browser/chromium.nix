{
  lib,
  noughtyConfig,
  ...
}:
let
  chromiumEnabled = noughtyConfig.browser.chromium or false;
in
lib.mkIf chromiumEnabled {
  catppuccin = {
    chromium.enable = true;
  };

  programs = {
    chromium = {
      enable = true;
    };
  };
}
