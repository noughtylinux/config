{
  pkgs,
  ...
}:
let
  # Use Ubuntu's agetty
  agettyBin = "/sbin/agetty";
  # Use Nixpkgs kmscon
  kmsconBin = "${pkgs.kmscon}/bin/kmscon";
  noughtyIssue = pkgs.writeTextFile {
    name = "noughty-issue";
    text = ''
      \e[2J\e[H\e[37m\e[1mN\e[36mø\e[37mughty Linux - v${version}\e[0m (\e[34m\4\e[0m) [\e[33m\l\e[0m]

    '';
  };
  version = builtins.getEnv "NOUGHTY_VERSION";

  # Create kmscon config directory like NixOS module does
  configDir = pkgs.writeTextFile {
    name = "kmscon-config";
    destination = "/kmscon.conf";
    text = ''
      no-drm
      no-reset-env
      font-name=FiraCode Nerd Font Mono
      font-size=16
      palette=custom
      palette-black=69,71,90
      palette-red=243,139,168
      palette-green=166,227,161
      palette-yellow=249,226,175
      palette-blue=137,180,250
      palette-magenta=245,194,231
      palette-cyan=148,226,213
      palette-light-grey=127,132,156
      palette-dark-grey=88,91,112
      palette-light-red=243,139,168
      palette-light-green=166,227,161
      palette-light-yellow=249,226,175
      palette-light-blue=137,180,250
      palette-light-magenta=245,194,231
      palette-light-cyan=148,226,213
      palette-white=205,214,244
      palette-foreground=166,173,200
      palette-background=30,30,46
      sb-size=65536
    '';
  };
in
{
  config = {
    environment = {
      systemPackages = [
        pkgs.kmscon
      ];
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
              ExecStart = "${kmsconBin} \"--vt=${tty}\" --seats=seat0 --configdir ${configDir} --login -- ${agettyBin} --issue ${noughtyIssue} --login-options '-p -- \\\\u' - xterm-256color";
              TTYPath = "/dev/${tty}";
              TTYReset = "yes";
              TTYVHangup = "yes";
              TTYVTDisallocate = "yes";
              Type = "idle";
              UtmpIdentifier = "${tty}";
            };
            wantedBy = [ "getty.target" ];
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
