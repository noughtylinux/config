# This file defines overlays
{ inputs, ... }:
{
  # Bring in local packages from the 'pkgs/' directory
  localPackages = final: _prev: import ../pkgs final.pkgs;

  # Change versions, add patches, set compilation flags, anything really.
  # https://nixos.wiki/wiki/Overlays
  modifiedPackages = _final: prev: {
    # Acquire latest Aetf/kmscon which includes various fixes and improvements
    kmscon = prev.kmscon.overrideAttrs (oldAttrs: {
      version = "9.0.1-unstable-2025-09-18";
      src = prev.fetchFromGitHub {
        owner = "Aetf";
        repo = "kmscon";
        rev = "f99c5a0279738fa23e8e13c34d590a7b43e67e5a";
        sha256 = "sha256-RwfFXGRPDlO5WYTD2JWsZnKs3QngbMjc6kWRzCUR1gw=";
      };
    });
  };

  # When applied, Nixpkgs unstable  will be accessible via 'pkgs.unstable'
  unstablePackages = final: _prev: {
    unstable = import inputs.nixpkgs-unstable {
      inherit (final) system;
      config.allowUnfree = true;
    };
  };
}
