# Catppuccin palette integration for noughtyConfig
{
  config,
  noughtyConfig,
  ...
}:
let
  catppuccinAccent = noughtyConfig.catppuccin.accent or "blue";
  catppuccinFlavor = noughtyConfig.catppuccin.flavor or "mocha";
  
  # Check if Catppuccin sources are available
  catppuccinSources = config.catppuccin.sources or null;
  
  # Create palette if sources are available
  catppuccinPalette = 
    if catppuccinSources != null then
      let
        paletteJson = builtins.fromJSON (builtins.readFile "${catppuccinSources.palette}/palette.json");
        palette = paletteJson.${catppuccinFlavor}.colors;

        # Helper function to get hex values
        getColor = colorName: palette.${colorName}.hex;

        # Helper function to get RGB values  
        getRGB = colorName: palette.${colorName}.rgb;

        # Helper function to get HSL values
        getHSL = colorName: palette.${colorName}.hsl;
      in
      {
        # Export the complete palette
        colors = palette;

        # Current flavor and accent info
        flavor = catppuccinFlavor;
        accent = catppuccinAccent;

        # Export convenient access functions
        inherit getColor getRGB getHSL;

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
        accents = builtins.listToAttrs (map (color: {
          name = color;
          value = getColor color;
        }) [
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
        ]);
      }
    else
      null;

  # Extended noughtyConfig with palette
  extendedNoughtyConfig = noughtyConfig // {
    catppuccin = (noughtyConfig.catppuccin or {}) // {
      palette = catppuccinPalette;
    };
  };
in
{
  # Make the extended config available to all modules
  _module.args = {
    noughtyConfig = extendedNoughtyConfig;
  };
}
