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

  # Helper to generate the noughtyConfig from config.toml
  # Use builtins.getEnv (impure) to ensure the flake evaluates when config.toml is missing
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
      };
      user = {
        name = builtins.getEnv "USER";
        home = builtins.getEnv "HOME";
      };
    }
    // tomlConfig;

  # Helper function for generating home-manager configs
  mkHome =
    {
      noughtyConfig,
      system,
    }:
    inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = pkgsFor system;
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
