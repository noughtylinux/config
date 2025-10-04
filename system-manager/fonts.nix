{
  pkgs,
  ...
}:
{
  config = {
    # Create font symlinks in /usr/local/share/fonts for system font discovery
    systemd.tmpfiles.rules = [
      # Create fonts directory
      "d /usr/local/share/fonts/noughty 0755 root root -"

      # Symlink Nerd Font packages to system font directory
      "L+ /usr/local/share/fonts/noughty/FiraCode - - - - ${pkgs.nerd-fonts.fira-code}/share/fonts/truetype/NerdFonts/FiraCode"
      "L+ /usr/local/share/fonts/noughty/symbola - - - - ${pkgs.symbola}/share/fonts/opentype"
      "L+ /usr/local/share/fonts/noughty/Symbols - - - - ${pkgs.nerd-fonts.symbols-only}/share/fonts/truetype/NerdFonts/Symbols"
      "L+ /usr/local/share/fonts/noughty/UbuntuMono - - - - ${pkgs.nerd-fonts.ubuntu-mono}/share/fonts/truetype/NerdFonts/UbuntuMono"
      "L+ /usr/local/share/fonts/noughty/WorkSans - - - - ${pkgs.work-sans}/share/fonts/opentype"
    ];
  };
}
