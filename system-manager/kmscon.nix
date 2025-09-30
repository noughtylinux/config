{
  pkgs,
  noughtyConfig,
  ...
}:
let
  # Use Ubuntu's agetty
  agettyBin = "/sbin/agetty";
  # Use Nixpkgs kmscon
  kmsconBin = "${pkgs.kmscon}/bin/kmscon";

  # Access Catppuccin palette from noughtyConfig
  palette = noughtyConfig.catppuccin.palette;

  # Helper function to convert RGB array to comma-separated string for kmscon
  rgbToKmscon =
    colorName:
    let
      rgb = palette.getRGB colorName;
    in
    "${toString rgb.r},${toString rgb.g},${toString rgb.b}";
  noughtyIssue = pkgs.writeTextFile {
    name = "noughty-issue";
    text = ''
      \e[2J\e[H\e[37m\e[1mN\e[36mø\e[37mughty Linux - v${version}\e[0m (\e[34m\4\e[0m) [\e[33m\l\e[0m]

    '';
  };
  version = builtins.getEnv "NOUGHTY_VERSION";

  # Generate kmscon config content
  kmsconConfig = ''
    no-drm
    no-switchvt
    font-name=FiraCode Nerd Font Mono
    font-size=16
    palette=custom
    palette-black=${rgbToKmscon "surface1"}
    palette-red=${rgbToKmscon "red"}
    palette-green=${rgbToKmscon "green"}
    palette-yellow=${rgbToKmscon "yellow"}
    palette-blue=${rgbToKmscon "blue"}
    palette-magenta=${rgbToKmscon "pink"}
    palette-cyan=${rgbToKmscon "teal"}
    palette-light-grey=${rgbToKmscon "subtext0"}
    palette-dark-grey=${rgbToKmscon "surface2"}
    palette-light-red=${rgbToKmscon "red"}
    palette-light-green=${rgbToKmscon "green"}
    palette-light-yellow=${rgbToKmscon "yellow"}
    palette-light-blue=${rgbToKmscon "blue"}
    palette-light-magenta=${rgbToKmscon "pink"}
    palette-light-cyan=${rgbToKmscon "teal"}
    palette-white=${rgbToKmscon "text"}
    palette-foreground=${rgbToKmscon "subtext1"}
    palette-background=${rgbToKmscon "base"}
    sb-size=16384
  '';
in
{
  config = {
    environment = {
      systemPackages = [
        pkgs.kmscon
      ];
      etc."noughty/kmscon/kmscon.conf".text = kmsconConfig;
    };

    # Create kmsconvt@ttyX.services that closely mimics Ubuntu's implementation
    systemd.services = builtins.listToAttrs (
      map
        (tty: {
          name = "kmsconvt@${tty}";
          value = {
            description = "KMS System Console on ${tty}";
            documentation = [ "man:kmscon(1)" ];
            after = [
              "systemd-user-sessions.service"
              "plymouth-quit-wait.service"
              "getty-pre.target"
              "dbus.service"
              "systemd-localed.service"
            ];
            before = [ "getty.target" ];
            conflicts = [
              "rescue.service"
              "getty@${tty}.service"
            ];
            onFailure = [ "getty@${tty}.service" ];
            unitConfig = {
              IgnoreOnIsolate = "yes";
              ConditionPathExists = "/dev/tty0";
            };
            serviceConfig = {
              Environment = [
                "PATH=${pkgs.dbus}/bin:${pkgs.coreutils}/bin:/usr/bin:/bin"
                "DBUS_SYSTEM_BUS_ADDRESS=unix:path=/run/dbus/system_bus_socket"
              ];
              ExecStart = "${kmsconBin} \"--vt=${tty}\" --seats=seat0 --configdir /etc/noughty/kmscon --login -- ${agettyBin} --issue ${noughtyIssue} --login-options '-p -- \\\\u' - xterm-256color";
              TTYPath = "/dev/${tty}";
              TTYReset = "yes";
              TTYVHangup = "yes";
              TTYVTDisallocate = "yes";
              Type = "idle";
              UtmpIdentifier = "${tty}";
            };
            wantedBy = [ "getty.target" ];
            restartIfChanged = false;
          };
        })
        [
          "tty1"
          "tty2"
          "tty3"
          "tty4"
          "tty5"
          "tty6"
        ]
    );

    # Mask Ubuntu's default getty services by symlinking them to /dev/null
    # This prevents conflicts with our kmscon setup
    systemd.tmpfiles.settings."10-mask-getty" = builtins.listToAttrs (
      map
        (tty: {
          name = "/etc/systemd/system/getty@${tty}.service";
          value = {
            L.argument = "/dev/null";
          };
        })
        [
          "tty1"
          "tty2"
          "tty3"
          "tty4"
          "tty5"
          "tty6"
        ]
    );
  };
}
