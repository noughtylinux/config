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
    # Only allow NixOS and Ubuntu distributions
    system-manager.allowAnyDistro = false;
  };
}
