{
  inputs,
  outputs,
  pkgs,
  noughtyConfig,
  ...
}:
let
  # Access Catppuccin palette from noughtyConfig
  palette = noughtyConfig.catppuccin.palette;

  # VT color mapping (16 colors: 0-15) - used for runtime color persistence
  # Standard ANSI colors followed by bright variants
  vtColorMap = [
    "surface1" # 0: black
    "red" # 1: red
    "green" # 2: green
    "yellow" # 3: yellow
    "blue" # 4: blue
    "pink" # 5: magenta
    "teal" # 6: cyan
    "subtext0" # 7: light grey
    "surface2" # 8: dark grey (bright black)
    "red" # 9: bright red
    "green" # 10: bright green
    "yellow" # 11: bright yellow
    "blue" # 12: bright blue
    "pink" # 13: bright magenta
    "teal" # 14: bright cyan
    "text" # 15: white
  ];

  # Generate runtime VT color escape sequences for persistence
  generateVTColorCommands =
    let
      # Generate ANSI escape sequence for each color (0-15)
      # Format: \e]P<index><RRGGBB> where index is hex 0-F
      colorCommands = builtins.genList (
        i:
        let
          colorName = builtins.elemAt vtColorMap i;
          # Use getColor helper to get hex value directly (with #)
          colorHex = builtins.substring 1 (-1) (palette.getColor colorName);
          indexHex = if i < 10 then toString i else builtins.substring (i - 10) 1 "ABCDEF";
        in
        "printf '\\e]P${indexHex}${colorHex}'"
      ) 16;

      # Apply to all VT terminals (tty1-tty6)
      applyToTerminals = terminal: map (cmd: "${cmd} > /dev/${terminal}") colorCommands;
      allTerminals = [
        "tty1"
        "tty2"
        "tty3"
        "tty4"
        "tty5"
        "tty6"
      ];

      # Generate commands for all terminals
      allCommands = builtins.concatLists (map applyToTerminals allTerminals);
    in
    builtins.concatStringsSep " 2>/dev/null\n      " allCommands + " 2>/dev/null";
in
{
  imports = [
    ./fonts.nix
    ./grub.nix
    ./kmscon.nix
  ];

  config = {
    # System services
    systemd.services = {
      # Apply Catppuccin VT colors at runtime for persistence
      vt-colors = {
        description = "Apply Catppuccin VT Color Palette";
        after = [ "multi-user.target" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = pkgs.writeShellScript "apply-vt-colors" ''
            #!/bin/bash
            # Apply Catppuccin palette to all VT terminals via ANSI escape sequences
            # This ensures colors persist beyond boot-time kernel parameters

            ${generateVTColorCommands}

            # Log completion
            echo "Applied Catppuccin VT color palette to all terminals"
          '';
          # Restart on configuration changes (theme switches)
          RestartIfChanged = true;
        };
      };
    };

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
        # Sudoers configuration to allow Nix-managed executables
        "sudoers.d/nix-paths" = {
          text = ''
            # Enable sudo to find executables from user Nix profiles
            # Root already has system Nix paths via /etc/profile (Determinate Nix installer)
            # Extend secure_path to include user-specific and system-manager paths
            Defaults secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin:/run/current-system/sw/bin:${noughtyConfig.user.home}/.nix-profile/bin"
          '';
          mode = "0440";
        };
      };
      systemPackages = [
        inputs.determinate.packages.${pkgs.system}.default
        inputs.system-manager.packages.${pkgs.system}.default
      ];
    };

    nix = {
      # Disable NixOS module management; Determinate Nix will handle configuration
      # https://github.com/numtide/system-manager/issues/267#issuecomment-3335147957
      enable = false;
      package = pkgs.nix;
    };

    nixpkgs = {
      config = {
        allowUnfree = true;
      };
      # Set the host platform architecture
      hostPlatform = pkgs.system;
      overlays = [
        # Overlays defined via overlays/default.nix and pkgs/default.nix
        outputs.overlays.localPackages
        outputs.overlays.modifiedPackages
        outputs.overlays.unstablePackages
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
