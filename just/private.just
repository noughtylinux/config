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
