{
  inputs,
  lib,
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

  nix =
    let
      flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
    in
    {
      package = pkgs.nix;
      settings = {
        experimental-features = "nix-command flakes";
        # Disable global registry
        flake-registry = "";
        # Workaround for https://github.com/NixOS/nix/issues/9574
        nix-path = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
        warn-dirty = false;
      };
    };

  programs.home-manager.enable = true;
}
