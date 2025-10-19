pkgs: {
  catppuccin-gtk = pkgs.callPackage ./catppuccin-gtk { };
  kmscon = pkgs.callPackage ./kmscon { };
  libtsm = pkgs.callPackage ./libtsm { };
  wayfire = pkgs.callPackage ./wayfire { wlroots = pkgs.wlroots_0_19; };
  wayfirePlugins = pkgs.callPackage ./wayfire/plugins.nix { };
}
