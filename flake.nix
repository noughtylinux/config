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
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      pkgsFor =
        system:
        import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
          };
        };

      # Check if config.toml exists - provide fallback if missing
      tomlPath = ./config.toml;
      tomlExists = builtins.pathExists tomlPath;

      # Read TOML config if it exists, otherwise use empty set
      tomlConfig = if tomlExists then builtins.fromTOML (builtins.readFile tomlPath) else { };

      # Merge TOML config with system facts from environment variables
      noughtyConfig = tomlConfig // {
        system = (tomlConfig.system or { }) // {
          hostname = builtins.getEnv "HOSTNAME";
        };
        user = (tomlConfig.user or { }) // {
          name = builtins.getEnv "USER";
          home = builtins.getEnv "HOME";
        };
      };

      # Helper library
      helper = import ./lib {
        inherit
          inputs
          outputs
          noughtyConfig
          ;
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
      devShells = forAllSystems (system: {
        default = makeDevShell system;
      });

      # Home Manager configurations
      homeConfigurations = {
        "${noughtyConfig.user.name}@${noughtyConfig.system.hostname}" = helper.mkHome {
          system = builtins.currentSystem;
        };
      };
    };
}
