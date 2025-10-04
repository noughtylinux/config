{
  pkgs,
  lib,
  noughtyConfig,
  ...
}:
let
  enabled = noughtyConfig.desktop.display-manager or true;

  # Extract theming configuration
  flavor = noughtyConfig.catppuccin.flavor;
  accent = noughtyConfig.catppuccin.accent;
  isDark = noughtyConfig.catppuccin.palette.isDark;
  palette = noughtyConfig.catppuccin.palette;

  # Build cursor package name
  cursorPackage =
    pkgs.catppuccin-cursors."${flavor}${lib.toUpper (builtins.substring 0 1 accent)}${
      builtins.substring 1 (-1) accent
    }";
  gtkThemePackage = (
    pkgs.catppuccin-gtk.override {
      accents = [ "${accent}" ];
      variant = flavor;
    }
  );
  iconTheme = if isDark then "Papirus-Dark" else "Papirus-Light";

  # Create Hyprland wrapper with logging
  hyprlandWrapper = pkgs.writeShellScript "hyprland-wrapper" ''
    # Clear screen with Catppuccin background color using ANSI escape sequences
    printf '\033]11;${palette.getColor "base"}\007\033[2J\033[H'

    LOG_DIR="${noughtyConfig.user.home}/.local/state/hyprland"
    LOG_FILE="$LOG_DIR/hyprland.log"
    mkdir -p "$LOG_DIR"
    if [ -f "$LOG_FILE" ]; then
      for i in 9 8 7 6 5 4 3 2 1; do
        if [ -f "$LOG_FILE.$i" ]; then
          ${pkgs.coreutils}/bin/mv "$LOG_FILE.$i" "$LOG_FILE.$((i + 1))"
        fi
      done
      ${pkgs.coreutils}/bin/mv "$LOG_FILE" "$LOG_FILE.1"
    fi

    echo "[$(${pkgs.coreutils}/bin/date '+%Y-%m-%d %H:%M:%S')] Starting Hyprland" | ${pkgs.coreutils}/bin/tee -a "$LOG_FILE"

    ${pkgs.expect}/bin/unbuffer ${pkgs.hyprland}/bin/Hyprland "$@" 2>&1 | ${pkgs.coreutils}/bin/tee -a "$LOG_FILE" &>/dev/null
    EXIT_CODE=$?

    echo "[$(${pkgs.coreutils}/bin/date '+%Y-%m-%d %H:%M:%S')] Hyprland exited with code $EXIT_CODE" | ${pkgs.coreutils}/bin/tee -a "$LOG_FILE"
    exit $EXIT_CODE
  '';

  # Create a wrapper script that sets GTK environment variables before launching regreet
  regreetWrapper = pkgs.writeShellScript "regreet-wrapper" ''
    LOG_DIR="/var/log/regreet"
    LOG_FILE="$LOG_DIR/regreet.log"
    mkdir -p "$LOG_DIR"

    # Rotate logs: keep last 10
    if [ -f "$LOG_FILE" ]; then
      for i in 9 8 7 6 5 4 3 2 1; do
        if [ -f "$LOG_FILE.$i" ]; then
          ${pkgs.coreutils}/bin/mv "$LOG_FILE.$i" "$LOG_FILE.$((i + 1))"
        fi
      done
      ${pkgs.coreutils}/bin/mv "$LOG_FILE" "$LOG_FILE.1"
    fi

    export GTK_THEME="catppuccin-${flavor}-${accent}-standard"
    export XCURSOR_THEME="catppuccin-${flavor}-${accent}-cursors"
    export XCURSOR_SIZE="32"
    export XDG_DATA_DIRS="${gtkThemePackage}/share:${cursorPackage}/share:${pkgs.papirus-icon-theme}/share:$XDG_DATA_DIRS"
    exec ${pkgs.cage}/bin/cage -s -- dbus-run-session ${pkgs.greetd.regreet}/bin/regreet --config /etc/noughty/greetd/regreet.toml --logs "$LOG_FILE" --log-level info
  '';

  # Use the wrapper script as the greetd command
  greetdCommand = "${regreetWrapper}";
in
lib.mkIf enabled {
  environment = {
    etc = {
      "noughty/greetd/config.toml" = {
        text = ''
          [terminal]
          vt = 1

          [default_session]
          command = "${greetdCommand}"
          user = "_greetd"
        '';
      };

      "noughty/greetd/regreet.toml" = {
        text = ''
          [background]
          # Reuse the same background image created for GRUB
          path = "/etc/noughty/grub/themes/catppuccin/background.png"
          fit = "Fill"

          [GTK]
          application_prefer_dark_theme = ${lib.boolToString isDark}
          cursor_theme_name = "catppuccin-${flavor}-${accent}-cursors"
          font_name = "Work Sans 16"
          icon_theme_name = "${iconTheme}"
          theme_name = "catppuccin-${flavor}-${accent}-standard"

          [commands]
          reboot = ["systemctl", "reboot"]
          poweroff = ["systemctl", "poweroff"]

          [appearance]
          greeting_msg = "Welcome to Nøughty Linux"

          [widget.clock]
          format = "%H:%M"
          resolution = "1000ms"
          label_width = 128
        '';
      };

      # Create Wayland session desktop file for Hyprland
      "noughty/greetd/hyprland.desktop" = {
        text = ''
          [Desktop Entry]
          Name=Nøughty Hyprland
          Comment=An intelligent dynamic tiling Wayland compositor
          Exec=${hyprlandWrapper}
          Type=Application
          DesktopNames=Hyprland
        '';
      };
    };

    systemPackages = [
      pkgs.greetd.regreet
      pkgs.cage
      gtkThemePackage
      pkgs.catppuccin-cursors."${flavor}${lib.toUpper (builtins.substring 0 1 accent)}${
        builtins.substring 1 (-1) accent
      }"
      pkgs.papirus-icon-theme
    ];
  };
}
