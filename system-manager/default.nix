{
  inputs,
  outputs,
  pkgs,
  ...
}:
{
  config = {
    # Basic system configuration placeholder
    environment = {
      # System packages will be configured here
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
        # Add overlays your own flake exports (from overlays and pkgs dir):
        outputs.overlays.additions
        outputs.overlays.modifications
        outputs.overlays.unstable-packages
        # Add overlays exported from other flakes:
      ];
      # Configure your nixpkgs instance
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
