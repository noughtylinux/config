# Build home-manager configuration
[private]
build-home: _header _is_compatible _has_config
    #!/usr/bin/env bash
    set -euo pipefail
    echo -e "{{GLYPH_BUILD}}Building {{BOLD}}home-manager{{RESET}} configuration..."
    # Ensure environment variables are available to Nix
    export HOSTNAME="${HOSTNAME:-$(hostname -s)}"
    export USER="${USER}"
    export HOME="${HOME}"
    nom build {{NIX_OPTS}} "path:.#homeConfigurations.${USER}@${HOSTNAME}.activationPackage"
    rm result 2> /dev/null || true

# Switch to home-manager configuration
[private]
switch-home: build-home
    #!/usr/bin/env bash
    set -euo pipefail
    echo -e "{{GLYPH_SWITCH}}Switching to new {{BOLD}}home-manager{{RESET}} configuration..."
    # Ensure environment variables are available to Nix
    export HOSTNAME="${HOSTNAME:-$(hostname -s)}"
    export USER="${USER}"
    export HOME="${HOME}"

    # Home Manager's dconf activation falls back to its Nix dbus-daemon when
    # DBUS_SESSION_BUS_ADDRESS is absent. On Ubuntu that daemon cannot find its
    # default /etc/dbus-1/session.conf. Prefer the user's systemd D-Bus socket,
    # which also lets Home Manager reload systemd user units correctly.
    user_runtime_dir="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
    if [[ -S "${user_runtime_dir}/bus" ]]; then
        export XDG_RUNTIME_DIR="${user_runtime_dir}"
        export DBUS_SESSION_BUS_ADDRESS="unix:path=${user_runtime_dir}/bus"
        home-manager --impure -b noughty-{{STAMP}} --flake "path:.#${USER}@${HOSTNAME}" switch 2> /dev/null
    elif [[ -x /usr/bin/dbus-run-session ]]; then
        # This fallback uses Ubuntu's correctly configured D-Bus daemon. It is
        # suitable for dconf activation when no login/user-manager bus exists.
        /usr/bin/dbus-run-session -- \
            home-manager --impure -b noughty-{{STAMP}} --flake "path:.#${USER}@${HOSTNAME}" switch 2> /dev/null
    else
        echo "Home Manager activation requires a user D-Bus or /usr/bin/dbus-run-session." >&2
        exit 1
    fi
    rm result 2> /dev/null || true
