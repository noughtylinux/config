{
  inputs,
  lib,
  outputs,
  pkgs,
  ...
}:
{
  imports = [
    inputs.catppuccin.homeModules.catppuccin
    inputs.nix-index-database.homeModules.nix-index
    ./user
    ./desktop
    ./fonts
    ./terminal
  ];

  home = {
    stateVersion = "25.05";
    # WIP: For basic testing only
    packages = with pkgs; [
      firefox
      unstable.hyprland
      kitty
    ];
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
      # Overlays defined via overlays/default.nix and pkgs/default.nix
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.unstable-packages
    ];
    config = {
      allowUnfree = true;
    };
  };

  programs = {
    home-manager.enable = true;
    nh = {
      enable = true;
      clean = {
        dates = "weekly";
        enable = true;
        extraArgs = "--keep 2 --keep-since 5d";
      };
    };
    nix-index.enable = true;
  };
}
