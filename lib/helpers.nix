{
  inputs,
  outputs,
  ...
}:
{
  # TOML configuration management - independent function
  mkNoughtyConfig =
    {
      tomlPath ? ../config.toml,
    }:
    let
      tomlExists = builtins.pathExists tomlPath;
      tomlConfig = if tomlExists then builtins.fromTOML (builtins.readFile tomlPath) else { };
    in
    {
      system = {
        hostname = builtins.getEnv "HOSTNAME";
        platform = builtins.currentSystem;
      };
      user = {
        name = builtins.getEnv "USER";
        home = builtins.getEnv "HOME";
      };
    }
    // tomlConfig;

  # Helper function for generating home-manager configs - needs noughtyConfig
  mkHome =
    {
      noughtyConfig,
    }:
    inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = inputs.nixpkgs.legacyPackages.${noughtyConfig.system.platform};
      extraSpecialArgs = {
        inherit
          inputs
          outputs
          noughtyConfig
          ;
      };
      modules = [ ../home-manager ];
    };

  forAllSystems = inputs.nixpkgs.lib.genAttrs [
    "x86_64-linux"
    "aarch64-linux"
  ];
}
