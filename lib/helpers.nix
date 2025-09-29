{
  inputs,
  outputs,
  ...
}:
let
  # Create nixpkgs instances with allowUnfree enabled
  pkgsFor =
    system:
    import inputs.nixpkgs {
      inherit system;
      config = {
        allowUnfree = true;
      };
    };
in
{
  inherit pkgsFor;

  # Helper to generate attributes for all supported systems
  forAllSystems = inputs.nixpkgs.lib.genAttrs [
    "x86_64-linux"
    "aarch64-linux"
  ];

  # Helper to generate the noughtyConfig from config.toml
  # Use builtins.getEnv (impure) to get system facts from environment
  mkConfig =
    {
      tomlPath ? ../config.toml,
      system,
    }:
    let
      tomlExists = builtins.pathExists tomlPath;
      tomlConfig = if tomlExists then builtins.fromTOML (builtins.readFile tomlPath) else { };

      envHostname = builtins.getEnv "HOSTNAME";
      envUsername = builtins.getEnv "USER";
      envHome = builtins.getEnv "HOME";

      # Base config with environment facts and TOML
      baseConfig =
        if envHostname == "" then
          throw "HOSTNAME environment variable is not set"
        else if envUsername == "" then
          throw "USER environment variable is not set"
        else if envHome == "" then
          throw "HOME environment variable is not set"
        else
          {
            system = {
              hostname = envHostname;
            };
            user = {
              name = envUsername;
              home = envHome;
            };
          }
          // tomlConfig;

      # Extract Catppuccin palette if flavor and accent are set
      catppuccinFlavor = baseConfig.catppuccin.flavor or "mocha";
      catppuccinAccent = baseConfig.catppuccin.accent or "blue";

      # Read palette.json from catppuccin package
      paletteJson = builtins.fromJSON (
        builtins.readFile "${inputs.catppuccin.packages.${system}.palette}/palette.json"
      );
      palette = paletteJson.${catppuccinFlavor}.colors;

      # Helper functions for palette access
      getColor = colorName: palette.${colorName}.hex;
      getRGB = colorName: palette.${colorName}.rgb;
      getHSL = colorName: palette.${colorName}.hsl;
      
      # Hyprland-specific helper that removes # from hex colors
      getHyprlandColor = colorName: builtins.substring 1 (-1) palette.${colorName}.hex;

      # Build complete palette structure
      catppuccinPalette = {
        # Export the complete palette
        colors = palette;

        # Current flavor and accent info
        flavor = catppuccinFlavor;
        accent = catppuccinAccent;

        # Theme variant detection - Latte is light, others are dark
        isDark = catppuccinFlavor != "latte";

        # Export convenient access functions
        inherit getColor getRGB getHSL getHyprlandColor;

        # Current user's selected accent
        selectedAccent = getColor catppuccinAccent;

        # Pre-defined color sets for common use cases
        backgrounds = {
          primary = getColor "base";
          secondary = getColor "mantle";
          tertiary = getColor "crust";
        };

        texts = {
          primary = getColor "text";
          secondary = getColor "subtext1";
          muted = getColor "subtext0";
        };

        surfaces = {
          primary = getColor "surface0";
          secondary = getColor "surface1";
          tertiary = getColor "surface2";
        };

        overlays = {
          primary = getColor "overlay0";
          secondary = getColor "overlay1";
          tertiary = getColor "overlay2";
        };

        # All accent colors for reference
        accents = builtins.listToAttrs (
          map
            (color: {
              name = color;
              value = getColor color;
            })
            [
              "rosewater"
              "flamingo"
              "pink"
              "mauve"
              "red"
              "maroon"
              "peach"
              "yellow"
              "green"
              "teal"
              "sky"
              "sapphire"
              "blue"
              "lavender"
            ]
        );
      };
    in
    # Return base config with palette embedded
    baseConfig
    // {
      catppuccin = (baseConfig.catppuccin or { }) // {
        palette = catppuccinPalette;
      };
    };

  # Helper function for generating home-manager configs
  mkHome =
    {
      noughtyConfig,
      system,
    }:
    inputs.home-manager.lib.homeManagerConfiguration {
      # Home Manager has a required pkgs parameter in its function signature
      pkgs = pkgsFor system;
      extraSpecialArgs = {
        inherit
          inputs
          outputs
          noughtyConfig
          ;
      };
      modules = [
        inputs.catppuccin.homeModules.catppuccin
        inputs.nix-index-database.homeModules.nix-index
        ../home-manager
      ];
    };

  # Helper function for generating system-manager configs
  mkSystem =
    {
      noughtyConfig,
      system,
    }:
    inputs.system-manager.lib.makeSystemConfig {
      extraSpecialArgs = {
        inherit
          inputs
          outputs
          noughtyConfig
          ;
        # system-manager doesn't have a direct pkgs parameter in its API, so pkgs
        # must be provided through extraSpecialArgs for modules to access it
        # system-manager and nix-system-graphics need unstable nixpkgs for newer features
        pkgs = pkgsFor system;
      };
      modules = [
        inputs.nix-system-graphics.systemModules.default
        ../system-manager
      ];
    };
}
