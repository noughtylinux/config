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
      corefonts
      fira
      font-awesome
      lato
      liberation_ttf
      nerd-fonts.fira-code
      nerd-fonts.space-mono
      nerd-fonts.symbols-only
      noto-fonts-emoji
      noto-fonts-monochrome-emoji
      poppins
      source-serif
      symbola
      ubuntu_font_family
      work-sans
    ];
  };

  fonts = {
    fontconfig = {
      enable = true;
      defaultFonts = lib.mkIf fontsConfigure {
        serif = [
          "Source Serif"
          "Noto Color Emoji"
        ];
        sansSerif = [
          "Work Sans"
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
  };
}
