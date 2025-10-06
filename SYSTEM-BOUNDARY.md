# System Boundary: Ubuntu + Nix Hybrid Architecture

## Philosophy

This system runs Ubuntu Server (minimal) as a stable foundation, with Nix layered on top for reproducibility where it matters. Think of Ubuntu as the bedrock: boring, reliable, and providing the services that need to work *before* anything else does. Nix handles everything you want to evolve, experiment with, and roll back.

## The Three Layers

```
┌────────────────────────────────────────────────────────────┐
│                        Ubuntu Host                         │
│   The bedrock: services that boot first, serve all users   │
├────────────────────────────────────────────────────────────┤
│ Init & IPC: systemd, dbus, udev, polkitd, systemd-logind   │
│ Network:    avahi, NetworkManager, ModemManager, ssh       │
│ Hardware:   bluez, colord, fprintd, fwupd, irqbalance      │
│ Storage:    smartd, udisks2                                │
│ Audio:      pipewire, rtkit, wireplumber                   │
│ Power:      power-profiles-daemon, thermald, upowerd       │
│ Login:      greetd, kmscon                                 │
│ Services:   cups, geoclue                                  │
└────────────────────────────────────────────────────────────┘
                              ▲
                              │ requires system-level daemon
                              │
                ┌─────────────┴──────────────┐
                │ all via D-Bus system bus   │
┌───────────────▼──────────┐   ┌──────────────▼─────────────┐
│ System-Manager (root)    │   │ Home Manager (per-user)    │
│ System-wide, declarative │   │ User-space, declarative    │
├──────────────────────────┤   ├────────────────────────────┤
│ • /etc files             │   │ • Dot file management      │
│ • systemd services       │   │ • systemd user services    │
│ • Application daemons    │   │ • Polkit auth agents (GUI) │
│ • System packages        │   │ • Terminal environment     │
│ • tmpfiles.d rules       │   │ • Desktop shell & portals  │
└──────────────────────────┘   └────────────────────────────┘
```

## Ubuntu Host: The System Boundary

**Rule:** If it needs to be running *before* a user logs in, it stays in Ubuntu.

### Core Infrastructure
- **dbus, systemd, udev, polkitd, systemd-logind**: The init and IPC layer. Everything else depends on these.

### Hardware Management
- **bluez**: Bluetooth protocol stack. Manages pairing, connections, and device discovery via D-Bus for all users.
- **fwupd**: Firmware updates need direct hardware access and should work regardless of who's logged in.
- **colord**: Color management daemon. Pulled in as a cups dependency, provides D-Bus color calibration services.
- **fprintd**: Fingerprint authentication daemon. Integrates with PAM for biometric login—needs to work at the greeter before any user session exists.
- **irqbalance** - Kernel-level interrupt distribution, affects all processes system-wide.

### Network Stack
- **NetworkManager, ModemManager, avahi**: Networking must work before Nix can fetch anything.
- **sshd**:  OpenSSH server daemon.

### Storage
- **udisks2**: Storage device management daemon. Handles disk mounting, formatting, and SMART data via D-Bus with polkit authorization.
- **smartmontools**: (smartd) - Direct disk access, monitoring should be independent of user sessions.

### Audio Pipeline
- **pipewire, wireplumber, rtkit**: Modern Ubuntu defaults to system-level PipeWire. Keeping it here prevents apt packages from spawning duplicate/competing audio services.

### Power Management
- **upowerd**: Battery and power device monitoring via D-Bus. Laptops need this before login.
- **power-profiles-daemon**: Power profile switching (performance/balanced/power-saver). Integrates with GNOME/KDE but runs system-wide.
- **thermald**: Direct hardware monitoring and thermal control, critical for preventing overheating regardless of who's logged in (Intel only)

### Login & Console
- **greetd**: Display manager service runs as Ubuntu systemd unit, but `cage` (Wayland compositor) and `regreet` (greeter UI) come from Nixpkgs and are configured via system-manager. This hybrid approach keeps the critical boot-to-login path in Ubuntu while allowing declarative greeter configuration.
- **kmscon**: Kernel-mode console as systemd getty replacement. Service managed by Ubuntu systemd, binary from Nixpkgs via system-manager.

### System Services
- **cups**: System-wide printing for all users.
- **geoclue**: - D-Bus location provider, needed before user sessions for system-wide location awareness.

**Why Ubuntu?** These packages are stable, well-tested, and Ubuntu won't surprise you with breaking changes. Security updates are handled by `apt`.

**The Hybrid Pattern:** Notice greetd and kmscon—the systemd service units live in Ubuntu, but the binaries come from Nix. This gives you declarative configuration and up-to-date software while keeping the service lifecycle management in Ubuntu's reliable hands. Best of both worlds.

## System-Manager: Declarative System Config

**Rule:** Use this for system-level services you want to version control and rollback.

System-manager brings NixOS-style declarative configuration to non-NixOS systems. It manages:

- **`environment.etc`**: Configuration files in `/etc/`
- **`systemd.services`**: System-level daemons (anchored to `system-manager.target`)
- **`systemd.tmpfiles`**: Temporary file management
- **`environment.systemPackages`**: System-wide packages

**What goes here:**
- Application services (web servers, databases, custom daemons)
- Configuration files you want in version control
- System packages unavailable or outdated in Ubuntu repos
- Binaries for hybrid services (greetd's cage/regreet, kmscon)

**Limitations:** System-manager doesn't (yet) support systemd timers, sockets, paths, or mounts. For those, you'll need raw systemd units or stay in Ubuntu-land.

## Defensive Package Management

Some packages are installed via apt not because they need to run at the system level,
but to prevent conflicts when other Ubuntu packages expect them as dependencies.

Defensive packaging keeps the apt and Nix ecosystems from colliding while preserving
declarative configuration where it matters.

**The Strategy:**
- Install the package via `apt` to satisfy dependency requirements
- Manage the actual services and configuration declaratively (usually Home Manager)
- Prevent apt and Nix from fighting over the same functionality

**Defensive Installations:**

**mpris-proxy**
- Bridges to MPRIS D-Bus media control interface
- Allows media keys and desktop widgets to control PipeWire audio sources
- Ubuntu packages may expect MPRIS support to be present, so we pre-install via apt and expressly disable via Home Manager.

**wireplumber**
- PipeWire session manager, already in Ubuntu system boundary
- Desktop packages often depend on wireplumber being present
- Installing via apt prevents conflicts with packages that expect PipeWire integration

## Ubuntu User-Space Infrastructure

Some packages provide foundational user-space services that, while running per-user,
are better managed by Ubuntu to prevent conflicts and ensure compatibility:

**gvfs**
- Virtual filesystem backends for file managers
- Installed via apt, GIO modules referenced in Home Manager session variables
- Prevents conflicts when installing GUI apps via apt
- All applications (Nix or apt) use the same gvfs instance

**Why Ubuntu?** These services are fundamental desktop infrastructure. Having a
single, stable source prevents apt and Nix packages from fighting over the same
user-space resources. Your Home Manager configuration still controls which backends
are active via environment variables.

## Home Manager: User-Space Paradise

**Rule:** If it runs as your user, configure it here.

Home Manager excels at:
- **User systemd services**: Things that start with your login session
- **Personal daemons**: Syncthing, gpg-agent, ssh-agent
- **Authentication agents**: Polkit GUI prompts (the user-facing part of polkit)
- **Desktop environment**: Window managers, terminals, editors
- **Development tools**: Language runtimes, build tools, formatters
- **Dotfiles**: Shell configs, git settings, application preferences

**Why this matters:** Your user environment becomes reproducible and portable. Sync your `home.nix` to a new machine, run `home-manager switch`, and you're home.

## Decision Framework

When you encounter a new service, ask:

1. **Does it require root privileges or kernel access?** → Ubuntu
2. **Must it run before users log in?** → Ubuntu
3. **Do apt packages depend on it being system-level?** → Ubuntu
4. **Is it a foundational service (network, audio, bluetooth, power)?** → Ubuntu
5. **Does it operate on user data or in `$HOME`?** → Home Manager
6. **Is it an application daemon you want to version control?** → System-Manager
7. **Everything else?** → Home Manager

**Edge cases:**
- **Syncthing**: *Could* be system-level, but works beautifully per-user
- **PipeWire**: *Can* run per-user on modern distros, but system-level prevents apt conflicts
- **greetd/kmscon**: Hybrid services—Ubuntu manages the systemd unit, Nix provides the binary

## The Win

This architecture gives you:
- **Stability**: Core services from Ubuntu's battle-tested repos
- **Reproducibility**: User space and applications are fully declarative
- **Flexibility**: Hybrid services let you mix Ubuntu reliability with Nix freshness
- **Safety**: Nix experiments won't brick your network, audio, or login
- **Clarity**: No hunting for "which layer provides SSH?"
- **Compatibility**: Apt-installed software just works
