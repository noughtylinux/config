{
  inputs,
  outputs,
  pkgs,
  ...
}:
let
  # Catppuccin kernel parameters for boot-time VT theming
  catppuccinKernelParams = "vt.default_red=30,243,166,249,137,245,148,186,88,243,166,249,137,245,148,166 vt.default_grn=30,139,227,226,180,194,226,194,91,139,227,226,180,194,226,173 vt.default_blu=46,168,161,175,250,231,213,222,112,168,161,175,250,231,213,200";
in
{
  imports = [
    ./fonts.nix
    ./kmscon.nix
  ];

  config = {
    environment = {
      etc = {
        # AppArmor profiles for Nix
        "apparmor.d/nix_brave" = {
          text = ''
            # This profile allows everything and only exists to give the
            # application a name instead of having the label "unconfined"

            abi <abi/4.0>,
            include <tunables/global>

            profile nix_brave /nix/store/**/bin/brave flags=(unconfined) {
              userns,

              # Site-specific additions and overrides. See local/README for details.
              include if exists <local/brave>
            }
          '';
          mode = "0644";
        };
        "apparmor.d/nix_chrome" = {
          text = ''
            # This profile allows everything and only exists to give the
            # application a name instead of having the label "unconfined"

            abi <abi/4.0>,
            include <tunables/global>

            profile nix_chrome /nix/store/**/bin/google-chrome-stable flags=(unconfined) {
              userns,

              # Site-specific additions and overrides. See local/README for details.
              include if exists <local/chrome>
            }
          '';
          mode = "0644";
        };
        "apparmor.d/nix_chromium" = {
          text = ''
            # This profile allows everything and only exists to give the
            # application a name instead of having the label "unconfined"

            abi <abi/4.0>,
            include <tunables/global>

            @{chromium} = {,ungoogled-}chromium{,-browser}

            profile nix_chromium /nix/store/**/bin/@{chromium} flags=(unconfined) {
              userns,

              # Site-specific additions and overrides. See local/README for details.
              include if exists <local/chromium>
            }
          '';
          mode = "0644";
        };
        "apparmor.d/nix_firefox" = {
          text = ''
            # This profile allows everything and only exists to give the
            # application a name instead of having the label "unconfined"

            abi <abi/4.0>,
            include <tunables/global>

            profile nix_firefox /nix/store/**/bin/firefox{,-esr,-bin} flags=(unconfined) {
              userns,

              # Site-specific additions and overrides. See local/README for details.
              include if exists <local/firefox>
            }
          '';
          mode = "0644";
        };
        "apparmor.d/nix_msedge" = {
          text = ''
            # This profile allows everything and only exists to give the
            # application a name instead of having the label "unconfined"

            abi <abi/4.0>,
            include <tunables/global>

            profile nix_msedge /nix/store/**/bin/microsoft-edge flags=(unconfined) {
              userns,

              # Site-specific additions and overrides. See local/README for details.
              include if exists <local/msedge>
            }
          '';
          mode = "0644";
        };
        "apparmor.d/nix_mullvad-browser" = {
          text = ''
            # This profile allows everything and only exists to give the
            # application a name instead of having the label "unconfined"

            abi <abi/4.0>,
            include <tunables/global>

            profile nix_firefox /nix/store/**/bin/mullvad-browser flags=(unconfined) {
              userns,

              # Site-specific additions and overrides. See local/README for details.
              include if exists <local/firefox>
            }
          '';
          mode = "0644";
        };
        "apparmor.d/nix_vivaldi" = {
          text = ''
            # This profile allows everything and only exists to give the
            # application a name instead of having the label "unconfined"

            abi <abi/4.0>,
            include <tunables/global>

            profile brave /nix/store/**/bin/vivaldi flags=(unconfined) {
              userns,

              # Site-specific additions and overrides. See local/README for details.
              include if exists <local/vivaldi-bin>
            }
          '';
          mode = "0644";
        };
        "default/grub.d/99-catppuccin.cfg" = {
          text = ''
            # Catppuccin Mocha theme for kernel VT - managed by Nix
            GRUB_CMDLINE_LINUX_DEFAULT="$GRUB_CMDLINE_LINUX_DEFAULT ${catppuccinKernelParams}"
          '';
          mode = "0644";
        };
      };
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
