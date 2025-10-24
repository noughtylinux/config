# Build home-manager configuration
[private]
build-home: _header _is_compatible _has_config
    #!/usr/bin/env bash
    echo -e "{{GLYPH_BUILD}}Building {{BOLD}}home-manager{{RESET}} configuration..."
    # Ensure environment variables are available to Nix
    export HOSTNAME="${HOSTNAME:-$(hostname -s)}"
    export USER="${USER}"
    export HOME="${HOME}"
    export NOUGHTY_KEYBOARD_LAYOUT="$(localectl status | grep "X11 Layout" | awk '{print $3}' || echo "gb")"
    nom build {{NIX_OPTS}} ".#homeConfigurations.${USER}@${HOSTNAME}.activationPackage"
    rm result 2> /dev/null || true

# Switch to home-manager configuration
[private]
switch-home: build-home
    #!/usr/bin/env bash
    echo -e "{{GLYPH_SWITCH}}Switching to new {{BOLD}}home-manager{{RESET}} configuration..."
    # Ensure environment variables are available to Nix
    export HOSTNAME="${HOSTNAME:-$(hostname -s)}"
    export USER="${USER}"
    export HOME="${HOME}"
    export NOUGHTY_KEYBOARD_LAYOUT="$(localectl status | grep "X11 Layout" | awk '{print $3}' || echo "gb")"
    home-manager --impure -b noughty-{{STAMP}} --flake ".#${USER}@${HOSTNAME}" switch 2> /dev/null
    rm result 2> /dev/null || true
