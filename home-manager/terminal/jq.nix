{
  noughtyConfig,
  ...
}:
let
  catppuccinFlavor = noughtyConfig.catppuccin.flavor or "mocha";
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
