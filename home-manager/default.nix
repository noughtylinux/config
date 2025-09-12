{
  pkgs,
  ...
}:
{
  imports = [
    ./user
    ./terminal
  ];

  home = {
    stateVersion = "25.05";
  };

  nixpkgs = {
    config = {
      allowUnfree = true;
    };
  };

  nix = {
    package = pkgs.nix;
    settings = {
      experimental-features = "nix-command flakes";
    };
  };

  programs.home-manager.enable = true;
}
