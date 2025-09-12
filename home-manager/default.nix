{
  noughtyConfig,
  pkgs,
  ...
}:
{
  imports = [
    ./user
    ./terminal
  ];

  home = {
    username = noughtyConfig.user.name;
    homeDirectory = noughtyConfig.user.home;
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
