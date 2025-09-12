# Noughty Linux justfile

# Color variables
RED := '\033[31m'
GREEN := '\033[32m'
YELLOW := '\033[33m'
RESET := '\033[0m'
ERROR := RED + '🗵 ERROR' + RESET
WARNING := YELLOW + '🛆 WARNING' + RESET
SUCCESS := GREEN + '🗹 SUCCESS' + RESET

# Constants
NIX_OPTS := "--no-update-lock-file --impure"

# List recipes
list:
    @just --list --unsorted

# Update configuration repository
update: _is_compatible
    #!/usr/bin/env bash
    set -euo pipefail

    echo "⟳ Updating configuration repository..."
    git pull --rebase
    echo -e "{{SUCCESS}}: Update complete!"

# Enter the development environment
develop: _is_compatible _has_config
    @nom develop {{NIX_OPTS}}

# Generate config.toml from config.toml.in template
generate-config: _is_compatible
    #!/usr/bin/env bash
    set -euo pipefail

    # Check if config.toml.in exists
    if [[ ! -f "config.toml.in" ]]; then
        echo -e "{{ERROR}}: config.toml.in template not found!"
        exit 1
    fi

    # Safety check: prompt if config.toml already exists
    if [[ -f "config.toml" ]]; then
        echo -e "{{WARNING}}: config.toml already exists!"
        echo "This will overwrite your existing configuration."
        read -p "Continue? [N/y]: " -r
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "⊘ Operation cancelled."
            exit 0
        fi
    fi

    # Generate config.toml by replacing placeholders
    echo "⊕ Generating config.toml from template..."
    cp config.toml.in config.toml
    sd '@@HOSTNAME@@' "$(hostname -s)" config.toml
    sd '@@USER@@' "${USER}" config.toml
    sd '@@HOME@@' "${HOME}" config.toml

# Run flake checks
check-flake: _is_compatible _has_config
    @nom flake check --all-systems {{NIX_OPTS}}
    @nom flake show {{NIX_OPTS}}

# Build home-manager configuration
build: _is_compatible _has_config
    #!/usr/bin/env bash
    set -euo pipefail

    # Set HOSTNAME if not already set
    export HOSTNAME="${HOSTNAME:-$(tq -f config.toml system.hostname)}"
    export USER="${USER:-$(tq -f config.toml user.name)}"
    nom build {{NIX_OPTS}} ".#homeConfigurations.${USER}@${HOSTNAME}.activationPackage"

# Switch to home-manager configuration
switch: _is_compatible _has_config
    #!/usr/bin/env bash
    set -euo pipefail

    # Set HOSTNAME if not already set
    export HOSTNAME="${HOSTNAME:-$(tq -f config.toml system.hostname)}"
    export USER="${USER:-$(tq -f config.toml user.name)}"
    nom run {{NIX_OPTS}} ".#homeConfigurations.${USER}@${HOSTNAME}.activationPackage"

# Check config.toml exists and validate contents
check-config: _is_compatible _has_config
    #!/usr/bin/env bash
    set -euo pipefail

    # Extract values from config.toml
    CONFIG_HOSTNAME=$(tq -f config.toml system.hostname)
    CONFIG_USER=$(tq -f config.toml user.name)
    CONFIG_HOME=$(tq -f config.toml user.home)
    CONFIG_SHELL=$(tq -f config.toml terminal.shell)

    # Check if hostname matches $(hostname)
    if [[ "${CONFIG_HOSTNAME}" != "$(hostname -s)" ]]; then
        echo -e "{{ERROR}}: config.toml system.hostname '${CONFIG_HOSTNAME}' does not match \$(hostname -s) '$(hostname -s)'"
        exit 1
    fi

    # Check if username matches $USER
    if [[ "${CONFIG_USER}" != "${USER}" ]]; then
        echo -e "{{ERROR}}: config.toml user.name '${CONFIG_USER}' does not match \$USER '${USER}'"
        exit 1
    fi

    # Check if home_directory matches $HOME
    if [[ "${CONFIG_HOME}" != "${HOME}" ]]; then
        echo -e "{{ERROR}}: config.toml user.home '${CONFIG_HOME}' does not match \$HOME '${HOME}'"
        exit 1
    fi

    # Check if home_directory path exists
    if [[ ! -d "${CONFIG_HOME}" ]]; then
        echo -e "{{ERROR}}: user.home path '${CONFIG_HOME}' does not exist"
        exit 1
    fi

    echo "▣ Hostname: ${CONFIG_HOSTNAME}"
    echo "☻ User: ${CONFIG_USER}"
    echo "⌂ Home: ${CONFIG_HOME}"
    echo "𐇣 Shell: ${CONFIG_SHELL}"
    echo ""
    echo "🟊 Ready to go!"

# Run all checks: config, flake, and OS
check:
    @just check-config
    @just check-flake

# Check if running as root or with sudo
[private]
_is_compatible:
    #!/usr/bin/env bash
    set -euo pipefail

    # Check if running as root (UID 0)
    if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
        echo -e "{{ERROR}}: Do not run this command as root!"
        exit 1
    fi

    # Check if sudo was used (SUDO_USER environment variable exists)
    if [[ -n "${SUDO_USER:-}" ]]; then
        echo -e "{{ERROR}}! Do not run this command with sudo!"
        exit 1
    fi

    # Check if /etc/os-release exists
    if [[ ! -f "/etc/os-release" ]]; then
        echo -e "{{ERROR}}: /etc/os-release not found!"
        exit 1
    fi

    # Source the os-release file to get variables
    source /etc/os-release

    # Check if this is Ubuntu
    if [[ "${ID:-}" != "ubuntu" ]]; then
        echo -e "{{ERROR}}: This system is not Ubuntu (detected: ${ID:-unknown})"
        if [[ "${ID}" == "nixos" ]] && [[ "${USER}" != "martin" ]]; then
            exit 1
        fi
    fi

    # Check for supported Ubuntu versions
    case "${VERSION_ID:-}" in
        "24.04"|"25.04")
            echo -e "{{SUCCESS}}: ${NAME} ${VERSION_ID} is supported!"
            ;;
        *)
            echo -e "{{ERROR}}: ${NAME:-unknown} ${VERSION_ID:-unknown} is not supported"
            if [[ "${ID}" == "nixos" ]] && [[ "${USER}" != "martin" ]]; then
                exit 1
            fi
            ;;
    esac

[private]
_has_config:
    #!/usr/bin/env bash
    set -euo pipefail

    if [[ ! -f "config.toml" ]]; then
        echo -e "{{ERROR}}: config.toml not found! Please run 'just generate-config' first."
        exit 1
    fi
