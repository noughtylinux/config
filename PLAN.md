# Display Manager Implementation Plan

This plan provides a structured approach to implementing the display manager while working within system-manager constraints and leveraging proven NixOS patterns.

## greetd + Cage + ReGreet for Noughty Linux

### **Project Context**
Implement a modern, themed display manager for Noughty Linux using:
- **greetd**: Lightweight, secure display manager daemon
- **Cage**: Minimal Wayland compositor for kiosk mode
- **ReGreet**: Beautiful GTK4 greeter with Catppuccin theming
- **system-manager**: NixOS-style service management (limited capabilities)

### **Research Phase: Technical Analysis Complete**

#### **system-manager Capabilities**
Based on numtide/system-manager analysis, the following NixOS module features are available:
- **environment.etc**: Configuration file generation in `/etc/`
- **environment.systemPackages**: System-wide package installation
- **systemd.services**: Service definitions with full systemd configuration
- **systemd.tmpfiles.settings**: Directory and file management rules
- **Limited PAM support**: Basic authentication configuration
- **User/group management**: System user creation (limited functionality)

#### **Key NixOS Module Analysis Results**

**greetd.nix (nixos/modules/services/display-managers/greetd.nix):**
```nix
# Core service configuration pattern
systemd.services.greetd = {
  aliases = [ "display-manager.service" ];
  unitConfig = {
    Wants = [ "systemd-user-sessions.service" ];
    After = [ "systemd-user-sessions.service" "getty@tty1.service" ];
    Conflicts = [ "getty@tty1.service" ];
  };
  serviceConfig = {
    ExecStart = "${pkgs.greetd.greetd}/bin/greetd --config ${configFile}";
    Type = "idle";
    Restart = "on-success";
    IgnoreSIGPIPE = false;
    SendSIGHUP = true;
    TimeoutStopSec = "30s";
    KeyringMode = "shared";
  };
  wantedBy = [ "graphical.target" ];
};
```

**cage.nix (nixos/modules/services/wayland/cage.nix):**
```nix
# VT1 management and display configuration
systemd.services."cage-tty1" = {
  after = [ "systemd-user-sessions.service" "plymouth-quit.service" "systemd-logind.service" ];
  conflicts = [ "getty@tty1.service" ];
  serviceConfig = {
    TTYPath = "/dev/tty1";
    TTYReset = "yes"; TTYVHangup = "yes"; TTYVTDisallocate = "yes";
    StandardInput = "tty-fail";
    PAMName = "cage";
  };
};
```

**regreet.nix (nixos/modules/programs/regreet.nix):**
```nix
# Configuration file generation and theming
environment.etc = {
  "greetd/regreet.toml".source = settingsFormat.generate "regreet.toml" cfg.settings;
  "greetd/regreet.css" = { text = cfg.extraCss; };
};
# Directory management via tmpfiles
systemd.tmpfiles.settings."10-regreet" = {
  "/var/lib/regreet".d = { user = "greeter"; group = "greeter"; mode = "0755"; };
  "/var/log/regreet".d = { user = "greeter"; group = "greeter"; mode = "0755"; };
};
```

### **Implementation Phase Structure**

#### **Phase 1: Foundation Setup (Week 1)**
**Goals:** Basic greetd service functionality
**Deliverables:**
- [x] **Research Complete**: NixOS modules analysed, system-manager constraints identified
- [ ] greetd daemon service definition
- [ ] Basic configuration file generation via environment.etc
- [ ] User/group management for greeter user
- [ ] VT1 allocation and getty override

**Key Implementation Tasks:**
1. **Service Definition** (based on actual working greetd.service):
   ```nix
   systemd.services.greetd = {
     aliases = [ "display-manager.service" ];  # Standard display manager alias
     description = "Greetd display manager";
     wantedBy = [ "graphical.target" ];
     wants = [ "systemd-user-sessions.service" ];
     after = [
       "systemd-user-sessions.service"
       "getty@tty1.service"
       "plymouth-quit-wait.service"
       "kmsconvt@tty1.service"  # Conflict with existing kmscon
     ];
     conflicts = [
       "getty@tty1.service"
       "kmsconvt@tty1.service"  # Cannot run both on VT1
     ];
     serviceConfig = {
       ExecStart = "${pkgs.greetd.greetd}/bin/greetd --config /etc/greetd/config.toml";
       Type = "idle";
       Restart = "on-success";
       IgnoreSIGPIPE = false;
       SendSIGHUP = true;
       TimeoutStopSec = "30s";
       KeyringMode = "shared";
     };
     # Don't restart on config changes to avoid disrupting active sessions
     restartIfChanged = false;
   };
   ```

2. **User Management** (system-manager limitation - manual user creation required):
   ```bash
   # just recipes will manage system users (based on NixOS pattern)
   sudo useradd -r -s /usr/bin/nologin -d /var/empty -c "Greeter user" greeter
   sudo groupadd -f greeter  # -f = don't fail if exists
   sudo usermod -a -G greeter greeter
   ```

3. **Configuration Generation** (matches NixOS greetd.nix defaults):
   ```nix
   environment.etc."greetd/config.toml".text = ''
     [terminal]
     vt = 1

     [default_session]
     # Based on NixOS regreet.nix: dbus-run-session cage -s -- regreet
     command = "${pkgs.dbus}/bin/dbus-run-session ${pkgs.cage}/bin/cage -s -- ${pkgs.greetd.regreet}/bin/regreet"
     user = "greeter"
   '';
   ```

4. **Directory Management** (based on NixOS tmpfiles pattern):
   ```nix
   # Note: system-manager uses settings format, not rules
   systemd.tmpfiles.settings."10-greetd" = {
     "/var/cache/greetd".d = { user = "greeter"; group = "greeter"; mode = "0755"; };
   };
   ```

5. **Disable Conflicting Services**:
   ```nix
   # Ensure getty and kmscon don't conflict on tty1
   systemd.services."autovt@tty1".enable = false;
   systemd.services."getty@tty1".enable = false;
   ```

**Critical Constraint**: system-manager cannot create users/groups dynamically. just recipes will handle user creation and management.

#### **Phase 2: Compositor Integration (Week 2)**
**Goals:** Cage + ReGreet visual functionality
**Deliverables:**
- [ ] Cage compositor integration with custom wrapper script
- [ ] ReGreet GTK4 greeter setup with Catppuccin theming
- [ ] Display management integration (kanshi or direct cage config)
- [ ] Session detection and launch capability

**Key Implementation Tasks:**
1. **Cage Wrapper Script** (based on NixOS regreet.nix default command):

   **Option A: Direct Command (NixOS default)**:
   ```nix
   # NixOS regreet.nix uses: dbus-run-session cage ${cageArgs} -- regreet
   # This is the standard approach for simple setups
   command = "${pkgs.dbus}/bin/dbus-run-session ${pkgs.cage}/bin/cage -s -- ${pkgs.greetd.regreet}/bin/regreet";
   ```

   **Option B: Custom Wrapper (Martin's Production Setup)**:
   ```nix
   # Based on Appendix A working configuration - includes kanshi for multi-monitor
   regreetCage = pkgs.writeShellScriptBin "regreet-cage" ''
     # Start regreet in a Wayland kiosk using Cage
     function cleanup() {
       ${pkgs.procps}/bin/pkill kanshi || true
     }
     trap cleanup EXIT

     # Optional kanshi profile for display configuration (see Appendix A)
     KANSHI_REGREET="$(${pkgs.coreutils}/bin/head --lines 1 --quiet /etc/kanshi/regreet 2>/dev/null | ${pkgs.gnused}/bin/sed 's/ //g')"
     if [ -n "$KANSHI_REGREET" ]; then
       exec ${pkgs.cage}/bin/cage -m last -s -- sh -c \
         '${pkgs.kanshi}/bin/kanshi --config /etc/kanshi/regreet & \
          exec ${pkgs.greetd.regreet}/bin/regreet'
     else
       exec ${pkgs.cage}/bin/cage -m last -s ${pkgs.greetd.regreet}/bin/regreet
     fi
   '';
   ```

   **Recommendation**: Start with Option A (direct command) for simplicity. Use Option B only if you need advanced display management for multi-monitor setups or screencasting scenarios.

   **Note**: Kanshi integration is optional and primarily for edge cases like preventing display manager startup on dummy HDMI dongles used for virtual screens during screencasting. Most users can use the simple cage-only path.

   **Optional Kanshi Profile** (for edge cases):
   ```nix
   # /etc/kanshi/regreet - example profile for display management
   environment.etc."kanshi/regreet".text = ''
     profile {
       output DP-3 disable
       output DP-2 disable
       output DP-1 enable mode 2560x2880@60Hz position 0,0 scale 1
     }
   '';
   ```

2. **ReGreet Configuration** (based on actual working `/etc/greetd/regreet.toml` from Appendix A):
   ```nix
   environment.etc."greetd/regreet.toml".text = ''
     [GTK]
     application_prefer_dark_theme = true
     cursor_theme_name = "catppuccin-${noughtyConfig.catppuccin.flavor}-${noughtyConfig.catppuccin.accent}-cursors"
     font_name = "Work Sans 16"
     icon_theme_name = "Papirus-Dark"
     theme_name = "catppuccin-${noughtyConfig.catppuccin.flavor}-${noughtyConfig.catppuccin.accent}-standard"

     [appearance]
     greeting_msg = "${noughtyConfig.user.name}, welcome to Nøughty Linux"

     [background]
     fit = "Cover"
     path = "/etc/backgrounds/Catppuccin-${noughtyConfig.display.resolution}.png"

     [commands]
     poweroff = ["/run/current-system/sw/bin/systemctl", "poweroff"]
     reboot = ["/run/current-system/sw/bin/systemctl", "reboot"]
   '';
   ```

3. **Directory Management** (based on NixOS regreet.nix tmpfiles):
   ```nix
   systemd.tmpfiles.settings."10-regreet" = {
     # ReGreet 0.2.0+ uses /var/lib, older versions use /var/cache
     "/var/lib/regreet".d = { user = "greeter"; group = "greeter"; mode = "0755"; };
     "/var/cache/regreet".d = { user = "greeter"; group = "greeter"; mode = "0755"; };
     "/var/log/regreet".d = { user = "greeter"; group = "greeter"; mode = "0755"; };
   };
   ```

#### **Phase 3: Theming & Polish (Week 3)**
**Goals:** Catppuccin integration and UX refinement
**Deliverables:**
- [ ] Dynamic Catppuccin theming from config.toml
- [ ] Noughty Linux branding integration
- [ ] Custom wallpaper system with resolution detection
- [ ] Session management and cleanup

**Key Implementation Tasks:**
1. **Dynamic Theming System** (matches structure from Appendix A `/etc/greetd/regreet.toml`):
   ```nix
   # Template-based configuration generation
   regreetConfig = noughtyConfig: pkgs.writeText "regreet.toml" ''
     [GTK]
     application_prefer_dark_theme = true
     cursor_theme_name = "catppuccin-${noughtyConfig.catppuccin.flavor}-${noughtyConfig.catppuccin.accent}-cursors"
     font_name = "Work Sans 16"
     icon_theme_name = "Papirus-Dark"
     theme_name = "catppuccin-${noughtyConfig.catppuccin.flavor}-${noughtyConfig.catppuccin.accent}-standard"

     [appearance]
     greeting_msg = "${noughtyConfig.user.name}, welcome to Nøughty Linux"

     [background]
     fit = "Cover"
     path = "/etc/backgrounds/Catppuccin-${noughtyConfig.display.resolution}.png"

     [commands]
     poweroff = ["/run/current-system/sw/bin/systemctl", "poweroff"]
     reboot = ["/run/current-system/sw/bin/systemctl", "reboot"]
   '';
   ```

2. **Wallpaper Resolution System** (based on wimpysworld pattern):
   ```nix
   wallpaperResolutions = {
     "1920x1080" = "fhd";
     "2560x1440" = "wqhd";
     "3440x1440" = "uwqhd";
     "3840x2160" = "uhd";
     default = "fhd";
   };

   # Detect resolution via just recipes, store in config.toml
   detectedResolution = noughtyConfig.display.resolution or "1920x1080";
   ```

3. **Branding Assets**:
   ```nix
   environment.etc = {
     "backgrounds/noughty-mocha.png".source = ./assets/wallpapers/noughty-mocha.png;
     "backgrounds/noughty-macchiato.png".source = ./assets/wallpapers/noughty-macchiato.png;
     "backgrounds/noughty-frappe.png".source = ./assets/wallpapers/noughty-frappe.png;
     "backgrounds/noughty-latte.png".source = ./assets/wallpapers/noughty-latte.png;
   };
   ```

#### **Phase 4: System Integration & Testing (Week 4)**
**Goals:** Full system integration and robustness
**Deliverables:**
- [ ] Seamless desktop session handoff to Hyprland
- [ ] Comprehensive error handling and recovery
- [ ] Service dependencies and ordering validation
- [ ] Integration testing and documentation

**Key Implementation Tasks:**
1. **Session Handoff Integration**:
   ```nix
   # Session detection script for ReGreet
   sessionScript = pkgs.writeShellScript "detect-sessions" ''
     # Detect available Wayland sessions
     SESSIONS_DIR="/run/current-system/sw/share/wayland-sessions"
     if [ -d "$SESSIONS_DIR" ]; then
       for session in "$SESSIONS_DIR"/*.desktop; do
         [ -f "$session" ] && basename "$session" .desktop
       done
     fi
   '';
   ```

2. **Service Dependency Chain Validation**:
   ```nix
   systemd.services.greetd = {
     # Complete dependency chain
     wants = [
       "systemd-user-sessions.service"
       "systemd-logind.service"
     ];
     after = [
       "systemd-user-sessions.service"
       "getty@tty1.service"
       "systemd-logind.service"
       "plymouth-quit.service"  # If plymouth enabled
       "kmsconvt@tty1.service"  # Must stop kmscon first
     ];
     conflicts = [
       "getty@tty1.service"
       "kmsconvt@tty1.service"
     ];
     before = [ "graphical.target" ];
   };
   ```

3. **Error Recovery and Logging**:
   ```nix
   # Enhanced logging and recovery
   serviceConfig = {
     ExecStart = "${pkgs.greetd.greetd}/bin/greetd --config /etc/greetd/config.toml";
     ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
     Restart = "on-failure";
     RestartSec = "5s";
     StandardOutput = "journal";
     StandardError = "journal";
     SyslogIdentifier = "greetd";
   };
   ```

### **Technical Architecture**

#### **Service Dependency Chain** (Updated based on research)
```
┌─────────────────────────────────────────┐
│ graphical.target                        │
├─────────────────────────────────────────┤
│ greetd.service                          │
│ ├─ aliases: display-manager.service     │
│ ├─ wants: systemd-user-sessions         │
│ ├─ after: systemd-logind               │
│ ├─ conflicts: getty@tty1               │
│ └─ conflicts: kmsconvt@tty1 (existing) │
├─────────────────────────────────────────┤
│ systemd-user-sessions.service           │
│ systemd-logind.service                  │
│ plymouth-quit-wait.service (optional)   │
├─────────────────────────────────────────┤
│ getty@tty1.service (disabled)           │
│ kmsconvt@tty1.service (disabled)        │
└─────────────────────────────────────────┘
```

#### **system-manager Constraints & Solutions**
| **NixOS Feature** | **system-manager Support** | **Workaround** |
|-------------------|----------------------------|----------------|
| `users.users.*` | ❌ Not supported | just recipes user creation |
| `security.pam.services.*` | ⚠️ Limited | Manual PAM config via `environment.etc` |
| `systemd.services.*` | ✅ Full support | Direct implementation |
| `systemd.tmpfiles.*` | ✅ Full support | Directory management |
| `environment.etc.*` | ✅ Full support | Configuration file generation |

#### **PAM Configuration Requirements**
Based on the actual NixOS modules (greetd.nix, cage.nix), the display manager requires specific PAM service configurations:

1. **greetd PAM Service** (from greetd.nix - simplified authentication):
   ```nix
   environment.etc."pam.d/greetd".text = ''
     #%PAM-1.0
     auth       sufficient   pam_unix.so nullok
     auth       required     pam_deny.so
     account    required     pam_unix.so
     session    required     pam_unix.so
     session    optional     pam_env.so conffile=/etc/pam/environment readenv=0
     session    required     pam_systemd.so
     session    optional     pam_gnome_keyring.so auto_start
   '';
   ```

2. **cage PAM Service** (from cage.nix - VT and session management):
   ```nix
   environment.etc."pam.d/cage".text = ''
     #%PAM-1.0
     auth       required     pam_unix.so nullok
     account    required     pam_unix.so
     session    required     pam_unix.so
     session    required     pam_env.so conffile=/etc/pam/environment readenv=0
     session    required     pam_systemd.so
   '';
   ```

**Note**: The NixOS greetd.nix module configures PAM with `allowNullPassword = true` and `startSession = true`, which translates to the above PAM stack. The cage service needs PAM for VT allocation and user session management.

#### **VT1 Management Strategy**
Current Noughty Linux uses `kmsconvt@tty1.service` for console login. Display manager implementation requires:

1. **Conflict Resolution**:
   ```nix
   systemd.services.greetd.conflicts = [
     "getty@tty1.service"
     "kmsconvt@tty1.service"  # Existing Noughty service
   ];
   ```

2. **Conditional Activation** (via config.toml):
   ```toml
   [desktop]
   display-manager = true  # Disables kmscon, enables greetd
   ```

3. **justfile Integration**:
   ```bash
   # In just/system-manager.just
   switch-display-manager:
     systemctl disable --now kmsconvt@tty1.service || true
     system-manager switch --flake .
     systemctl enable --now greetd.service
   ```

#### **Configuration File Structure** (Enhanced)
```
/etc/greetd/
├── config.toml          # Main greetd configuration (generated from noughtyConfig)
├── regreet.toml         # ReGreet appearance settings (template-based)
├── regreet.css          # Custom CSS overrides
├── sessions/            # Available session files
│   ├── hyprland.desktop
│   └── emergency.desktop
└── scripts/
    └── regreet-cage     # Custom cage wrapper with display management

/etc/noughty-linux/
├── config.toml          # User configuration (existing)
└── display-profiles/    # Display configuration templates
    ├── single.kanshi    # Single display profile
    └── multi.kanshi     # Multi-display profile

/var/lib/regreet/        # ReGreet data directory (>= v0.2.0)
├── cache/               # Session cache
└── state/               # Persistent state

/var/log/regreet/        # ReGreet log directory
└── regreet.log          # Application logs
```

#### **User Session Flow** (Enhanced with error handling)
```
just Recipe Phase:
├── User creation (greeter user/group)
├── PAM configuration setup (greetd, cage, regreet services)
└── Service conflict resolution (kmscon vs greetd)

Runtime Flow:
greetd daemon → Environment preparation →
Cage compositor (with display config) →
ReGreet greeter (themed) → User authentication →
Session selection → Cleanup & handoff →
Hyprland desktop (via home-manager)

Error Recovery:
├── Service restart on failure
├── Fallback to emergency session
└── Log aggregation for debugging
```

#### **Integration Points with Existing Noughty Linux**
1. **TOML Configuration Extension**:
   ```toml
   [desktop]
   display-manager = true           # Enable greetd, disable kmscon
   terminal-fallback = false        # Keep kmscon available as fallback

   [display]
   resolution = "1920x1080"         # Auto-detected by just recipes
   primary-output = "DP-1"          # Optional display configuration

   [greeter]
   show-hostname = true             # Personalization options
   timeout-seconds = 30             # Auto-login timeout (if enabled)
   ```

2. **justfile Integration**:
   ```bash
   # New commands for display manager management
   enable-graphical: _header _is_compatible
       @echo "Enabling graphical display manager..."
       @just switch-display-manager

   disable-graphical: _header _is_compatible
       @echo "Falling back to console login..."
       @systemctl disable --now greetd.service
       @systemctl enable --now kmsconvt@tty1.service
   ```

### **Research Checklist**

#### **NixOS Module Analysis**
- [ ] Extract systemd service configuration patterns from `greetd.nix`
- [ ] Identify user management requirements and PAM integration
- [ ] Document service dependencies and ordering requirements
- [ ] Analyse configuration file generation and templating
- [ ] Study session enumeration and launch mechanisms

#### **system-manager Capabilities Assessment**
- [ ] Document exactly what systemd primitives are available
- [ ] Test configuration file generation in etc
- [ ] Verify user/group management capabilities
- [ ] Confirm package installation mechanisms
- [ ] Test service enablement and dependency handling

#### **Integration Requirements**
- [ ] Map existing kmscon VT allocation to greetd requirements
- [ ] Verify Hyprland session detection and launch
- [ ] Test Catppuccin theming consistency
- [ ] Document TOML configuration integration points

### **Risk Mitigation**

#### **High-Risk Areas**
1. **VT Management**: Conflict with existing kmscon setup
   - **Mitigation**: Conditional service enablement via config.toml flag
   - **Testing**: Automated service conflict detection in just recipes
   - **Fallback**: Manual kmscon restoration command

2. **Session Handoff**: Complex transition from greeter to desktop
   - **Mitigation**: Use proven wimpysworld patterns with session wrapper
   - **Testing**: Session enumeration validation and cleanup testing
   - **Fallback**: Emergency console session always available

3. **systemd Dependencies**: Manual service ordering without NixOS abstractions
   - **Mitigation**: Explicit dependency mapping based on greetd.nix analysis
   - **Testing**: Dependency validation in CI/testing framework
   - **Fallback**: Service restart policies with exponential backoff

4. **system-manager Limitations**: Limited user/PAM management capabilities
   - **Mitigation**: just recipes handle user creation and PAM setup
   - **Testing**: Validate user creation and PAM authentication in test environment
   - **Fallback**: Manual user creation documentation and recovery procedures

#### **Implementation Risks**
| **Risk** | **Impact** | **Probability** | **Mitigation Strategy** |
|----------|------------|-----------------|-------------------------|
| User creation failure | High | Low | just recipes validation + manual fallback |
| PAM misconfiguration | High | Medium | Template-based config + testing matrix |
| Display detection failure | Medium | Medium | Fallback to safe defaults + manual override |
| Theme asset missing | Low | Low | Bundled assets + graceful degradation |
| Session launch failure | High | Low | Emergency session + comprehensive logging |

#### **Testing Strategy**
1. **Isolation Testing**: Each phase tested independently in containers
2. **Integration Testing**: Full system testing on Ubuntu Server VMs
3. **Compatibility Testing**: Multiple Ubuntu versions and hardware configurations
4. **Regression Testing**: Ensure existing Noughty functionality preserved

### **Collaboration Workflow**

#### **AI Engineer Responsibilities**
- **NixOS Module Analysis**: Extract patterns from greetd.nix, cage.nix, regreet.nix
- **system-manager Translation**: Adapt NixOS configurations to system-manager constraints
- **Configuration Templating**: Dynamic TOML-driven configuration generation
- **Service Dependency Mapping**: Ensure correct systemd service ordering and conflicts
- **Integration Code**: just recipes enhancements and automation
- **Error Handling**: Comprehensive logging and recovery mechanisms

#### **Human Engineer Responsibilities**
- **Hardware Testing**: Real Ubuntu system integration and display management
- **Theme Customization**: Noughty Linux branding and Catppuccin integration
- **User Experience Validation**: Login flow testing and refinement
- **Documentation**: User-facing guides and troubleshooting procedures
- **Configuration Validation**: Real-world config.toml testing and edge cases

#### **Shared Activities**
- **Architecture Review**: Technical decision validation and constraint analysis
- **Service Integration**: Collaborative debugging of systemd service interactions
- **Performance Testing**: Boot time analysis and optimization
- **Security Validation**: PAM configuration and authentication flow verification

#### **Implementation Reference Sources**
Based on research analysis, key reference implementations:
- **greetd.nix**: `/nixos/modules/services/display-managers/greetd.nix` (nixos-25.05)
- **cage.nix**: `/nixos/modules/services/wayland/cage.nix` (nixos-25.05)
- **regreet.nix**: `/nixos/modules/programs/regreet.nix` (nixos-25.05)
- **wimpysworld config**: `nixos/_mixins/desktop/greeters/greetd.nix` (proven working setup)
- **system-manager docs**: numtide/system-manager README and module capabilities

### **Success Criteria**
1. **Functional**: Boot directly to themed login screen
2. **Visual**: Consistent Catppuccin theming throughout login flow
3. **Seamless**: Smooth transition from login to desktop session
4. **Robust**: Proper error handling and recovery mechanisms
5. **Integrated**: Configuration driven by existing TOML system
6. **Maintainable**: Clear service definitions and debugging capabilities


# Appendix A - Martin's Working NixOS Configuration

These are the actual configuration files from Martin's working NixOS workstation. This demonstrates the difference between the NixOS module default approach and a production setup with advanced display management.

**Key Differences from Standard NixOS Modules:**
- Uses custom `regreet-cage` wrapper script (not direct command)
- Includes kanshi integration for multi-monitor management
- Provides cleanup handling and error recovery
- Optimised for screencasting and virtual display scenarios

## /etc/systemd/system/greetd.service

```ini
[Unit]
After=systemd-user-sessions.service
After=getty@tty1.service
After=plymouth-quit-wait.service
Conflicts=getty@tty1.service
Wants=systemd-user-sessions.service

[Service]
Environment="LOCALE_ARCHIVE=/nix/store/csbxgi9rywzzix0a70ib1psxbgjc93xk-glibc-locales-2.40-66/lib/locale/locale-archive"
Environment="PATH=/nix/store/rry6qingvsrqmc7ll7jgaqpybcbdgf5v-coreutils-9.7/bin:/nix/store/392hs9nhm6wfw4imjllbvb1wil1n39qx-findutils-4.10.0/bin:/nix/store/l2wvwyg680h0v2la18hz3yiznxy2naqw-gnugrep-3.11/bin:/nix/store/4rpiqv9yr2pw5094v4wc33ijkqjpm9sa-gnused-4.9/bin:/nix/store/iq67az90s1wh3962rnja9cpvnzfh8kpg-systemd-257.8/bin:/nix/store/rry6qingvsrqmc7ll7jgaqpybcbdgf5v-coreutils-9.7/sbin:/nix/store/392hs9nhm6wfw4imjllbvb1wil1n39qx-findutils-4.10.0/sbin:/nix/store/l2wvwyg680h0v2la18hz3yiznxy2naqw-gnugrep-3.11/sbin:/nix/store/4rpiqv9yr2pw5094v4wc33ijkqjpm9sa-gnused-4.9/sbin:/nix/store/iq67az90s1wh3962rnja9cpvnzfh8kpg-systemd-257.8/sbin"
Environment="TZDIR=/nix/store/f7yb9lhi1z8dk4x8gy3c5xf3gvn3yi1s-tzdata-2025b/share/zoneinfo"
X-RestartIfChanged=false
ExecStart=/nix/store/1wch7q57cqshxrcn4rnxvahmvvf93sx0-greetd-0.10.3/bin/greetd --config /nix/store/wwmkllffvqcafhp3q3b6nyar48a8aygs-greetd.toml
IgnoreSIGPIPE=false
KeyringMode=shared
Restart=on-success
SendSIGHUP=true
TimeoutStopSec=30s
Type=idle

[Install]
WantedBy=graphical.target
```

## /nix/store/wwmkllffvqcafhp3q3b6nyar48a8aygs-greetd.toml

```ini
[default_session]
# Note: This uses the custom wrapper script, not the NixOS module default
# NixOS module default would be: dbus-run-session cage -s -- regreet
command = "regreet-cage"
user = "greeter"

[terminal]
vt = 1
```

## Custom regreet-cage wrapper script
## Custom regreet-cage wrapper script

```bash
#!/nix/store/cfqbabpc7xwg8akbcchqbq3cai6qq2vs-bash-5.2p37/bin/bash
# Start regreet in a Wayland kiosk using Cage
function cleanup() {
  /nix/store/nrf3s22si6zz58ksjnsrv480hjfjc2pc-procps-4.0.4/bin/pkill kanshi || true
}
trap cleanup EXIT

# If there is a kanshi profile for regreet, use it.
KANSHI_REGREET="$(/nix/store/ckm8z4gmsic83qvj1xgfmacvcasy6s1p-uutils-coreutils-0.0.30/bin/head --lines 1 --quiet /etc/kanshi/regreet 2>/dev/null | /nix/store/4rpiqv9yr2pw5094v4wc33ijkqjpm9sa-gnused-4.9/bin/sed 's/ //g')"
if [ -n "$KANSHI_REGREET" ]; then
  /nix/store/wc0jchq0s8lpp2cgq39075s607pf8b6r-cage-0.2.0/bin/cage -m last -s -- sh -c \
    '/nix/store/m9qkmqcrqfvfgcnk8fb5hpp7ss8q68yb-kanshi-1.7.0/bin/kanshi --config /etc/kanshi/regreet & \
     /nix/store/lf45c6jiyppjl4y4rwai4w344yg55mlw-regreet-0.2.0/bin/regreet'
else
  /nix/store/wc0jchq0s8lpp2cgq39075s607pf8b6r-cage-0.2.0/bin/cage -m last -s /nix/store/lf45c6jiyppjl4y4rwai4w344yg55mlw-regreet-0.2.0/bin/regreet
fi
```

## /etc/kanshi/regreet
```
profile {
  output DP-3 disable
  output DP-2 disable
  output DP-1 enable mode 2560x2880@60Hz position 0,0 scale 1
}
```

## /etc/greetd/regreet.toml

```toml
[GTK]
application_prefer_dark_theme = true
cursor_theme_name = "catppuccin-mocha-blue-cursors"
font_name = "Work Sans 16"
icon_theme_name = "Papirus-Dark"
theme_name = "catppuccin-mocha-blue-standard"

[appearance]
greeting_msg = "May Vader serve you well"

[background]
fit = "Cover"
path = "/etc/backgrounds/Catppuccin-2560x2880.png"

[commands]
poweroff = ["/run/current-system/sw/bin/systemctl", "poweroff"]
reboot = ["/run/current-system/sw/bin/systemctl", "reboot"]
```

# Appendix B - Nixpkgs modules

Here are direct links to the raw Nixpkgs modules for greetd, cage, and regreet

- https://raw.githubusercontent.com/NixOS/nixpkgs/refs/heads/nixos-25.05/nixos/modules/services/display-managers/greetd.nix
- https://raw.githubusercontent.com/NixOS/nixpkgs/refs/heads/nixos-25.05/nixos/modules/programs/regreet.nix
- https://raw.githubusercontent.com/NixOS/nixpkgs/refs/heads/nixos-25.05/nixos/modules/services/wayland/cage.nix
