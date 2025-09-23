{
  inputs,
  outputs,
  pkgs,
  ...
}:
{
  imports = [
    ./fonts.nix
    ./kmscon.nix
  ];

  config = {
    environment = {
      systemPackages = [
        inputs.determinate.packages.${pkgs.system}.default
        inputs.system-manager.packages.${pkgs.system}.default
      ];
    };

    nix = {
      # Disable NixOS module management; Determinate Nix will handle configuration
      enable = false;
      package = pkgs.nix;
    };

    nixpkgs = {
      # Set the host platform architecture
      hostPlatform = pkgs.system;
      overlays = [
        # Overlays defined via overlays/default.nix and pkgs/default.nix
        outputs.overlays.localPackages
        outputs.overlays.modifiedPackages
        outputs.overlays.unstablePackages
      ];
      config = {
        allowUnfree = true;
      };
    };

    # Enable system-graphics support
    system-graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = [ ];
      extraPackages32 = [ ];
    };
    # Only allow NixOS and Ubuntu distributions
    system-manager.allowAnyDistro = false;
  };
}
