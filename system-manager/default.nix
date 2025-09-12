{
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
        pkgs.glow
      ];
    };
    # Only allow NixOS and Ubuntu distributions
    system-manager.allowAnyDistro = false;
  };
}
