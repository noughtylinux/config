{
  noughtyConfig,
  ...
}: 
let
  # Access Catppuccin palette from noughtyConfig
  palette = noughtyConfig.catppuccin.palette;
  
  # Helper function to get color as hex string
  getColor = colorName: palette.getColor colorName;
in
{
  imports = [
    ./alacritty.nix
    ./foot.nix
    ./kitty.nix
  ];

  # TODO: Enable terminal-exec when available (Home Manager 25.11+ or unstable)
  xdg = {
    #terminal-exec = {
    #  settings = {
    #    default = [ "Alacritty.desktop" ];
    #  };
    #};
  };

  xresources.properties = {
    "*background" = getColor "base";
    "*foreground" = getColor "text";
    # black
    "*color0" = getColor "surface1";
    "*color8" = getColor "surface2";
    # red
    "*color1" = getColor "red";
    "*color9" = getColor "red";
    # green
    "*color2" = getColor "green";
    "*color10" = getColor "green";
    # yellow
    "*color3" = getColor "yellow";
    "*color11" = getColor "yellow";
    # blue
    "*color4" = getColor "blue";
    "*color12" = getColor "blue";
    #magenta
    "*color5" = getColor "pink";
    "*color13" = getColor "pink";
    #cyan
    "*color6" = getColor "teal";
    "*color14" = getColor "teal";
    #white
    "*color7" = getColor "subtext1";
    "*color15" = getColor "subtext0";

    # Xterm Appearance
    "XTerm*background" = getColor "base";
    "XTerm*foreground" = getColor "text";
    "XTerm*letterSpace" = 0;
    "XTerm*lineSpace" = 0;
    "XTerm*geometry" = "132x50";
    "XTerm.termName" = "xterm-256color";
    "XTerm*internalBorder" = 2;
    "XTerm*faceName" = "FiraCode Nerd Font Mono:size=14:style=Medium:antialias=true";
    "XTerm*boldFont" = "FiraCode Nerd Font Mono:size=14:style=Bold:antialias=true";
    "XTerm*boldColors" = true;
    "XTerm*cursorBlink" = true;
    "XTerm*cursorUnderline" = false;
    "XTerm*saveline" = 2048;
    "XTerm*scrollBar" = false;
    "XTerm*scrollBar_right" = false;
    "XTerm*urgentOnBell" = true;
    "XTerm*depth" = 24;
    "XTerm*utf8" = true;
    "XTerm*locale" = false;
    "XTerm.vt100.metaSendsEscape" = true;
  };
}
