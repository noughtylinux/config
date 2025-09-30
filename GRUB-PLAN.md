# GRUB Theme Integration Plan

## Executive Summary

This document outlines the implementation plan for integrating the Catppuccin GRUB theme into Noughty Linux, leveraging the existing dynamic Catppuccin palette system and system-manager architecture. The theme will dynamically adapt to user-configured flavors and accents while maintaining Ubuntu compatibility through the existing ubuntu-pre/post deployment patterns.

## Project Context

**Architecture**: Noughty Linux is a Ubuntu+Nix hybrid system using `system-manager` for system-level configuration and `home-manager` for user environments. The project features a sophisticated dynamic Catppuccin theming system via `noughtyConfig.catppuccin.palette` with helper functions (`getColor`, `getRGB`, `getHyprlandColor`).

**Constraints**:
- `system-manager` limitations: Only `systemd.services`, `environment.etc`, and `environment.systemPackages` primitives available
- Ubuntu deployment integration required via ubuntu-pre/post patterns
- Dynamic theming must integrate with existing `noughtyConfig` palette system
- Asset management through direct file bundling in repo and `environment.etc` deployment

**Current State**:
- Existing GRUB configuration in `system-manager/default.nix` with VT kernel parameters
- Established Catppuccin palette integration patterns throughout codebase
- Working ubuntu-pre/post deployment workflows in justfile

## Technical Analysis

### Upstream Theme Structure (catppuccin/grub)
```
themes/
├── catppuccin-frappe-grub-theme/
├── catppuccin-latte-grub-theme/
├── catppuccin-macchiato-grub-theme/
└── catppuccin-mocha-grub-theme/
    ├── theme.txt           # Main theme configuration
    ├── background.png      # Background image (1920x1080)
    ├── logo.png           # Catppuccin logo
    ├── select_c.png       # Selection graphics
    ├── select_e.png
    ├── select_w.png
    ├── icons/             # Menu item icons
    │   ├── arch.png
    │   ├── debian.png
    │   └── ubuntu.png
    └── font.pf2          # Terminus font
```

### Dynamic Integration Requirements
1. **Theme Selection**: Use `noughtyConfig.catppuccin.flavor` to select appropriate theme variant
2. **Color Customization**: Override theme.txt colors using palette helper functions
3. **Asset Management**: Bundle static assets directly in repo structure, deploy via `environment.etc`
4. **Ubuntu Integration**: Direct deployment to `/etc/noughty/grub/themes/` via `environment.etc` and systemd tmpfiles

## Implementation Strategy

### Phase 1: Foundation Infrastructure

**Objective**: Establish core GRUB theme infrastructure with hybrid static/dynamic asset system.

#### 1.1 Asset Repository Structure
**Location**: `system-manager/grub/assets/`

**Directory Structure**:
```
system-manager/grub/
├── assets/
│   ├── logo.png          # Catppuccin logo (static)
│   ├── font.pf2          # Terminus font (static)
│   └── icons/
│       ├── arch.png      # Static icons
│       ├── debian.png
│       └── ubuntu.png
├── generators/           # NetPBM generation scripts
│   └── generate-assets.nix
└── default.nix           # GRUB theme module
```

**Key Components**:
- Generate background.png and select_*.png dynamically using NetPBM based on user's palette
- Bundle static assets (logos, icons, fonts) directly in repository structure
- Dynamic color generation for both theme.txt configuration and PNG assets
- NetPBM-based asset generation integrated with Nix build system

#### 1.2 System Manager Integration
**Location**: `system-manager/grub/default.nix`

**Core Requirements**:
- Use `environment.etc` to deploy theme files directly to `/etc/noughty/grub/themes/catppuccin/`
- Generate dynamic `theme.txt` using `noughtyConfig.catppuccin.palette`
- Deploy static assets via `environment.etc` with appropriate file references
- Integrate with existing GRUB configuration in `system-manager/default.nix`

**Expected Interface**:
```nix
{ noughtyConfig, lib, pkgs, ... }:
let
  palette = noughtyConfig.catppuccin.palette;

  # Generate theme.txt content dynamically
  themeConfig = ''
    # Dynamic Catppuccin GRUB theme
    desktop-color: "${palette.getColor "base"}"
    terminal-color: "${palette.getColor "text"}"
    menu_color_normal: "${palette.getColor "text"}"
    menu_color_highlight: "${palette.getColor "accent"}"
    # Additional theme properties...
  '';

  # Generate dynamic PNG assets using NetPBM
  backgroundPng = pkgs.runCommand "grub-background.png"
    { buildInputs = [ pkgs.netpbm ]; } ''
    ppmmake '${palette.getColor "base"}' 640 480 | pnmtopng > $out
  '';

  selectCPng = pkgs.runCommand "grub-select-c.png"
    { buildInputs = [ pkgs.netpbm ]; } ''
    ppmmake '${palette.getColor "surface1"}' 8 36 | pnmtopng > $out
  '';

  selectEPng = pkgs.runCommand "grub-select-e.png"
    { buildInputs = [ pkgs.netpbm ]; } ''
    ppmmake '${palette.getColor "surface1"}' 5 36 | pnmtopng > $out
  '';

  selectWPng = pkgs.runCommand "grub-select-w.png"
    { buildInputs = [ pkgs.netpbm ]; } ''
    ppmmake '${palette.getColor "surface1"}' 5 36 | pnmtopng > $out
  '';
in
{
  # Deploy theme configuration
  environment.etc."noughty/grub/themes/catppuccin/theme.txt".text = themeConfig;

  # Deploy dynamically generated assets
  environment.etc."noughty/grub/themes/catppuccin/background.png".source = backgroundPng;
  environment.etc."noughty/grub/themes/catppuccin/select_c.png".source = selectCPng;
  environment.etc."noughty/grub/themes/catppuccin/select_e.png".source = selectEPng;
  environment.etc."noughty/grub/themes/catppuccin/select_w.png".source = selectWPng;

  # Deploy static assets
  environment.etc."noughty/grub/themes/catppuccin/logo.png".source = ./assets/logo.png;
  environment.etc."noughty/grub/themes/catppuccin/font.pf2".source = ./assets/font.pf2;
  environment.etc."noughty/grub/themes/catppuccin/icons/ubuntu.png".source = ./assets/icons/ubuntu.png;
  # Additional static asset deployments...
}
```

### Phase 2: Dynamic Palette Integration

**Objective**: Implement sophisticated color customization using the existing palette system.

#### 2.1 Theme Configuration Generator
**Location**: `lib/grub-theme.nix`

**Core Logic**:
- Generate `theme.txt` dynamically using `noughtyConfig.catppuccin.palette`
- Map Catppuccin color roles to GRUB theme properties
- Support accent color customization for interactive elements
- Maintain theme structure while allowing color overrides

**Color Mapping Strategy**:
```nix
# Expected color mapping
palette = noughtyConfig.catppuccin.palette;
grubColors = {
  desktop_color = palette.getColor "base";
  terminal_color = palette.getColor "text";
  menu_color_normal = palette.getColor "text";
  menu_color_highlight = palette.getColor "accent";  # User's accent choice
  # Additional mappings...
};
```

#### 2.2 Dynamic Asset Generation
**Scope**: Implement NetPBM-based dynamic PNG generation
- Background.png (640×480) generated from palette base color
- Selection graphics (select_c.png 8×36, select_e.png 5×36, select_w.png 5×36) from `surface1` color
  - Frappé: `#414559`, Latte: `#CCD0DA`, Macchiato: `#363A4F`, Mocha: `#313244`
  - All map to Catppuccin `surface1` color role for consistent selection indicators
- Static assets (logo, icons, fonts) remain bundled in repository
- NetPBM commands integrated into Nix build process

### Phase 3: Asset Management System

**Objective**: Implement robust direct asset deployment via system-manager primitives.

#### 3.1 Environment.etc Asset Deployment
**Location**: `system-manager/grub/default.nix`

**Requirements**:
- Deploy all static assets via `environment.etc` to `/etc/noughty/grub/themes/catppuccin/`
- Generate dynamic `theme.txt` using palette integration
- Use systemd tmpfiles for proper permissions and directory creation
- Maintain single source of truth for assets in repository structure

#### 3.2 System-Manager Deployment Strategy
**Integration**: Extend existing system-manager workflows

**Deployment Components**:
- `environment.etc` entries for all theme files
- Systemd tmpfiles for directory permissions management
- Integration with existing GRUB configuration in `system-manager/default.nix`
- Automatic theme activation through ubuntu-post patterns

**Asset Deployment Pattern**:
```nix
environment.etc = {
  # Theme configuration (dynamically generated)
  "noughty/grub/themes/catppuccin/theme.txt".text = themeConfig;

  # Dynamically generated PNG assets
  "noughty/grub/themes/catppuccin/background.png".source = backgroundPng;  # NetPBM generated
  "noughty/grub/themes/catppuccin/select_c.png".source = selectCPng;      # NetPBM generated
  "noughty/grub/themes/catppuccin/select_e.png".source = selectEPng;      # NetPBM generated
  "noughty/grub/themes/catppuccin/select_w.png".source = selectWPng;      # NetPBM generated

  # Static assets (bundled in repository)
  "noughty/grub/themes/catppuccin/logo.png".source = ./assets/logo.png;
  "noughty/grub/themes/catppuccin/font.pf2".source = ./assets/font.pf2;
  "noughty/grub/themes/catppuccin/icons/ubuntu.png".source = ./assets/icons/ubuntu.png;
};
```

### Phase 4: GRUB Configuration Integration

**Objective**: Complete integration with system GRUB configuration and Ubuntu deployment.

#### 4.1 System Manager Extension
**Location**: `system-manager/default.nix` (extend existing GRUB config)

**Integration Points**:
```nix
# Expected integration with existing config
boot.loader.grub = {
  theme = "/etc/noughty/grub/themes/catppuccin";
  splashImage = null;  # Use theme background instead
  # Preserve existing VT configuration
};
```

#### 4.2 Ubuntu Integration via Environment.etc
**Strategy**: Direct deployment through system-manager's environment.etc primitive

**Deployment Process**:
- Theme assets deployed to `/etc/noughty/grub/themes/catppuccin/` via `environment.etc`
- Systemd tmpfiles ensure proper directory structure and permissions
- Ubuntu GRUB configuration references theme via absolute path `/etc/noughty/grub/themes/catppuccin`
- `update-grub` automatically picks up theme from configured location

**Integration Benefits**:
- No manual copying required - system-manager handles deployment
- Atomic updates through Nix evaluation and system-manager activation
- Proper file permissions and ownership via systemd tmpfiles
- Leverages existing system-manager infrastructure

### Phase 5: Enhancement & Optimization

**Objective**: Polish user experience and add advanced features.

#### 5.1 Configuration Options
**Location**: `config.toml.in` (extend template)

**New Configuration Section**:
```toml
[boot]
grub_theme = true  # Enable/disable GRUB theme
grub_timeout = 5   # Boot menu timeout
```

**Integration**: Extend `lib/helpers.nix:mkConfig()` to process boot configuration

#### 5.2 Testing & Validation
**Test Suite Components**:
- Theme syntax validation
- Color palette verification
- Asset integrity checks
- Ubuntu deployment simulation
- Multi-flavor testing

## Technical Specifications

### Color Palette Integration

**Palette Helper Usage**:
```nix
palette = noughtyConfig.catppuccin.palette;

# GRUB theme color extraction
colors = {
  background = palette.getColor "base";      # Main background
  foreground = palette.getColor "text";     # Text color
  highlight = palette.getColor "accent";    # User's accent choice
  secondary = palette.getColor "surface0";  # Secondary elements
  border = palette.getColor "overlay0";     # Borders and dividers
};
```

**Theme.txt Color Mapping**:
- `desktop_color`: Background color from palette.base
- `terminal_color`: Text color from palette.text
- `menu_color_normal`: Normal menu items from palette.text
- `menu_color_highlight`: Selected items from user's accent color
- `scrollbar_color`: Scrollbar from palette.overlay0

### Asset Management Architecture

**Hybrid Generation Strategy**:
- Dynamic PNG generation for color-dependent assets using NetPBM
- Static bundling for logos, icons, and fonts in `system-manager/grub/assets/`
- NetPBM integration via Nix derivations for build-time asset generation
- Palette-driven asset creation ensures perfect color matching

**File Structure in Repository**:
```
system-manager/grub/assets/
├── logo.png          # Catppuccin logo (static)
├── font.pf2          # Terminus font (static)
└── icons/
    ├── ubuntu.png    # Ubuntu icon (static)
    ├── debian.png    # Debian icon (static)
    └── arch.png      # Arch icon (static)

# Dynamically generated at build time:
# - background.png (640×480) from palette.base
# - select_c.png (8×36) from palette.surface1
# - select_e.png (5×36) from palette.surface1
# - select_w.png (5×36) from palette.surface1
```

### Ubuntu Integration Patterns

**Deployment Workflow**:
1. System-manager deploys theme assets to `/etc/noughty/grub/themes/catppuccin/` via `environment.etc`
2. Dynamic `theme.txt` generated with user's Catppuccin palette configuration
3. GRUB configuration references theme via `/etc/noughty/grub/themes/catppuccin` path
4. `update-grub` automatically discovers and applies theme during ubuntu-post

**Validation Checks**:
- Verify theme.txt syntax and color values
- Confirm all required assets present in `/etc/noughty/grub/themes/catppuccin/`
- Validate GRUB configuration references theme correctly
- Test theme activation through system-manager deployment

## Risk Assessment

### High-Risk Areas
- **Ubuntu GRUB Integration**: System GRUB configuration changes require careful validation
- **Asset Path Management**: Nix store paths vs. Ubuntu system paths need proper mapping
- **Theme Syntax Validation**: Invalid theme.txt can break GRUB boot menu

### Medium-Risk Areas
- **Color Palette Edge Cases**: Unusual accent colors may need fallback strategies
- **Asset Resolution**: Different display resolutions may affect theme rendering
- **Upstream Changes**: Catppuccin GRUB repository updates may require adaptation

### Low-Risk Areas
- **Nix Package Building**: Well-established patterns with existing Catppuccin packages
- **File Copy Operations**: Standard asset deployment through ubuntu-post
- **Configuration Templating**: Established TOML processing pipeline

### Risk Mitigation Strategies
- **Incremental Testing**: Each phase builds on validated foundations
- **Fallback Mechanisms**: Preserve existing GRUB configuration as backup
- **Validation Pipeline**: Theme syntax and color validation before deployment
- **Documentation**: Clear rollback procedures for failed deployments

## Testing Strategy

### Development Testing
- **System-Manager Build**: `just build-system` to validate GRUB module integration
- **Theme Configuration**: Generate and inspect theme.txt with different palette settings
- **Color Verification**: Test palette integration with different flavors/accents
- **NetPBM Generation**: Verify dynamic PNG generation with correct dimensions and colors
- **Asset Integrity**: Verify static assets present in repository, dynamic assets generated correctly

### Integration Testing
- **System Manager**: Test theme module integration with existing GRUB config
- **Ubuntu Deployment**: Validate ubuntu-post asset copying and GRUB updates
- **Multi-Flavor**: Test all Catppuccin flavors (Latte, Frappé, Macchiato, Mocha)
- **Configuration Options**: Test TOML configuration parsing and application

### User Acceptance Testing
- **Boot Experience**: Visual validation of themed boot menu
- **Functionality**: Ensure boot menu remains fully functional
- **Responsiveness**: Test menu navigation and selection
- **Accessibility**: Verify text readability and contrast

## Collaboration Guidelines

### For AI Engineers
- **Context Requirements**: Always analyze existing `noughtyConfig` patterns before implementing
- **Code Style**: Follow established Nix formatting and naming conventions throughout project
- **Error Handling**: Implement graceful fallbacks for missing assets or invalid configurations
- **Documentation**: Maintain inline comments explaining Catppuccin-specific color mappings

### For Human Engineers
- **Phase-by-Phase Review**: Each implementation phase should be reviewed before proceeding
- **Visual Validation**: Human review required for color choices and visual aesthetics
- **Ubuntu Testing**: Physical Ubuntu system testing for deployment validation
- **User Experience**: Evaluate boot menu usability and visual coherence

### Shared Responsibilities
- **Asset Updates**: Monitor upstream Catppuccin GRUB repository for updates
- **Configuration Testing**: Validate TOML configuration options across different user scenarios
- **Documentation Maintenance**: Keep implementation plan updated as work progresses
- **Integration Verification**: Ensure seamless integration with existing Noughty Linux patterns

## Success Criteria

### Functional Requirements
- ✅ GRUB boot menu displays with Catppuccin theme matching user's flavor choice
- ✅ Theme colors dynamically reflect user's accent color selection
- ✅ All static assets (background, logo, icons) properly loaded and displayed
- ✅ Boot functionality remains completely unchanged from pre-theme behavior

### Integration Requirements
- ✅ Theme configuration generated using existing `noughtyConfig.catppuccin.palette` system
- ✅ Asset management follows established Nix package patterns in project
- ✅ Ubuntu deployment integrates seamlessly with existing ubuntu-pre/post workflows
- ✅ Configuration options added to `config.toml` with sensible defaults

### Quality Requirements
- ✅ Implementation follows existing code patterns and architectural decisions
- ✅ Error handling provides graceful fallbacks for asset or configuration failures
- ✅ Documentation sufficient for future maintenance and extension
- ✅ Testing validates functionality across all supported Catppuccin flavors

### User Experience Requirements
- ✅ Boot menu theme matches desktop environment theme creating visual coherence
- ✅ Text remains readable and accessible across all flavor combinations
- ✅ Theme enhances rather than hinders boot menu functionality
- ✅ Configuration options provide meaningful user control without complexity

## Conclusion

This implementation plan provides a comprehensive, phased approach to integrating the Catppuccin GRUB theme into Noughty Linux while preserving the project's architectural integrity and user experience principles. The plan leverages existing infrastructure patterns, maintains Ubuntu compatibility, and provides a foundation for future boot-time theming enhancements.

The modular design allows for iterative implementation and testing, ensuring each phase delivers value while building toward a complete, cohesive solution that seamlessly integrates with Noughty Linux's dynamic theming system.
