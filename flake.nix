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

      # Check if config.toml exists - provide fallback if missing
      configPath = ./config.toml;
      configExists = builtins.pathExists configPath;

      # Provide fallback config when config.toml doesn't exist yet
      fallbackConfig = {
        user = {
          name = "ubuntu";
          home = "/home/ubuntu";
        };
        terminal = {
          shell = "bash";
        };
      };

      # Use config.toml if it exists, otherwise use fallback
      config = if configExists then builtins.fromTOML (builtins.readFile configPath) else fallbackConfig;

      # Validate required config sections exist
      validateConfig =
        config:
        assert builtins.hasAttr "user" config || throw "Missing [user] section in config.toml";
        assert builtins.hasAttr "terminal" config || throw "Missing [terminal] section in config.toml";
        assert builtins.hasAttr "name" config.user || throw "Missing name in [user] section";
        assert builtins.hasAttr "home" config.user || throw "Missing home in [user] section";
        assert builtins.hasAttr "shell" config.terminal || throw "Missing shell in [terminal] section";
        config;

      validatedConfig = validateConfig config;

      makeDevShell =
        system:
        let
          pkgs = pkgsFor system;

          corePackages = [
            inputs.determinate.packages.${system}.default
            pkgs.curl
            pkgs.git
            pkgs.nh
            pkgs.home-manager
            pkgs.just
            pkgs.nil
            pkgs.nixfmt-rfc-style
            pkgs.nixpkgs-fmt
            pkgs.nix-output-monitor
            pkgs.sd
            pkgs.tomlq
          ];
        in
        pkgs.mkShell {
          buildInputs = corePackages;
          shellHook = ''
            echo "🐧 Noughty Linux"
            ${
              if configExists then
                ''
                  echo "User: ${validatedConfig.user.name}"
                  echo "Home: ${validatedConfig.user.home}"
                  echo "Shell: ${validatedConfig.terminal.shell}"
                  echo "Architecture: ${system}"
                  echo ""
                  echo "Ready to go! 🚀"
                ''
              else
                ''
                  echo "🟖 config.toml not found"
                  echo "   Run 'just generate-config' to create your personal config"
                ''
            }
          '';
        };
    in
    {
      devShells = forAllSystems (system: {
        default = makeDevShell system;
      });
    };
}
