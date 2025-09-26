{
  lib,
  noughtyConfig,
  pkgs,
  ...
}:
let
  microsoftEdgeEnabled = noughtyConfig.browser.microsoft-edge or false;
in
lib.mkIf microsoftEdgeEnabled {
  catppuccin = {
    chromium.enable = true;
  };

  home = {
    packages = with pkgs; [
      microsoft-edge
    ];
  };
}
