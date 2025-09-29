# Nøughty Linux AI Coding Agent Guide

## Project Architecture: Ubuntu + Nix Hybrid

Nøughty Linux combines Ubuntu Server's hardware compatibility with Nix's declarative configuration. This is **not** a traditional Linux distribution - users start with Ubuntu Server and apply our Nix flake transformation.

### Core Components

- **`flake.nix`**: Main entry point defining `homeConfigurations` (user environment) and `systemConfigs` (system-level config)
- **`lib/helpers.nix`**: Central configuration logic with `mkConfig()`, `mkHome()`, `mkSystem()` functions
- **`config.toml`**: User-facing configuration (generated from `config.toml.in` template)
- **`system-manager/`**: System-level Nix modules (services, fonts, kmscon, etc.)
- **`home-manager/`**: User environment modules (terminal, desktop, apps, scripts)

### Core references

- <https://github.com/numtide/system-manager>
- <https://nix-community.github.io/home-manager/>
- <https://nix-community.github.io/home-manager/options.xhtml>
- <https://github.com/soupglasses/nix-system-graphics>

### Configuration Flow

```
config.toml → lib/helpers.nix:mkConfig() → noughtyConfig → {home-manager, system-manager}
```

The `noughtyConfig` parameter is passed to ALL modules, containing:
- System facts from environment variables (`HOSTNAME`, `USER`, `HOME`)
- User preferences from `config.toml`
- Dynamic Catppuccin palette with helper functions: `getColor`, `getRGB`, `getHyprlandColor`

## Essential Development Patterns

### Development on NixOS
Typically development is done on NixOS and testing is performed on a remote Ubuntu host.
NixOS does not export `HOSTNAME` to the environment by default, so you will to coerce it
when running nix evaluations and other debugging tasks.

### TOML-Driven Configuration
All user choices flow through `config.toml`. Access patterns:
```nix
# In any module accepting noughtyConfig parameter:
selectedShell = noughtyConfig.terminal.shell or "fish";
packages = noughtyConfig.terminal.packages or [];
```

### Dynamic Catppuccin Theming
Colors are dynamically generated from user's flavor/accent choices:
```nix
palette = noughtyConfig.catppuccin.palette;
# Use in configs:
color = palette.getColor "blue";           # Returns hex with #
rgbValue = palette.getRGB "blue";          # Returns {r=137; g=180; b=250;}
hyprColor = palette.getHyprlandColor "blue"; # Hex without # for Hyprland
```

### Module Import Pattern
Directories with `default.nix` auto-import subdirectories:
```nix
# home-manager/scripts/default.nix pattern used throughout
directories = lib.filterAttrs (name: type: type == "directory" && name != "_template") (builtins.readDir ./.);
imports = lib.mapAttrsToList (name: _: import (./${name})) directories;
```

## Critical Workflows

### Build System
```bash
just build           # Build both system and home configs
just build-system    # system-manager only
just build-home      # home-manager only
just switch          # Full deployment with Ubuntu pre/post tasks
```

### Configuration Management
```bash
just generate        # Create config.toml from template (with safety prompt)
just check           # Nix flake validation
nix develop          # Auto-generates config.toml if missing
```

### Ubuntu Integration
The `ubuntu-pre` and `ubuntu-post` recipes handle Ubuntu package management:
- Uses `nala` instead of `apt-get` for better UX
- TOML-driven package removal via `tq -f config.toml ubuntu.remove.${package}`
- Automatic conflict detection for `nix-bin`, `nix-setup-systemd`

## System Manager Constraints

Unlike NixOS, `system-manager` has limited capabilities:
- ✅ `environment.etc`, `environment.systemPackages`, `systemd.services`
- ❌ `users.users.*`, complex PAM configs, full NixOS module ecosystem

**Workarounds:**
- Initial setup handled in `bootstrap.sh` (one-time setup)
- Manual PAM configs via `environment.etc` files
- Always use `nix-system-graphics` for GPU acceleration

## Naming Conventions

### Custom Scripts (all in `home-manager/scripts/`)
- `nout`: Run single package from stable Nixpkgs
- `nosh`: Shell with multiple packages
- `nook`: Nix store inspector
- `nope`: `setsid` wrapper for detached processes
- `halp`: Enhanced help finder for any command

### Justfile Glyphs
Consistent visual language using Unicode glyphs from `just/constants.just`:
- `GLYPH_BUILD` ☭, `GLYPH_SYSTEM` ▣, `GLYPH_HOME` ⌂
- `ERROR`, `WARNING`, `SUCCESS` with colored formatting

## Key Integration Points

### VT Console Theming
`system-manager/kmscon.nix` demonstrates palette integration:
```nix
rgbToKmscon = colorName:
  let rgb = palette.getRGB colorName;
  in "${toString rgb.r},${toString rgb.g},${toString rgb.b}";
```

### Cross-System Dependencies
- Both `mkHome` and `mkSystem` receive same `noughtyConfig`
- `system-manager` uses `nixpkgs-unstable` for newer features
- `home-manager` uses stable `nixpkgs` for reliability

### Bootstrap Integration
The `bootstrap.sh` handles:
- Determinate Nix installation
- `nala` package manager setup
- Repository cloning and first configuration

## Debugging Tips

- `nix develop` automatically handles impure evaluation for `config.toml` access
- Use `just check` for comprehensive flake validation
- Build failures often indicate missing TOML configuration - check `_has_config` guard
- `tq` commands require exact TOML section paths: `tq -f config.toml ubuntu.remove.snapd`
