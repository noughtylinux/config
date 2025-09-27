{
  noughtyConfig,
  ...
}:
{
  home = {
    username = noughtyConfig.user.name;
    homeDirectory = noughtyConfig.user.home;
  };
}
