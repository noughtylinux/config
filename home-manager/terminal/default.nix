{
  config,
  inputs,
  lib,
  noughtyConfig,
  ...
}:
let
  catppuccinAccent = noughtyConfig.catppuccin.accent or "blue";
  catppuccinFlavor = noughtyConfig.catppuccin.flavor or "mocha";
  selectedShell = noughtyConfig.terminal.shell or "fish";
in
{
  imports = [
    inputs.catppuccin.homeModules.catppuccin
    ./bat.nix
    ./bottom.nix
    ./btop.nix
    ./dircolors.nix
    ./eza.nix
    ./starship.nix
  ];

  # Catppuccin is not enabled for everything by default
  # I have custom Catppuccin themes for some programs
  catppuccin = {
    accent = catppuccinAccent;
    flavor = catppuccinFlavor;
    fish.enable = config.programs.fish.enable;
    zsh-syntax-highlighting.enable = config.programs.zsh.enable;
  };

  # Terminal/shell configuration derived from TOML config
  # Always enable bash for scripts and compatibility
  programs = {
    fish.enable = selectedShell == "fish";
    bash.enable = true;
    zsh.enable = selectedShell == "zsh";
  };

  systemd = {
    user = {
      # Nicely reload system units when changing configs
      startServices = "sd-switch";
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
    userDirs = {
      enable = true;
      createDirectories = lib.mkDefault true;
      extraConfig = {
        XDG_SCREENSHOTS_DIR = "${config.home.homeDirectory}/Pictures/Screenshots";
      };
    };
  };
}
