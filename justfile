# Noughty Linux justfile

# Colours
BLACK := '\033[30m'
RED := '\033[31m'
GREEN := '\033[32m'
YELLOW := '\033[33m'
BLUE := '\033[34m'
MAGENTA := '\033[35m'
CYAN := '\033[36m'
WHITE := '\033[37m'

# Formatting
RESET := '\033[0m'
BOLD := '\033[1m'
DIM := '\033[2m'
ITALIC := '\033[3m'
UNDERLINE := '\033[4m'
BLINK := '\033[5m'
REVERSE := '\033[7m'
HIDDEN := '\033[8m'
STRIKETHROUGH := '\033[9m'

# Status messages
ERROR := RED + '🗵 ' + UNDERLINE + DIM + 'ERROR' + RESET + BOLD + ': ' + RESET
WARNING := YELLOW + '🛆 ' + DIM + 'WARNING' + RESET + BOLD + ': ' + RESET
SUCCESS := GREEN + '🗹 ' + DIM + 'SUCCESS' + RESET + BOLD + ': ' + RESET

# Glyphs
GLYPH_CANCEL := MAGENTA + '⊘ ' + RESET
GLYPH_CONFIG := BLUE + '✦ ' + RESET
GLYPH_FLAKE := BLUE + '❆ ' + RESET
GLYPH_HOME := BLUE + '≋ ' + RESET
GLYPH_LOGO := CYAN + '🄍 ' + RESET
GLYPH_NET := BLUE + '🖧 ' + RESET
GLYPH_SHELL := BLUE + '﹩ ' + RESET
GLYPH_SYSTEM := BLUE + '▣ ' + RESET
GLYPH_TRANSFER := BLUE + '➲ ' + RESET
GLYPH_UPDATE := BLUE + '⇩ ' + RESET
GLYPH_USER := BLUE + '☻ ' + RESET

# Constants
NIX_OPTS := "--no-update-lock-file --impure"
STAMP := `date +%Y%m%d-%H%M`
VERSION := "0.0.0"

# List recipes
list: _header
    @just --list --unsorted

# Update configuration repository
update: _header _is_compatible
    @echo -e "{{GLYPH_UPDATE}}Updating configuration repository..."
    @git pull --rebase
    @echo -e "{{SUCCESS}}Update complete!"

# Run flake checks
check: _header
    @echo -e "{{GLYPH_FLAKE}}Running flake checks..."
    @nix flake check --log-format internal-json -v --all-systems {{NIX_OPTS}} |& nom --json
    @nix flake show --all-systems {{NIX_OPTS}}

# Enter the development environment
develop: _header _is_compatible
    @nom develop {{NIX_OPTS}}

# Build home-manager configuration
build-home: _header _is_compatible _has_config
    #!/usr/bin/env bash
    echo -e "{{GLYPH_HOME}}Building {{BOLD}}home-manager{{RESET}} configuration..."
    # Set HOSTNAME and USER if not already set
    export HOSTNAME="${HOSTNAME:-$(tq -f config.toml system.hostname)}"
    export USER="${USER:-$(tq -f config.toml user.name)}"
    nom build {{NIX_OPTS}} ".#homeConfigurations.${USER}@${HOSTNAME}.activationPackage"

# Switch to home-manager configuration
switch-home: _header _is_compatible _has_config
    #!/usr/bin/env bash
    echo -e "{{GLYPH_HOME}}Switching to new {{BOLD}}home-manager{{RESET}} configuration..."
    # Set HOSTNAME and USER if not already set
    export HOSTNAME="${HOSTNAME:-$(tq -f config.toml system.hostname)}"
    export USER="${USER:-$(tq -f config.toml user.name)}"
    home-manager --impure -b noughty-{{STAMP}} --flake ".#${USER}@${HOSTNAME}" switch


# Build system-manager configuration
build-system: _header _is_compatible _has_config
    @echo -e "{{GLYPH_SYSTEM}}Building {{BOLD}}system-manager{{RESET}} configuration..."
    @nom build {{NIX_OPTS}} ".#systemConfigs.default"

# Switch to system-manager configuration
switch-system: _header _is_compatible _has_config
    @echo -e "{{GLYPH_SYSTEM}}Switching to new {{BOLD}}system-manager{{RESET}} configuration..."
    @sudo env PATH="${PATH}" system-manager switch --flake '.#default' --nix-option pure-eval false

# Build home and system configurations
build: build-home build-system

# Switch to new home and system configurations
switch: switch-home switch-system

# Generate config.toml from config.toml.in template
generate-config: _header _is_compatible
    #!/usr/bin/env bash
    set -euo pipefail
    echo -e "{{GLYPH_CONFIG}}Generating {{DIM}}config.toml{{RESET}} from template..."

    # Check if config.toml.in exists
    if [[ ! -f "config.toml.in" ]]; then
        echo -e "{{ERROR}}config.toml.in template not found!"
        exit 1
    fi

    # Safety check: prompt if config.toml already exists
    if [[ -f "config.toml" ]]; then
        echo -e "{{WARNING}}{{DIM}}config.toml{{RESET}} already exists!"
        echo -en "{{YELLOW}}{{BOLD}}⬢ {{RESET}}{{YELLOW}}{{DIM}}Overwrite your existing configuration? {{RESET}}"
        read -p "[N/y]: " -r
        if [[ ! ${REPLY} =~ ^[Yy]$ ]]; then
            echo -e "{{GLYPH_CANCEL}}Aborting. No changes made."
            exit 0
        fi
    fi

    # Generate config.toml by replacing placeholders
    cp config.toml.in config.toml
    sd '@@HOSTNAME@@' "$(hostname -s)" config.toml
    sd '@@USER@@' "${USER}" config.toml
    echo -e "{{SUCCESS}}{{DIM}}config.toml{{RESET}} generated!"

# Display config.toml status
status: _header _is_compatible _has_config
    @echo -e "{{GLYPH_SYSTEM}}Hostname:\t{{DIM}}$(tq -f config.toml system.hostname){{RESET}}"
    @echo -e "{{GLYPH_USER}}User:\t\t{{DIM}}$(tq -f config.toml user.name){{RESET}}"
    @echo -e "{{GLYPH_HOME}}Home:\t\t{{DIM}}/home/$(tq -f config.toml user.name){{RESET}}"

# Remove unwanted Ubuntu packages based on config.toml
cleanse: _header _is_compatible _has_config
    #!/usr/bin/env bash
    set -euo pipefail

    # Array to collect packages to remove
    PACKAGES_TO_REMOVE=()

    # Check ubuntu configuration section
    if tq -f config.toml ubuntu >/dev/null 2>&1; then
        # Check each package option
        if [[ "$(tq -f config.toml ubuntu.remove.snapd 2>/dev/null || echo 'false')" == "true" ]]; then
            PACKAGES_TO_REMOVE+=("snapd")
        fi

        if [[ "$(tq -f config.toml ubuntu.remove.apport 2>/dev/null || echo 'false')" == "true" ]]; then
            PACKAGES_TO_REMOVE+=("apport")
        fi

        if [[ "$(tq -f config.toml ubuntu.remove.pollinate 2>/dev/null || echo 'false')" == "true" ]]; then
            PACKAGES_TO_REMOVE+=("pollinate")
        fi

        if [[ "$(tq -f config.toml ubuntu.remove.unattended-upgrades 2>/dev/null || echo 'false')" == "true" ]]; then
            PACKAGES_TO_REMOVE+=("unattended-upgrades")
        fi
    else
        echo -e "{{WARNING}}No {{DIM}}[ubuntu]{{RESET}} section found in config.toml - no packages will be removed."
        exit 0
    fi

    # Remove packages if any are configured for removal
    if [[ ${#PACKAGES_TO_REMOVE[@]} -gt 0 ]]; then
        echo -e "{{GLYPH_CANCEL}}Removing unwanted Ubuntu packages..."
        echo -e "{{YELLOW}}{{DIM}}Packages to remove: ${PACKAGES_TO_REMOVE[*]}{{RESET}}"
        sudo apt-get update
        sudo apt-get -y remove --purge "${PACKAGES_TO_REMOVE[@]}"
        sudo apt-get -y autoremove --purge
        sudo apt-get -y autoclean
        # If snapd was removed, also remove snap directories
        if [[ " ${PACKAGES_TO_REMOVE[*]} " == *" snapd "* ]]; then
            sudo rm -rf \
                /snap \
                /usr/lib/snapd \
                /var/snap \
                /var/lib/snapd
        fi
        echo -e "{{SUCCESS}}Successfully removed ${#PACKAGES_TO_REMOVE[@]} packages!"
    fi

# Transfer Noughty Linux configuration to remote Ubuntu host
transfer host path="~/NoughtyLinux": _header
    #!/usr/bin/env bash
    set -euo pipefail
    echo -e "{{GLYPH_UPDATE}}Copying project to {{BOLD}}{{host}}:{{path}}{{RESET}}..."

    # Create temporary archive excluding sensitive files
    TEMP_ARCHIVE=$(mktemp /tmp/noughty-linux.XXXXXX.tar.gz)
    trap "rm -f ${TEMP_ARCHIVE}" EXIT

    # Create archive using git (respects .gitignore automatically)
    git archive --format=tar.gz HEAD > "${TEMP_ARCHIVE}"

    # Copy archive to remote host
    scp "${TEMP_ARCHIVE}" "{{host}}:/tmp/noughty-linux-payload.tar.gz"

    # Extract on remote host
    ssh "{{host}}" "mkdir -p {{path}} && cd {{path}} && tar -xzf /tmp/noughty-linux-payload.tar.gz && rm -f /tmp/noughty-linux-payload.tar.gz"

    echo -e "{{SUCCESS}}Project deployed to {{BOLD}}{{host}}:{{path}}{{RESET}}!"

# Bootstrap Noughty Linux on remote Ubuntu host via SSH
bootstrap host: _header
    #!/usr/bin/env bash
    set -euo pipefail
    echo -e "{{GLYPH_SYSTEM}}Bootstrapping Noughty Linux on {{BOLD}}{{host}}{{RESET}}..."

    # Check if bootstrap script exists
    if [[ ! -f "../bootstrap/bootstrap.sh" ]]; then
        echo -e "{{ERROR}}Bootstrap script not found at ../bootstrap/bootstrap.sh"
        exit 1
    fi

    just transfer {{host}}

    # Transfer bootstrap script to remote host
    echo -e "{{GLYPH_TRANSFER}}Transferring bootstrap script..."
    scp "../bootstrap/bootstrap.sh" "{{host}}:/tmp/noughty-bootstrap.sh"

    # Make bootstrap script executable and run it
    echo -e "{{GLYPH_SYSTEM}}Executing bootstrap on remote host..."
    if ! ssh -t "{{host}}" "chmod +x /tmp/noughty-bootstrap.sh && /tmp/noughty-bootstrap.sh"; then
        echo ""
        echo -e "{{ERROR}}Bootstrap failed on remote host."
        echo "Check the output above for specific error details."
        echo ""
        # Clean up bootstrap script even on failure
        ssh "{{host}}" "rm -f /tmp/noughty-bootstrap.sh" 2>/dev/null || true
        exit 1
    fi

    # Clean up bootstrap script
    ssh "{{host}}" "rm -f /tmp/noughty-bootstrap.sh"

    echo -e "{{SUCCESS}}Bootstrap completed on {{BOLD}}{{host}}{{RESET}}!"
    echo -e "{{GLYPH_HOME}}You can now SSH to {{BOLD}}{{host}}{{RESET}} and run {{DIM}}just{{RESET}} commands."

[private]
_header:
    @echo -e "{{GLYPH_LOGO}}{{BOLD}}{{UNDERLINE}}Noughty Linux - {{RESET}}{{UNDERLINE}}v{{VERSION}}{{RESET}}"

# Check if running as root or with sudo
[private]
_is_compatible:
    #!/usr/bin/env bash
    set -euo pipefail

    # Check if running as root (UID 0)
    if [[ "${EUID:-$(id -u)}" -eq 1 ]]; then
        echo -e "{{ERROR}}{{BOLD}}{{UNDERLINE}}Do not{{RESET}} run this command as {{DIM}}root{{RESET}}!"
        exit 1
    fi

    # Check if sudo was used (SUDO_USER environment variable exists)
    if [[ -n "${SUDO_USER:-}" ]]; then
        echo -e "{{ERROR}}{{BOLD}}{{UNDERLINE}}Do not{{RESET}} run this command with {{DIM}}sudo{{RESET}}!"
        exit 1
    fi

    # Check if /etc/os-release exists
    if [[ ! -f "/etc/os-release" ]]; then
        echo -e "{{ERROR}}{{DIM}}/etc/os-release{{RESET}} not found!"
        exit 1
    fi

    # Source the os-release file to get variables
    source /etc/os-release

    # Check if this is Ubuntu
    if [[ "${ID:-}" != "ubuntu" ]]; then
        echo -e "{{ERROR}}${NAME:-unknown} ${VERSION_ID:-unknown} is not supported! {{BOLD}}Only Ubuntu is supported.{{RESET}}"
        exit 1
    fi

    # Check for supported Ubuntu versions
    case "${VERSION_ID:-}" in
        "24.04"|"25.04")
            echo -e "{{SUCCESS}}${NAME} ${VERSION_ID} is supported!"
            ;;
        *)
            echo -e "{{ERROR}}${NAME:-unknown} ${VERSION_ID:-unknown} is not supported! {{BOLD}}Only Ubuntu 24.04 and 25.04 are supported.{{RESET}}"
            exit 1
            ;;
    esac

    # Check architecture is x86_64 or aarch64
    if uname -m | grep -vqE '^(x86_64|aarch64)$'; then
        echo -e "{{ERROR}}Unsupported architecture {{DIM}}$(uname -m){{RESET}}! {{BOLD}}Only x86_64 and aarch64 are supported.{{RESET}}"
        exit 1
    fi

# Check if config.toml exists and is valid
[private]
_has_config:
    #!/usr/bin/env bash
    set -euo pipefail

    if [[ ! -f "config.toml" ]]; then
        echo -e "{{ERROR}}{{DIM}}config.toml{{RESET}} not found! Please run: {{BOLD}}just generate-config{{RESET}}."
        exit 1
    fi

    # Extract values from config.toml
    CONFIG_HOSTNAME=$(tq -f config.toml system.hostname)
    CONFIG_USER=$(tq -f config.toml user.name)
    CONFIG_HOME="/home/$(tq -f config.toml user.name)"

    # Check if hostname matches $(hostname -s)
    if [[ "${CONFIG_HOSTNAME}" != "$(hostname -s)" ]]; then
        echo -e "{{ERROR}}{{DIM}}config.toml{{RESET}} system.hostname '${CONFIG_HOSTNAME}' {{UNDERLINE}}does not match{{RESET}} \$(hostname -s) '$(hostname -s)'"
        exit 1
    fi

    # Check if username matches $USER
    if [[ "${CONFIG_USER}" != "${USER}" ]]; then
        echo -e "{{ERROR}}{{DIM}}config.toml{{RESET}} user.name '${CONFIG_USER}' {{UNDERLINE}}does not match{{RESET}} \$USER '${USER}'"
        exit 1
    fi

    # Check if home_directory path exists
    if [[ ! -d "${CONFIG_HOME}" ]]; then
        echo -e "{{ERROR}}{{BOLD}}${CONFIG_HOME}{{DIM}} does not exist"
        exit 1
    fi
