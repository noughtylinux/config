{
  config,
  inputs,
  lib,
  noughtyConfig,
  outputs,
  pkgs,
  ...
}:
let
  # Use validated values from palette (these have already been validated and fallen back if needed)
  catppuccinAccent = noughtyConfig.catppuccin.palette.accent;
  catppuccinFlavor = noughtyConfig.catppuccin.palette.flavor;
  selectedShell = noughtyConfig.terminal.shell or "bash";
in
{
  imports = [
    ./user
    ./desktop
    ./fonts
    ./scripts
    ./terminal
  ];

  # Catppuccin is not enabled for everything by default
  # I have custom Catppuccin themes for some programs
  catppuccin = {
    accent = catppuccinAccent;
    flavor = catppuccinFlavor;
    fish.enable = config.programs.fish.enable;
    zsh-syntax-highlighting.enable = config.programs.zsh.enable;
  };

  home = {
    stateVersion = "25.05";
    sessionVariables = {
      # Enable truecolor for all terminal apps
      COLORTERM = "truecolor";
    };
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
      outputs.overlays.localPackages
      outputs.overlays.modifiedPackages
      outputs.overlays.unstablePackages
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
    # Terminal/shell configuration derived from TOML config
    # Always enable bash for scripts and compatibility
    fish = {
      enable = selectedShell == "fish";
      shellInit = lib.mkIf config.programs.nh.enable ''
        # Set nh search to use the stable channel
        set -gx NH_SEARCH_CHANNEL (norm 2>/dev/null; or echo nixos-unstable)
      '';
    };
    bash = {
      enable = true;
      initExtra = lib.mkIf config.programs.nh.enable ''
        # Set nh search to use the stable channel
        export NH_SEARCH_CHANNEL="$(norm 2>/dev/null || echo nixos-unstable)"
      '';
    };
    zsh = {
      enable = selectedShell == "zsh";
      initContent = lib.mkIf config.programs.nh.enable (
        lib.mkOrder 500 ''
          # Set nh search to use the stable channel
          export NH_SEARCH_CHANNEL="$(norm 2>/dev/null || echo nixos-unstable)"
        ''
      );
    };
  };

  systemd = {
    user = {
      # Nicely reload system units when changing configs
      startServices = "sd-switch";
      systemctlPath = "${pkgs.systemd}/bin/systemctl";
      # Create age keys directory for SOPS
      tmpfiles = {
        rules = [
          "d ${config.home.homeDirectory}/.config/sops/age 0755 ${config.home.username} users - -"
        ];
      };
    };
  };

  xdg = {
    enable = true;
    desktopEntries = {
      cups = {
        name = "Manage Printing";
        noDisplay = true;
      };
      fish = {
        name = "fish";
        noDisplay = true;
      };
    };
    userDirs = {
      enable = true;
      extraConfig = {
        XDG_SCREENSHOTS_DIR = "${config.home.homeDirectory}/Pictures/Screenshots";
      };
      createDirectories = true;
    };
  };
}
