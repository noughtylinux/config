{
  inputs,
  pkgs,
  ...
}:
{
  config = {
    # Set the host platform architecture
    nixpkgs.hostPlatform = pkgs.system;

    # Basic system configuration placeholder
    environment = {
      # System packages will be configured here
      systemPackages = [
        inputs.system-manager.packages.${pkgs.system}.default
      ];
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
