{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
        };
      };

      config = builtins.fromTOML (builtins.readFile ./config.toml);

      # Map shell choice to package
      shellPackage =
        {
          fish = pkgs.fish;
          zsh = pkgs.zsh;
          bash = pkgs.bash;
        }
        .${config.terminal.shell};

      # Core packages for terminal environment
      corePackages = [
        pkgs.git
        pkgs.curl
        pkgs.just
        pkgs.direnv
        shellPackage
      ];

    in
    {
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = corePackages;

        shellHook = ''
          echo "🐧 Noughty Linux"
          echo "User: ${config.user.username}"
          echo "Home: ${config.user.home_directory}"
          echo "Shell: ${config.terminal.shell}"
          echo ""
          echo "Ready to go! 🚀"
        '';
      };
    };
}
