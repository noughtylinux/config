{
  inputs,
  lib,
  outputs,
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

  news.display = "silent";

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

  nixpkgs = {
    overlays = [
      # Add overlays your own flake exports (from overlays and pkgs dir):
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.unstable-packages
    ];
    config = {
      allowUnfree = true;
    };
  };

  programs.home-manager.enable = true;
}
