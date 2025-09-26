{
  lib,
  noughtyConfig,
  pkgs,
  ...
}:
let
  vivaldiEnabled = noughtyConfig.browser.vivaldi or false;
in
lib.mkIf vivaldiEnabled {
  catppuccin = {
    vivaldi.enable = true;
  };

  home = {
    packages = with pkgs; [
      vivaldi
      vivaldi-ffmpeg-codecs
    ];
  };
}
