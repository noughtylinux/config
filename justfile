# Nøughty Linux recipes
import "just/constants.just"
import "just/home-manager.just"
import "just/private.just"
import "just/system-manager.just"
import "just/ubuntu.just"

# List recipes
list: _header
    @just --list

# Update configuration
update: _header _is_compatible
    @echo -e "{{GLYPH_UPDATE}}Updating configuration repository..."
    @git pull --rebase
    @echo -e "{{SUCCESS}}Update complete!"

# Check flake integrity
check: _header
    @echo -e "{{GLYPH_FLAKE}}Running flake checks..."
    @nix flake check --log-format internal-json -v --all-systems {{NIX_OPTS}} |& nom --json
    @nix flake show --all-systems {{NIX_OPTS}}

# Build configuration
build: build-system build-home

# Switch to new configuration
switch: ubuntu-pre switch-system switch-home ubuntu-post

# Generate config.toml
generate: _header _is_compatible
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

# Show configuration summary
show: _header _is_compatible _has_config
    @echo -e "{{GLYPH_SYSTEM}}Hostname:\t{{DIM}}$(tq -f config.toml system.hostname){{RESET}}"
    @echo -e "{{GLYPH_USER}}User:\t\t{{DIM}}$(tq -f config.toml user.name){{RESET}}"
    @echo -e "{{GLYPH_HOME}}Home:\t\t{{DIM}}/home/$(tq -f config.toml user.name){{RESET}}"

# Create a tarball of the configuration
tarball filename=("noughty-linux-" + VERSION + ".tar.gz"): _has_git
    @echo -e "{{GLYPH_TARBALL}}Creating tarball of the configuration..."
    @git archive --format=tar.gz HEAD > "{{filename}}"
    @echo -e "{{SUCCESS}}Tarball created at {{DIM}}{{filename}}{{RESET}}!"

# Transfer configuration to remote Ubuntu host via SSH
transfer host path="~/NoughtyLinux": _header _has_git
    #!/usr/bin/env bash
    set -euo pipefail

    just tarball noughty-linux-payload.tar.gz

    echo -e "{{GLYPH_UPDATE}}Copying configuration to {{BOLD}}{{host}}:{{path}}{{RESET}}..."

    # Copy archive to remote host
    scp "noughty-linux-payload.tar.gz" "{{host}}:/tmp/noughty-linux-payload.tar.gz"
    rm -f "noughty-linux-payload.tar.gz"

    # Extract on remote host
    ssh "{{host}}" "
        rm -f {{path}}/result 2>/dev/null || true &&
        # Backup config.toml
        if [[ -f {{path}}/config.toml ]]; then
            cp {{path}}/config.toml /tmp/config.toml
        fi &&

        # Extract payload
        mkdir -p {{path}} &&
        cd {{path}} &&
        tar -xzf /tmp/noughty-linux-payload.tar.gz &&
        rm -f /tmp/noughty-linux-payload.tar.gz &&

        # Restore config.toml
        if [[ -f /tmp/config.toml ]]; then
            mv /tmp/config.toml config.toml
        fi
    "
    echo -e "{{SUCCESS}}Configuration transferred to {{BOLD}}{{host}}:{{path}}{{RESET}}!"

# Bootstrap a remote Ubuntu host via SSH
bootstrap host: _header _has_git
    #!/usr/bin/env bash
    set -euo pipefail
    echo -e "{{GLYPH_SYSTEM}}Bootstrapping Nøughty Linux on {{BOLD}}{{host}}{{RESET}}..."

    # Check if bootstrap script exists
    if [[ ! -f "bootstrap.sh" ]]; then
        echo -e "{{ERROR}}Bootstrap script not found at bootstrap.sh"
        exit 1
    fi

    just transfer {{host}}

    # Transfer bootstrap script to remote host
    echo -e "{{GLYPH_TRANSFER}}Transferring bootstrap script..."
    scp "bootstrap.sh" "{{host}}:/tmp/noughty-bootstrap.sh"

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
