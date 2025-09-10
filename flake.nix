{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      system = "x86_64-linux";
      # Configure nixpkgs to allow unfree packages
      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
        };
      };

      config = builtins.fromTOML (builtins.readFile ./config.toml);

      # Map configuration choices to packages
      shellPackage =
        {
          fish = pkgs.fish;
          zsh = pkgs.zsh;
          bash = pkgs.bash;
        }
        .${config.defaults.shell};

      browserPackage =
        {
          firefox = pkgs.firefox;
          chromium = pkgs.chromium;
          brave = pkgs.brave;
        }
        .${config.defaults.browser};

      terminalEditorPackage =
        {
          neovim = pkgs.neovim;
          helix = pkgs.helix;
          micro = pkgs.micro;
        }
        .${config.defaults.terminal_editor};

      graphicalIdePackage =
        {
          vscode = pkgs.vscode;
          zed = pkgs.zed-editor;
          none = null;
        }
        .${config.defaults.graphical_ide};

      containerRuntimePackages =
        {
          docker = [
            pkgs.docker
            pkgs.docker-compose
          ];
          podman = [
            pkgs.podman
            pkgs.podman-compose
          ];
          none = [ ];
        }
        .${config.defaults.container_runtime};

      # Optional "big" applications
      optionalApps =
        [ ]
        ++ (if config.applications.obs_studio then [ pkgs.obs-studio ] else [ ])
        ++ (if config.applications.blender then [ pkgs.blender ] else [ ])
        ++ (if config.applications.gimp then [ pkgs.gimp ] else [ ])
        ++ (if config.applications.libreoffice then [ pkgs.libreoffice ] else [ ]);

      # Core packages always included
      corePackages = [
        pkgs.git
        pkgs.curl
        pkgs.just
        pkgs.direnv
      ];

      # Filter out null packages and flatten lists
      allPackages =
        corePackages
        ++ [
          shellPackage
          browserPackage
          terminalEditorPackage
        ]
        ++ (if graphicalIdePackage != null then [ graphicalIdePackage ] else [ ])
        ++ containerRuntimePackages
        ++ optionalApps;

    in
    {
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = allPackages;

        shellHook = ''
          echo "🐧 Noughty Linux"
          echo "Shell: ${config.defaults.shell}"
          echo "Browser: ${config.defaults.browser}"
          echo "Terminal Editor: ${config.defaults.terminal_editor}"
          echo "IDE: ${config.defaults.graphical_ide}"
          echo "Container Runtime: ${config.defaults.container_runtime}"
          echo ""
          echo "Applications installed:"
          ${if config.applications.obs_studio then ''echo "  📹 OBS Studio"'' else ""}
          ${if config.applications.blender then ''echo "  🎨 Blender"'' else ""}
          ${if config.applications.gimp then ''echo "  🖼️  GIMP"'' else ""}
          ${if config.applications.libreoffice then ''echo "  📄 LibreOffice"'' else ""}
          echo ""
          echo "Ready to go! 🚀"
        '';
      };
    };
}
