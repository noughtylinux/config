# This file defines overlays
{ inputs, ... }:
{
  # Bring in local packages from the 'pkgs/' directory
  localPackages = final: _prev: import ../pkgs final.pkgs;

  # Change versions, add patches, set compilation flags, anything really.
  # https://nixos.wiki/wiki/Overlays
  modifiedPackages = _final: prev: {
    # Override rofi-unwrapped to remove desktop entries (this is where they come from!)
    rofi-unwrapped = prev.rofi-unwrapped.overrideAttrs (oldAttrs: {
      postInstall = (oldAttrs.postInstall or "") + ''
        rm -f $out/share/applications/rofi.desktop
        rm -f $out/share/applications/rofi-theme-selector.desktop
      '';
    });
  };

  # When applied, Nixpkgs unstable  will be accessible via 'pkgs.unstable'
  unstablePackages = final: _prev: {
    unstable = import inputs.nixpkgs-unstable {
      inherit (final) system;
      config.allowUnfree = true;
      overlays = [
        # Apply the same rofi-unwrapped modification to unstable packages
        (_final: _prev: {
          rofi-unwrapped = _prev.rofi-unwrapped.overrideAttrs (oldAttrs: {
            postInstall = (oldAttrs.postInstall or "") + ''
              rm -f $out/share/applications/rofi.desktop
              rm -f $out/share/applications/rofi-theme-selector.desktop
            '';
          });
        })
      ];
    };
  };
}
