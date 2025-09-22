{
  inputs,
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
      # Disable NixOS module management; Determinate Nix will handle it
      enable = false;
      package = pkgs.nix;
    };

    # Set the host platform architecture
    nixpkgs.hostPlatform = pkgs.system;

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
