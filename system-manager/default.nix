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
        # AppArmor profile for bwrap in the Nix store
        "apparmor.d/nix_bwrap" = {
          text = ''
            # This profile allows almost everything and only exists to allow bwrap
            # to work on a system with user namespace restrictions being enforced.
            # bwrap is allowed access to user namespaces and capabilities within
            # the user namespace, but its children do not have capabilities,
            # blocking bwrap from being able to be used to arbitrarily by-pass the
            # user namespace restrictions.

            # Note: the nix_bwrap child is stacked against the nix_bwrap profile
            # due to bwrap's use of no-new-privs.

            abi <abi/4.0>,
            include <tunables/global>

            profile nix_bwrap /nix/store/**/bin/*bwrap* flags=(attach_disconnected,mediate_deleted) {
              allow capability,
              # not allow all, to allow for pix stack on systems that don't support
              # rule priority.
              #
              # sadly we have to allow 'm' every where to allow children to work under
              # profile stacking atm.
              allow file rwlkm /{**,},
              allow network,
              allow unix,
              allow ptrace,
              allow signal,
              allow mqueue,
              allow io_uring,
              allow userns,
              allow mount,
              allow umount,
              allow pivot_root,
              allow dbus,

              # stacked like this due to no-new-privs restriction
              # this will stack a target profile against nix_bwrap and nix_unpriv_bwrap
              # Ideally
              # - there would be a transition at userns creation first. This would allow
              #   for the bwrap profile to be tighter, and looser within the user
              #   ns. nix_bwrap will still have to fairly loose until a transition at
              #   namespacing in general (not just user ns) is available.
              # - there would be an independent second target as fallback
              #   This would allow for select target profiles to be used, and not
              #   necessarily stack the nix_unpriv_bwrap in cases where this is desired
              #
              # the ix works here because stack will apply to ix fallback
              # Ideally we would sanitize the environment across a privilege boundary
              # (leaving bwrap into application) but flatpak etc use environment glibc
              # sanitized environment variables as part of the sandbox setup.
              allow pix /** -> &nix_bwrap//&nix_unpriv_bwrap,
            }

            # The unpriv_bwrap profile is used to strip capabilities within the userns
            profile nix_unpriv_bwrap flags=(attach_disconnected,mediate_deleted) {
              # not allow all, to allow for pix stack
              allow file rwlkm /{**,},
              allow network,
              allow unix,
              allow ptrace,
              allow signal,
              allow mqueue,
              allow io_uring,
              allow userns,
              allow mount,
              allow umount,
              allow pivot_root,
              allow dbus,

              # nix_bwrap profile does stacking against itself this will keep the
              # target profile from having elevated privileges in the container.
              # If done recursively the stack will remove any duplicate
              allow pix /** -> &nix_unpriv_bwrap,

              audit deny capability,
            }
          '';
          mode = "0644";
        };
        # AppArmor profile for Ubuntu compatibility of Nix store binaries
        "apparmor.d/nix_store_compat" = {
          text = ''
            abi <abi/4.0>,
            include <tunables/global>

            profile nix_store_compat /nix/store/**/bin/* flags=(unconfined) {
              userns,
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
