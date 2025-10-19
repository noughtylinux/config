[private]
_header:
    @echo -e "{{BOLD}}{{WHITE}}N{{CYAN}}ø{{WHITE}}ughty Linux{{RESET}} - {{DIM}}v{{VERSION}}{{RESET}}"

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
        "24.04"|"25.04"|"25.10"|"26.04")
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

# Check if system is Ubuntu Server (not Desktop)
[private]
_is_ubuntu_server:
    #!/usr/bin/env bash
    set -euo pipefail

    # If Noughty Linux is already activated, skip desktop checks
    if [[ -e /var/lib/noughty/activated ]]; then
        marker_valid=true
        marker_file="/var/lib/noughty/activated"

        if [[ ! -s "$marker_file" ]]; then
            marker_valid=false
            echo -e "{{WARNING}}Activation marker exists but is empty"
        else
            # Validate the marker file structure and contents
            activated_by=$(grep "^activated_by=" "$marker_file" 2>/dev/null | cut -d= -f2)
            hostname_marker=$(grep "^hostname=" "$marker_file" 2>/dev/null | cut -d= -f2)
            activated_at=$(grep "^activated_at=" "$marker_file" 2>/dev/null | cut -d= -f2)

            if [[ -z "$activated_by" || -z "$hostname_marker" || -z "$activated_at" ]]; then
                marker_valid=false
                echo -e "{{WARNING}}Activation marker has invalid format (missing fields)"
            elif [[ "$activated_by" != "$USER" ]]; then
                marker_valid=false
                echo -e "{{WARNING}}Activation marker username mismatch (marker: $activated_by, current: $USER)"
            elif [[ "$hostname_marker" != "$HOSTNAME" ]]; then
                marker_valid=false
                echo -e "{{WARNING}}Activation marker hostname mismatch (marker: $hostname_marker, current: $HOSTNAME)"
            fi
        fi

        # If marker is invalid, prompt for confirmation
        if [[ "$marker_valid" == "false" ]]; then
            echo -e "{{ERROR}}Activation marker is invalid!"
            echo ""
            echo "It is highly recommended you activate Nøughty Linux on Ubuntu Server"
            echo "You may proceed at your own risk, but if you break your system, consider the left over pieces a free gift."
            echo ""
            read -p "Throw caution to the wind and skip the system checks? [y/N] " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                echo -e "{{GLYPH_FLAG_MAGENTA}}Hold on tight, unleash the chaos!"
                sudo rm -f "$marker_file"
                exit 0
            else
                echo -e "{{GLYPH_FLAG_BLUE}}Proceeding with system checks..."
            fi
        else
            echo -e "{{SUCCESS}}Nøughty Linux already activated - skipping Ubuntu desktop checks"
            exit 0
        fi
    fi

    echo -e "{{GLYPH_EYE}}Checking for existing desktop installation..."

    # Check for desktop metapackages
    DESKTOP_METAPACKAGES=(
        "edubuntu-desktop"
        "edubuntu-desktop-minimal"
        "kubuntu-desktop"
        "lubuntu-desktop"
        "lubuntu-desktop-minimal"
        "ubuntu-desktop"
        "ubuntu-desktop-minimal"
        "ubuntucinnamon-desktop"
        "ubuntucinnamon-desktop-minimal"
        "ubuntu-budgie-desktop"
        "ubuntu-budgie-desktop-minimal"
        "ubuntu-mate-core"
        "ubuntu-mate-desktop"
        "ubuntu-unity-desktop"
        "xubuntu-core"
        "xubuntu-desktop"
        "xubuntu-desktop-minimal"
    )

    for pkg in "${DESKTOP_METAPACKAGES[@]}"; do
        if dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "^install ok installed"; then
            echo -e "{{ERROR}}Desktop metapackage detected: {{DIM}}${pkg}{{RESET}}"
            echo -e "{{DIM}}Nøughty Linux should not be installed on an Ubuntu Desktop.{{RESET}}"
            exit 1
        fi
    done

    # Check for display managers (Nøughty uses greetd)
    DISPLAY_MANAGERS=("gdm3" "sddm" "lightdm" "slim")
    for dm in "${DISPLAY_MANAGERS[@]}"; do
        if dpkg-query -W -f='${Status}' "$dm" 2>/dev/null | grep -q "^install ok installed"; then
            echo -e "{{ERROR}}Display manager detected: {{DIM}}${dm}{{RESET}}"
            echo -e "{{DIM}}This indicates an existing desktop installation.{{RESET}}"
            exit 1
        fi
    done

    # Check for desktop environment core packages
    DESKTOP_ENVIRONMENTS=(
        "cinnamon-session"
        "gnome-shell"
        "lxqt-session"
        "mate-session"
        "plasma-desktop"
        "unity-session"
        "xfce4-session"
    )
    for de in "${DESKTOP_ENVIRONMENTS[@]}"; do
        if dpkg-query -W -f='${Status}' "$de" 2>/dev/null | grep -q "^install ok installed"; then
            echo -e "{{ERROR}}Desktop environment detected: {{DIM}}${de}{{RESET}}"
            echo -e "{{DIM}}This indicates an existing desktop installation.{{RESET}}"
            exit 1
        fi
    done

    # Check for X11 session files (Nøughty never creates X11 sessions)
    if [ -d /usr/share/xsessions ] && [ -n "$(ls -A /usr/share/xsessions/*.desktop 2>/dev/null)" ]; then
        echo -e "{{ERROR}}X11 session files detected in {{DIM}}/usr/share/xsessions/{{RESET}}"
        echo -e "{{DIM}}This indicates an existing desktop installation.{{RESET}}"
        exit 1
    fi

    # Check for Wayland sessions (Nøughty sessions are always prefixed "noughty-")
    if [ -d /usr/share/wayland-sessions ]; then
        NON_NOUGHTY_SESSIONS=$(ls /usr/share/wayland-sessions/*.desktop 2>/dev/null | grep -v "/noughty-" | wc -l || true)
        if [ "$NON_NOUGHTY_SESSIONS" -gt 0 ]; then
            echo -e "{{ERROR}}Wayland session files detected:"
            ls /usr/share/wayland-sessions/*.desktop 2>/dev/null | grep -v "/noughty-" || true
            echo -e "{{DIM}}This indicates an existing desktop installation.{{RESET}}"
            exit 1
        fi
    fi

    echo -e "{{SUCCESS}}Nøughty Linux compatibility checks passed!"

# Check if config.toml exists and is valid
[private]
_has_config:
    #!/usr/bin/env bash
    set -euo pipefail

    if [[ ! -f "config.toml" ]]; then
        echo -e "{{ERROR}}{{DIM}}config.toml{{RESET}} not found! Please run: {{BOLD}}just generate{{RESET}}."
        exit 1
    fi

[private]
_has_git:
    #!/usr/bin/env bash
    set -euo pipefail

    if [[ ! -d ".git" ]]; then
        echo -e "{{ERROR}}{{DIM}}.git{{RESET}} directory not found!"
        echo -e "{{DIM}}Some commands require running from a git repository.{{RESET}}"
        exit 1
    fi
