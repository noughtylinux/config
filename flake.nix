{
  description = "Nøughty Linux";
  inputs = {
    catppuccin.url = "github:catppuccin/nix/release-25.05";
    catppuccin.inputs.nixpkgs.follows = "nixpkgs";
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";
    determinate.inputs.nixpkgs.follows = "nixpkgs-unstable";
    home-manager.url = "github:nix-community/home-manager/release-25.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";
    nix-system-graphics.url = "github:soupglasses/nix-system-graphics?rev=9c875e0c56cf2eb272b9102a4f3e24e4e31629fd";
    nix-system-graphics.inputs.nixpkgs.follows = "nixpkgs";
    system-manager.url = "github:numtide/system-manager?rev=e271eedac9a24678ca6cfc61677837422bf474e0";
    system-manager.inputs.nixpkgs.follows = "nixpkgs";
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
      platform = builtins.currentSystem;
      noughtyConfig = helper.mkConfig { system = platform; };
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
            pkgs.jq
            pkgs.just
            pkgs.nix-output-monitor
            pkgs.sd
            pkgs.tomlq
          ];
        in
        pkgs.mkShell {
          buildInputs = corePackages;
          shellHook = '''';
        };
    in
    {
      devShells = helper.forAllSystems (system: {
        default = makeDevShell system;
      });

      # Formatter for .nix files, available via 'nix fmt'
      formatter = helper.forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-rfc-style);

      # Home Manager configurations
      homeConfigurations = {
        "${noughtyConfig.user.name}@${noughtyConfig.system.hostname}" = helper.mkHome {
          inherit noughtyConfig;
          system = platform;
        };
      };

      # Custom packages and modifications, exported as overlays
      overlays = import ./overlays { inherit inputs; };

      # Custom packages; accessible via 'nix build', 'nix shell', etc
      packages = helper.forAllSystems (
        system:
        let
          pkgs = import nixpkgs {
            system = platform;
            config.allowUnfree = true;
            overlays = builtins.attrValues self.overlays;
          };
        in
        import ./pkgs pkgs
      );

      # System Manager configuration
      systemConfigs.default = helper.mkSystem {
        inherit noughtyConfig;
        system = platform;
      };
    };
}
