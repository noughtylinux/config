{
  noughtyConfig,
  ...
}:
let
  customConfigPath = ./custom.nix;
  customConfigExists = builtins.pathExists customConfigPath;
in
{
  imports = if customConfigExists then [ customConfigPath ] else [ ];

  home = {
    username = noughtyConfig.user.name;
    homeDirectory = noughtyConfig.user.home;
  };
}
