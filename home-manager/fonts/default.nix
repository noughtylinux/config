{
  lib,
  noughtyConfig,
  pkgs,
  ...
}:
let
  fontsConfigure = noughtyConfig.fonts.configure or false;
in
{
  home = {
    packages = with pkgs; [
      nerd-fonts.fira-code
      nerd-fonts.fira-mono
      nerd-fonts.space-mono
      nerd-fonts.symbols-only
      corefonts
      fira
      font-awesome
      lato
      liberation_ttf
      noto-fonts-emoji
      noto-fonts-monochrome-emoji
      poppins
      source-serif
      symbola
      ubuntu_font_family
      unscii
      work-sans
    ];
  };

  fonts.fontconfig = {
    enable = true;
    defaultFonts = lib.mkIf fontsConfigure {
      serif = [
        "Source Serif"
        "Noto Color Emoji"
      ];
      sansSerif = [
        "Fira Sans"
        "Noto Color Emoji"
      ];
      monospace = [
        "FiraCode Nerd Font Mono"
        "Font Awesome 6 Free"
        "Font Awesome 6 Brands"
        "Symbola"
        "Noto Emoji"
      ];
      emoji = [
        "Noto Color Emoji"
      ];
    };
  };
}
