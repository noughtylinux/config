# 🎨 Dynamic Catppuccin Theming

Nøughty Linux provides a dynamic Catppuccin palette system that automatically adapts to your chosen flavor and accent color from `config.toml`. Every module receives the palette via `noughtyConfig.catppuccin.palette`.

## Quick Start

```nix
{ noughtyConfig, ... }:
let
  palette = noughtyConfig.catppuccin.palette;
in
{
  # Use helper functions for different formats
  programs.kitty.settings = {
    background = palette.getColor "base";           # #1e1e2e
    foreground = palette.getColor "text";           # #cdd6f4
    cursor = palette.selectedAccent;                # User's chosen accent
  };
}
```

## Palette Functions

- **`getColor "colorName"`** → `#1e1e2e` (hex with #)
- **`getRGB "colorName"`** → `{r=30; g=30; b=46;}` (RGB components)
- **`getHyprlandColor "colorName"`** → `1e1e2e` (hex without #)

## Pre-defined Color Groups

Access common color combinations directly:

```nix
palette.backgrounds.primary     # Base background
palette.backgrounds.secondary   # Mantle (darker)
palette.backgrounds.tertiary    # Crust (darkest)

palette.texts.primary          # Main text
palette.texts.secondary        # Subtext1 (dimmed)
palette.texts.muted           # Subtext0 (muted)

palette.surfaces.primary      # Surface0
palette.surfaces.secondary    # Surface1
palette.surfaces.tertiary     # Surface2
```

## All Available Colors

Base colors: `base`, `mantle`, `crust`
Text colors: `text`, `subtext1`, `subtext0`
Surface colors: `surface0`, `surface1`, `surface2`
Overlay colors: `overlay0`, `overlay1`, `overlay2`

Accent colors: `rosewater`, `flamingo`, `pink`, `mauve`, `red`, `maroon`, `peach`, `yellow`, `green`, `teal`, `sky`, `sapphire`, `blue`, `lavender`

## Real Examples

### Hyprland Configuration
```nix
# From home-manager/desktop/compositor/hyprland/default.nix
decoration.shadow = {
  color = "rgba(${palette.getHyprlandColor "crust"}af)";      # No # prefix
  color_inactive = "rgba(${palette.getHyprlandColor "base"}af)";
};
```

### RGB for System Configs
```nix
# From system-manager/kmscon.nix
rgbToKmscon = colorName:
  let rgb = palette.getRGB colorName;
  in "${toString rgb.r},${toString rgb.g},${toString rgb.b}";  # "30,30,46"
```

### Template-based Configs
```nix
# From home-manager/desktop/compositor/components/rofi/default.nix
configFile = pkgs.writeText "rofi-config" ''
  background-color: ${palette.getColor "base"};
  text-color: ${palette.getColor "text"};
  border-color: ${palette.selectedAccent};
'';
```

## Theme Detection

```nix
# Check if user has light or dark theme
palette.isDark          # true for mocha/macchiato/frappé, false for latte
palette.flavor           # "mocha", "latte", etc.
palette.accent          # "blue", "red", etc.
```

The palette automatically updates when users change their `config.toml` settings, ensuring consistent theming across all applications.
