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
  # Use builtins.getEnv (impure) to ensure the flake evaluates when config.toml is missing
  mkConfig =
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
        pkgs = pkgsFor system;
      };
      modules = [ ../system-manager ];
    };
}
