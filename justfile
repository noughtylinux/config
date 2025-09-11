# Noughty Linux justfile

# List recipes
list:
    @just --list --unsorted

# Enter the development environment
develop:
    @nix develop --no-update-lock-file

# Run flake checks
check-flake:
    @nix flake check --all-systems

# Check config.toml exists and validate contents
check-config:
    #!/usr/bin/env bash
    set -euo pipefail

    # Check if config.toml exists
    if [[ ! -f "config.toml" ]]; then
        echo "⨯ ERROR: config.toml not found!"
        exit 1
    fi

    # Extract values from config.toml
    CONFIG_USER=$(tq -f config.toml user.name )
    CONFIG_HOME=$(tq -f config.toml user.home)

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
    echo "🗸 SUCCESS: config.toml checks passed!"

# Check operating system is supported Ubuntu version
check-os:
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

# Run all checks: OS, config, and flake
check:
    @just check-config
    @just check-os
    @just check-flake
