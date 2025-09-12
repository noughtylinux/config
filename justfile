# Noughty Linux justfile

# List recipes
list:
    @just --list --unsorted

# Update configuration repository
update: _is_root
    #!/usr/bin/env bash
    set -euo pipefail

    echo "🗘 Updating configuration repository..."
    git pull --rebase
    echo "🗸 SUCCESS: Update complete!"

# Enter the development environment
develop: _is_root
    @nix develop --impure --no-update-lock-file

# Generate config.toml from config.toml.in template
generate-config: _is_root
    #!/usr/bin/env bash
    set -euo pipefail

    # Check if config.toml.in exists
    if [[ ! -f "config.toml.in" ]]; then
        echo "⨯ ERROR: config.toml.in template not found!"
        exit 1
    fi

    # Generate config.toml by replacing placeholders
    echo "⊕ Generating config.toml from template..."
    cp config.toml.in config.toml
    sd '@@HOSTNAME@@' "$(hostname -s)" config.toml
    sd '@@USER@@' "${USER}" config.toml
    sd '@@HOME@@' "${HOME}" config.toml

# Run flake checks
check-flake: _is_root
    @nix flake check --impure --all-systems
    @nix flake show --impure

# Build home-manager configuration
build: _is_root
    #!/usr/bin/env bash
    set -euo pipefail

    # Check if config.toml exists first
    if [[ ! -f "config.toml" ]]; then
        echo "⨯ ERROR: config.toml not found!"
        echo "Run 'nix develop' first to generate configuration, then try building again."
        exit 1
    fi

    # Set HOSTNAME if not already set (for NixOS compatibility)
    export HOSTNAME="${HOSTNAME:-$(hostname)}"
    nix build --impure ".#homeConfigurations.x86_64-linux.${USER}@${HOSTNAME}.activationPackage"

# Switch to home-manager configuration
switch: _is_root
    #!/usr/bin/env bash
    set -euo pipefail

    # Check if config.toml exists first
    if [[ ! -f "config.toml" ]]; then
        echo "⨯ ERROR: config.toml not found!"
        echo "Run 'nix develop' first to generate configuration, then try switching again."
        exit 1
    fi

    # Set HOSTNAME if not already set (for NixOS compatibility)
    export HOSTNAME="${HOSTNAME:-$(hostname)}"
    nix run --impure ".#homeConfigurations.x86_64-linux.${USER}@${HOSTNAME}.activationPackage"

# Check config.toml exists and validate contents
check-config: _is_root
    #!/usr/bin/env bash
    set -euo pipefail

    # Check if config.toml exists
    if [[ ! -f "config.toml" ]]; then
        echo "⊖ config.toml not found"
        just generate-config
    fi

    # Extract values from config.toml
    CONFIG_HOSTNAME=$(tq -f config.toml system.hostname)
    CONFIG_USER=$(tq -f config.toml user.name)
    CONFIG_HOME=$(tq -f config.toml user.home)
    CONFIG_SHELL=$(tq -f config.toml terminal.shell)

    # Check if hostname matches $(hostname)
    if [[ "${CONFIG_HOSTNAME}" != "$(hostname)" ]]; then
        echo "⨯ ERROR: config.toml system.hostname '${CONFIG_HOSTNAME}' does not match \$(hostname) '$(hostname)'"
        exit 1
    fi

    # Check if username matches $USER
    if [[ "${CONFIG_USER}" != "${USER}" ]]; then
        echo "⨯ ERROR: config.toml user.name '${CONFIG_USER}' does not match \$USER '${USER}'"
        exit 1
    fi

    # Check if home_directory matches $HOME
    if [[ "${CONFIG_HOME}" != "${HOME}" ]]; then
        echo "⨯ ERROR: config.toml user.home '${CONFIG_HOME}' does not match \$HOME '${HOME}'"
        exit 1
    fi

    # Check if home_directory path exists
    if [[ ! -d "${CONFIG_HOME}" ]]; then
        echo "⨯ ERROR: user.home path '${CONFIG_HOME}' does not exist"
        exit 1
    fi

    echo "🞴 Hostname: ${CONFIG_HOSTNAME}"
    echo "☻ User: ${CONFIG_USER}"
    echo "⌂ Home: ${CONFIG_HOME}"
    echo "𐇣 Shell: ${CONFIG_SHELL}"
    echo ""
    echo "✪ Ready to go!"

# Check operating system is supported Ubuntu version
check-os: _is_root
    #!/usr/bin/env bash
    set -euo pipefail

    # Check if /etc/os-release exists
    if [[ ! -f "/etc/os-release" ]]; then
        echo "⨯ ERROR: /etc/os-release not found!"
        exit 1
    fi

    # Source the os-release file to get variables
    source /etc/os-release

    # Check if this is Ubuntu
    if [[ "${ID:-}" != "ubuntu" ]]; then
        echo "⨯ ERROR: This system is not Ubuntu (detected: ${ID:-unknown})"
        exit 1
    fi

    # Check for supported Ubuntu versions
    case "${VERSION_ID:-}" in
        "24.04"|"25.04")
            echo "🗸 SUCCESS: Ubuntu ${VERSION_ID} is supported!"
            ;;
        *)
            echo "⨯ ERROR: Ubuntu ${VERSION_ID:-unknown} is not supported"
            exit 1
            ;;
    esac

# Run all checks: config, flake, and OS
check:
    @just check-config
    @just check-flake
    @just check-os

# Check if running as root or with sudo
[private]
_is_root:
    #!/usr/bin/env bash
    set -euo pipefail

    # Check if running as root (UID 0)
    if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
        echo "🟖 ERROR: Do not run this command as root!"
        exit 1
    fi

    # Check if sudo was used (SUDO_USER environment variable exists)
    if [[ -n "${SUDO_USER:-}" ]]; then
        echo "🟖 ERROR! Do not run this command with sudo!"
        exit 1
    fi
