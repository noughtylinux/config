{
  pkgs,
  lib,
  noughtyConfig,
  ...
}:
let
  enabled = if builtins.isString noughtyConfig.desktop.compositor then true else false;
  compositorExecutable =
    if noughtyConfig.desktop.compositor == "hyprland" then
      "${pkgs.hyprland}/bin/Hyprland"
    else if noughtyConfig.desktop.compositor == "wayfire" then
      "${pkgs.wayfire}/bin/wayfire"
    else
      throw "Unsupported compositor: ${noughtyConfig.desktop.compositor}";
  # Extract theming configuration
  flavor = noughtyConfig.catppuccin.palette.flavor;
  accent = noughtyConfig.catppuccin.palette.accent;
  isDark = noughtyConfig.catppuccin.palette.isDark;
  palette = noughtyConfig.catppuccin.palette;

  # Build cursor package name
  cursorThemeName = "catppuccin-${flavor}-${accent}-cursors";
  cursorThemePackage =
    pkgs.catppuccin-cursors."${flavor}${lib.toUpper (builtins.substring 0 1 accent)}${
      builtins.substring 1 (-1) accent
    }";
  gtkThemeName = "catppuccin-${flavor}-${accent}-standard";
  gtkThemePackage = (
    pkgs.catppuccin-gtk.override {
      accents = [ "${accent}" ];
      size = "standard";
      variant = flavor;
    }
  );
  iconThemeName = if noughtyConfig.catppuccin.palette.isDark then "Papirus-Dark" else "Papirus-Light";
  iconThemePackage = pkgs.catppuccin-papirus-folders.override {
    inherit flavor;
    inherit accent;
  };

  # Create compositor wrapper with logging
  compositorWrapper = pkgs.writeShellScript "compositor-wrapper" ''
    # Clear screen with Catppuccin background color using ANSI escape sequences
    printf '\033]11;${palette.getColor "base"}\007\033[2J\033[H'

    LOG_DIR="${noughtyConfig.user.home}/.local/state/${noughtyConfig.desktop.compositor}"
    LOG_FILE="$LOG_DIR/${noughtyConfig.desktop.compositor}.log"
    mkdir -p "$LOG_DIR"
    if [ -f "$LOG_FILE" ]; then
      for i in 9 8 7 6 5 4 3 2 1; do
        if [ -f "$LOG_FILE.$i" ]; then
          ${pkgs.coreutils}/bin/mv "$LOG_FILE.$i" "$LOG_FILE.$((i + 1))"
        fi
      done
      ${pkgs.coreutils}/bin/mv "$LOG_FILE" "$LOG_FILE.1"
    fi

    echo "[$(${pkgs.coreutils}/bin/date '+%Y-%m-%d %H:%M:%S')] Starting ${noughtyConfig.desktop.compositor}" | ${pkgs.coreutils}/bin/tee -a "$LOG_FILE"

    ${pkgs.expect}/bin/unbuffer ${compositorExecutable} "$@" 2>&1 | ${pkgs.coreutils}/bin/tee -a "$LOG_FILE" &>/dev/null
    EXIT_CODE=$?

    echo "[$(${pkgs.coreutils}/bin/date '+%Y-%m-%d %H:%M:%S')] ${noughtyConfig.desktop.compositor} exited with code $EXIT_CODE" | ${pkgs.coreutils}/bin/tee -a "$LOG_FILE"
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

    export GTK_THEME="${gtkThemeName}"
    export XCURSOR_THEME="${cursorThemeName}"
    export XCURSOR_SIZE="32"
    export XDG_DATA_DIRS="${gtkThemePackage}/share:${cursorThemePackage}/share:${iconThemePackage}/share:$XDG_DATA_DIRS"
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
          # Revolutionary VT allocation: VT9 for graphical session
          # This allows VT1-8 to serve as console "workspaces" matching desktop's 8 workspaces
          # Keyboard mapping: Ctrl+Alt+F1-F8 = console workspaces, Ctrl+Alt+F9 = graphical
          vt = 9

          [default_session]
          command = "${greetdCommand}"
          user = "_greetd"
        '';
      };

      "noughty/greetd/regreet.toml" = {
        text = ''
          [background]
          # Reuse the same background image created for GRUB
          path = "/etc/noughty/backgrounds/Catppuccin-1920x1200.png"
          fit = "Cover"

          [GTK]
          application_prefer_dark_theme = ${lib.boolToString isDark}
          cursor_theme_name = "${cursorThemeName}"
          font_name = "Work Sans 16"
          icon_theme_name = "${iconThemeName}"
          theme_name = "${gtkThemeName}"

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

      # Create Wayland desktop session files
      "noughty/greetd/hyprland.desktop" = lib.mkIf (noughtyConfig.desktop.compositor == "hyprland") {
        text = ''
          [Desktop Entry]
          Name=Nøughty Hyprland
          Comment=An intelligent dynamic tiling Wayland compositor
          Exec=${compositorWrapper}
          Type=Application
          DesktopNames=Hyprland
        '';
      };
      "noughty/greetd/wayfire.desktop" = lib.mkIf (noughtyConfig.desktop.compositor == "wayfire") {
        text = ''
          [Desktop Entry]
          Name=Nøughty Wayfire
          Comment=3D Wayland compositor
          Exec=${compositorWrapper}
          Type=Application
          DesktopNames=Wayfire
        '';
      };
    };

    systemPackages = [
      cursorThemePackage
      gtkThemePackage
      iconThemePackage
      pkgs.greetd.regreet
      pkgs.cage
    ];
  };
}
