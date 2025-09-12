{
  inputs,
  outputs,
  noughtyConfig,
  ...
}:
{
  # Helper function for generating home-manager configs
  mkHome =
    {
      system,
    }:
    inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = inputs.nixpkgs.legacyPackages.${system};
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
