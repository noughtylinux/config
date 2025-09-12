{
  noughtyConfig,
  ...
}:
{
  home = {
    username = noughtyConfig.user.name;
    homeDirectory = "/home/${noughtyConfig.user.name}";
  };
}
