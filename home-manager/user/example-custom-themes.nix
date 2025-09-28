# Example: Custom waybar theme using Catppuccin palette
# This demonstrates how users can theme applications not covered by the Catppuccin module

{
  lib,
  noughtyConfig,
  ...
}:
{
  # Example: Custom waybar styling using Catppuccin colors
  programs.waybar = lib.mkIf (noughtyConfig.catppuccin.palette != null) {
    enable = true;
    style = 
      let
        p = noughtyConfig.catppuccin.palette;
      in ''
        * {
          font-family: "JetBrains Mono Nerd Font";
          font-size: 14px;
          border: none;
          border-radius: 0;
        }

        window#waybar {
          background: ${p.backgrounds.primary};
          border-bottom: 3px solid ${p.selectedAccent};
          color: ${p.texts.primary};
        }

        .modules-left,
        .modules-center,
        .modules-right {
          background: ${p.backgrounds.secondary};
        }

        #workspaces button {
          padding: 0 8px;
          background: ${p.surfaces.primary};
          color: ${p.texts.secondary};
          border: 1px solid ${p.overlays.primary};
        }

        #workspaces button:hover {
          background: ${p.surfaces.secondary};
          color: ${p.texts.primary};
        }

        #workspaces button.active {
          background: ${p.selectedAccent};
          color: ${p.backgrounds.primary};
        }

        #clock {
          padding: 0 16px;
          background: ${p.accents.blue};
          color: ${p.backgrounds.primary};
          font-weight: bold;
        }

        #battery {
          padding: 0 16px;
          background: ${p.accents.green};
          color: ${p.backgrounds.primary};
        }

        #battery.warning {
          background: ${p.accents.yellow};
          color: ${p.backgrounds.primary};
        }

        #battery.critical {
          background: ${p.accents.red};
          color: ${p.backgrounds.primary};
        }

        #network {
          padding: 0 16px;
          background: ${p.accents.teal};
          color: ${p.backgrounds.primary};
        }

        #pulseaudio {
          padding: 0 16px;
          background: ${p.accents.mauve};
          color: ${p.backgrounds.primary};
        }
      '';

    settings = [{
      layer = "top";
      position = "top";
      height = 30;
      spacing = 4;
      
      modules-left = [ "hyprland/workspaces" ];
      modules-center = [ "clock" ];
      modules-right = [ "pulseaudio" "network" "battery" ];

      "hyprland/workspaces" = {
        disable-scroll = true;
        all-outputs = true;
        format = "{name}";
      };

      clock = {
        format = "{:%a %d %b %H:%M}";
        tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
      };

      battery = {
        states = {
          warning = 30;
          critical = 15;
        };
        format = "{capacity}% {icon}";
        format-charging = "{capacity}% ";
        format-plugged = "{capacity}% ";
        format-icons = [ "" "" "" "" "" ];
      };

      network = {
        format-wifi = "{essid} ";
        format-ethernet = "{ipaddr}/{cidr} ";
        format-linked = "{ifname} (No IP) ";
        format-disconnected = "Disconnected ⚠";
      };

      pulseaudio = {
        scroll-step = 1;
        format = "{volume}% {icon}";
        format-bluetooth = "{volume}% {icon} ";
        format-bluetooth-muted = " {icon} ";
        format-muted = " ";
        format-icons = {
          headphone = "";
          hands-free = "";
          headset = "";
          phone = "";
          portable = "";
          car = "";
          default = [ "" "" "" ];
        };
        on-click = "pactl set-sink-mute @DEFAULT_SINK@ toggle";
        on-click-right = "pavucontrol";
      };
    }];
  };

  # Example: Custom application theme file
  home.file.".config/custom-theme/catppuccin.conf".text =
    let
      p = noughtyConfig.catppuccin.palette;
    in
    lib.optionalString (p != null) ''
      # Noughty Linux Custom Theme - Catppuccin ${p.flavor} with ${p.accent} accent
      
      [colors]
      background = "${p.backgrounds.primary}"
      foreground = "${p.texts.primary}"
      accent = "${p.selectedAccent}"
      
      # Semantic colors
      success = "${p.accents.green}"
      warning = "${p.accents.yellow}"
      error = "${p.accents.red}"
      info = "${p.accents.blue}"
      
      # UI elements
      border = "${p.overlays.primary}"
      selection = "${p.surfaces.secondary}"
      hover = "${p.surfaces.tertiary}"
      
      # All accent colors for advanced theming
      ${builtins.concatStringsSep "\n" (
        lib.mapAttrsToList (name: value: "${name} = \"${value}\"") p.accents
      )}
    '';
}
