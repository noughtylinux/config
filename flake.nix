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

      config = builtins.fromTOML (builtins.readFile ./config.toml);

      # Validate required config sections exist
      validateConfig =
        config:
        assert builtins.hasAttr "user" config || throw "Missing [user] section in config.toml";
        assert builtins.hasAttr "terminal" config || throw "Missing [terminal] section in config.toml";
        assert builtins.hasAttr "username" config.user || throw "Missing username in [user] section";
        assert
          builtins.hasAttr "home_directory" config.user || throw "Missing home_directory in [user] section";
        assert builtins.hasAttr "shell" config.terminal || throw "Missing shell in [terminal] section";
        config;

      validatedConfig = validateConfig config;

      makeDevShell =
        system:
        let
          pkgs = pkgsFor system;

          # Map shell choice to package
          shellPackage =
            {
              fish = pkgs.fish;
              zsh = pkgs.zsh;
              bash = pkgs.bash;
            }
            .${validatedConfig.terminal.shell};

          corePackages = [
            inputs.determinate.packages.${system}.default
            pkgs.git
            pkgs.curl
            pkgs.just
            pkgs.home-manager
            pkgs.nh
            pkgs.nil
            pkgs.nixfmt-rfc-style
            pkgs.nixpkgs-fmt
            pkgs.nix-output-monitor
          ];
        in
        pkgs.mkShell {
          buildInputs = corePackages;

          shellHook = ''
            echo "🐧 Noughty Linux"
            echo "User: ${validatedConfig.user.username}"
            echo "Home: ${validatedConfig.user.home_directory}"
            echo "Shell: ${validatedConfig.terminal.shell}"
            echo "Architecture: ${system}"
            echo ""
            echo "Ready to go! 🚀"
          '';
        };

    in
    {
      devShells = forAllSystems (system: {
        default = makeDevShell system;
      });
    };
}
