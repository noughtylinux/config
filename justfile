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

# Run both flake and config checks
check:
    @just check-config
    @just check-flake
