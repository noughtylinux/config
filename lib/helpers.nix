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
    }:
    let
      tomlExists = builtins.pathExists tomlPath;
      tomlConfig = if tomlExists then builtins.fromTOML (builtins.readFile tomlPath) else { };

      envHostname = builtins.getEnv "HOSTNAME";
      envUsername = builtins.getEnv "USER";
      envHome = builtins.getEnv "HOME";
    in
    # Hard fail if critical environment variables are missing
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
      modules = [ ../home-manager ];
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
