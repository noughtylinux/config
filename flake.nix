{
  description = "Noughty Linux";
  inputs = {
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";
    determinate.inputs.nixpkgs.follows = "nixpkgs-unstable";
    home-manager.url = "github:nix-community/home-manager/release-25.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    system-manager.url = "github:numtide/system-manager";
    system-manager.inputs.nixpkgs.follows = "nixpkgs-unstable";
  };

  outputs =
    {
      self,
      nixpkgs,
      ...
    }@inputs:
    let
      inherit (self) outputs;
      helper = import ./lib { inherit inputs outputs; };
      noughtyConfig = helper.mkConfig { };
      makeDevShell =
        system:
        let
          pkgs = helper.pkgsFor system;
          corePackages = [
            inputs.determinate.packages.${system}.default
            inputs.system-manager.packages.${system}.default
            pkgs.curl
            pkgs.git
            pkgs.gnugrep
            pkgs.home-manager
            pkgs.just
            pkgs.nix-output-monitor
            pkgs.sd
            pkgs.tomlq
          ];
        in
        pkgs.mkShell {
          buildInputs = corePackages;
          shellHook = ''
            echo "🄍 Noughty Linux"
          '';
        };
    in
    {
      devShells = helper.forAllSystems (system: {
        default = makeDevShell system;
      });

      # Home Manager configurations
      homeConfigurations = {
        "${noughtyConfig.user.name}@${noughtyConfig.system.hostname}" = helper.mkHome {
          inherit noughtyConfig;
          system = builtins.currentSystem;
        };
      };

      # System Manager configuration
      systemConfigs.default = helper.mkSystem {
        inherit noughtyConfig;
        system = builtins.currentSystem;
      };
    };
}
