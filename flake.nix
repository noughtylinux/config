{
  description = "Noughty Linux";
  inputs = {
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";
    home-manager.url = "github:nix-community/home-manager/release-25.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
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
      noughtyConfig = helper.mkNoughtyConfig { };

      pkgsFor =
        system:
        import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
          };
        };

      makeDevShell =
        system:
        let
          pkgs = pkgsFor system;

          corePackages = [
            inputs.determinate.packages.${system}.default
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
        };
      };
    };
}
