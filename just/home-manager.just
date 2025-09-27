# Build home-manager configuration
[private]
build-home: _header _is_compatible _has_config
    #!/usr/bin/env bash
    echo -e "{{GLYPH_HOME}}Building {{BOLD}}home-manager{{RESET}} configuration..."
    # Set HOSTNAME and USER if not already set
    export HOSTNAME="${HOSTNAME:-$(tq -f config.toml system.hostname)}"
    export USER="${USER:-$(tq -f config.toml user.name)}"
    nom build {{NIX_OPTS}} ".#homeConfigurations.${USER}@${HOSTNAME}.activationPackage"
    rm result 2> /dev/null || true

# Switch to home-manager configuration
[private]
switch-home: build-home
    #!/usr/bin/env bash
    echo -e "{{GLYPH_HOME}}Switching to new {{BOLD}}home-manager{{RESET}} configuration..."
    # Set HOSTNAME and USER if not already set
    export HOSTNAME="${HOSTNAME:-$(tq -f config.toml system.hostname)}"
    export USER="${USER:-$(tq -f config.toml user.name)}"
    home-manager --impure -b noughty-{{STAMP}} --flake ".#${USER}@${HOSTNAME}" switch
    rm result 2> /dev/null || true
