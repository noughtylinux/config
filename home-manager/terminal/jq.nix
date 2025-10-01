{
  noughtyConfig,
  ...
}:
let
  # Use validated value from palette (already validated and fallen back if needed)
  catppuccinFlavor = noughtyConfig.catppuccin.palette.flavor;
in
{
  programs = {
    jq = {
      enable = true;
    };
    jqp = {
      enable = true;
      settings = {
        theme = {
          name = "catppuccin-${catppuccinFlavor}";
        };
      };
    };
  };
}
