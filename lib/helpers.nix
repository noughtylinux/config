{
  inputs,
  outputs,
  ...
}:
let
  # Create nixpkgs instances with allowUnfree enabled and overlays applied
  pkgsFor =
    system:
    import inputs.nixpkgs {
      inherit system;
      config = {
        allowUnfree = true;
      };
      # Apply all overlays including local packages (kmscon, libtsm, etc.)
      overlays = builtins.attrValues outputs.overlays;
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

      # Valid Catppuccin options
      validFlavors = [
        "latte"
        "frappe"
        "macchiato"
        "mocha"
      ];
      validAccents = [
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
      ];

      # Valid desktop compositor options
      validDesktopCompositors = [
        "hyprland"
        "wayfire"
      ];

      # Extract Catppuccin palette with validation and fallback
      rawFlavor = baseConfig.catppuccin.flavor or "mocha";
      rawAccent = baseConfig.catppuccin.accent or "blue";

      # Validate flavor with warning and fallback to mocha
      catppuccinFlavor =
        if builtins.elem rawFlavor validFlavors then
          rawFlavor
        else
          builtins.trace "WARNING: Invalid Catppuccin flavor '${rawFlavor}'. Valid options: ${builtins.concatStringsSep ", " validFlavors}. Falling back to 'mocha'." "mocha";

      # Validate accent with warning and fallback to blue
      catppuccinAccent =
        if builtins.elem rawAccent validAccents then
          rawAccent
        else
          builtins.trace "WARNING: Invalid Catppuccin accent '${rawAccent}'. Valid options: ${builtins.concatStringsSep ", " validAccents}. Falling back to 'mauve'." "mauve";

      # Extract and validate desktop shell
      rawDesktopCompositor = baseConfig.desktop.compositor or "";

      # Validate desktop shell with warning and set to null if invalid or empty
      desktopCompositor =
        if rawDesktopCompositor == "" then
          null
        else if builtins.elem rawDesktopCompositor validDesktopCompositors then
          rawDesktopCompositor
        else
          builtins.trace "WARNING: Invalid desktop compositor '${rawDesktopCompositor}'. Valid options: ${builtins.concatStringsSep ", " validDesktopCompositors}. Desktop features will be disabled." null;

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
        inherit
          getColor
          getRGB
          getHSL
          getHyprlandColor
          ;

        # Current user's selected accent
        selectedAccent = getColor catppuccinAccent;

        # VT color mapping (16 ANSI colors: 0-15)
        # Standard ANSI colors followed by bright variants
        # Note: Index 0 is used as default background, so it must be "base"
        vtColorMap = [
          "base" # 0: black (also used as default background)
          "red" # 1: red
          "green" # 2: green
          "yellow" # 3: yellow
          "blue" # 4: blue
          "pink" # 5: magenta
          "teal" # 6: cyan
          "subtext0" # 7: light grey
          "surface1" # 8: dark grey (bright black)
          "red" # 9: bright red
          "green" # 10: bright green
          "yellow" # 11: bright yellow
          "blue" # 12: bright blue
          "pink" # 13: bright magenta
          "teal" # 14: bright cyan
          "text" # 15: white
        ];

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
    # Return base config with palette embedded and validated desktop shell
    baseConfig
    // {
      catppuccin = (baseConfig.catppuccin or { }) // {
        palette = catppuccinPalette;
      };
      desktop = (baseConfig.desktop or { }) // {
        compositor = desktopCompositor;
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
